#!/usr/bin/env python3
"""Experimento 5: failover y recuperacion manual en PostgreSQL.

Registra una verificacion simple del estado de replicacion y documenta el
procedimiento esperado de promocion/manual recovery.
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

from db_helpers import PostgreSQLConnection, PerformanceTester  # noqa: E402

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
    return RESULTS_DIR / "exp5_failover_recovery.json"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def main() -> None:
    load_dotenv()
    db = PostgreSQLConnection(**PRIMARY_CFG)

    print("=" * 72)
    print("EXPERIMENTO 5: FAILOVER Y RECUPERACION EN POSTGRESQL")
    print("=" * 72)

    try:
        db.connect()
        tester = PerformanceTester(db)
        replication = tester.get_replication_status()
        users = db.execute_query("SELECT user_id, username FROM users ORDER BY user_id LIMIT 1;")

        payload = {
            "replication_status": replication,
            "sample_users": users,
            "recovery_steps": [
                "detener el primary",
                "promover una replica",
                "reconfigurar el host de escritura",
                "validar pg_stat_replication y realizar lectura/escritura",
            ],
        }
        save_payload(payload)
        print(json.dumps(payload, indent=2, default=str, ensure_ascii=False))
        print(f"[+] Resultados guardados en {result_path()}")
    except Exception as exc:
        payload = {"error": str(exc)}
        save_payload(payload)
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
