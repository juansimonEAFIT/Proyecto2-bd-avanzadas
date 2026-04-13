#!/usr/bin/env python3
"""Experimento 4: transacciones distribuidas manuales en PostgreSQL.

Ejecuta una transferencia lógica entre shards, documenta locks y simula una
caida de coordinacion via rollback controlado.
"""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT / "data") not in sys.path:
    sys.path.insert(0, str(ROOT / "data"))

from db_helpers import PostgreSQLConnection  # noqa: E402

RESULTS_DIR = ROOT / "docs" / "results"

PRIMARY_CFG = {
    "host": os.getenv("PG_HOST", os.getenv("CRDB_HOST", "localhost")),
    "port": int(os.getenv("PG_PORT", 5432)),
    "database": os.getenv("PG_DATABASE", "social_network"),
    "user": os.getenv("PG_USER", "admin"),
    "password": os.getenv("PG_PASSWORD", "admin123"),
}


def result_path() -> Path:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    return RESULTS_DIR / "exp4_distributed_transactions.json"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def fetch_users(db: PostgreSQLConnection) -> list[dict]:
    return db.execute_query("SELECT user_id, username FROM users ORDER BY user_id LIMIT 10;")


def main() -> None:
    load_dotenv()
    db = PostgreSQLConnection(**PRIMARY_CFG)

    print("=" * 72)
    print("EXPERIMENTO 4: TRANSACCIONES DISTRIBUIDAS EN POSTGRESQL")
    print("=" * 72)

    try:
        db.connect()
        users = fetch_users(db)
        if len(users) < 2:
            raise RuntimeError("No hay suficientes usuarios para el experimento")

        follower_id = int(users[0]["user_id"])
        following_id = int(users[1]["user_id"])

        # Ejecuta el procedimiento de 2PC definido por el integrante 1.
        with db.get_cursor() as cursor:
            cursor.execute(
                "CALL sp_distributed_follow_2pc(%s, %s);",
                (follower_id, following_id),
            )

        final_state = db.execute_query(
            "SELECT * FROM distributed_transactions ORDER BY created_at DESC LIMIT 5;"
        )
        lock_view = db.execute_query("SELECT * FROM v_transaction_locks LIMIT 10;")
        prepared_view = db.execute_query("SELECT * FROM v_prepared_transactions LIMIT 10;")

        payload = {
            "follower_id": follower_id,
            "following_id": following_id,
            "result": "COMMITTED",
            "distributed_transactions": final_state,
            "transaction_locks": lock_view,
            "prepared_transactions": prepared_view,
        }
        save_payload(payload)
        print(json.dumps(payload, indent=2, default=str, ensure_ascii=False))
        print(f"[+] Resultados guardados en {result_path()}")
    except Exception as exc:
        payload = {
            "result": "FAILED",
            "error": str(exc),
        }
        save_payload(payload)
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
