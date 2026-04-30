#!/usr/bin/env python3
"""Experimento 4: transacciones distribuidas manuales en PostgreSQL.

Ejecuta una operacion exitosa sobre shards logicos distintos y documenta el
estado de locks, transacciones preparadas y una aproximacion de rollback
controlado para evidenciar las limitaciones del 2PC manual en este proyecto.
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT / "data") not in sys.path:
    sys.path.insert(0, str(ROOT / "data"))

from db_helpers import PostgreSQLConnection, build_postgres_env_config  # noqa: E402

SQL_PATH = ROOT / "scripts" / "postgres" / "02-distributed-transactions.sql"


def results_dir() -> Path:
    return ROOT / os.getenv("RESULTS_DIR", "docs/results")


def result_path() -> Path:
    current_results_dir = results_dir()
    current_results_dir.mkdir(parents=True, exist_ok=True)
    return current_results_dir / "exp4_distributed_transactions.json"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def ensure_support_objects(db: PostgreSQLConnection) -> None:
    sql_text = SQL_PATH.read_text(encoding="utf-8")
    with db.get_cursor() as cursor:
        cursor.execute(sql_text)


def find_cross_shard_users(db: PostgreSQLConnection) -> tuple[dict, dict]:
    rows = db.execute_query(
        """
        SELECT user_id, username, MOD(user_id, 3) AS shard_id
        FROM users
        ORDER BY user_id
        LIMIT 50;
        """
    )
    for follower in rows:
        for following in rows:
            if follower["user_id"] != following["user_id"] and follower["shard_id"] != following["shard_id"]:
                return follower, following
    raise RuntimeError("No se encontraron usuarios en shards distintos para el experimento")


def collect_views(db: PostgreSQLConnection) -> dict:
    return {
        "distributed_transactions": db.execute_query(
            "SELECT * FROM distributed_transactions ORDER BY created_at DESC LIMIT 10;"
        ),
        "transaction_locks": db.execute_query("SELECT * FROM v_transaction_locks LIMIT 20;"),
        "prepared_transactions": db.execute_query("SELECT * FROM v_prepared_transactions LIMIT 20;"),
    }


def rollback_controlled_scenario(db: PostgreSQLConnection, follower_id: int, following_id: int) -> dict:
    result = {
        "approach": "rollback_controlled",
        "reason": "El procedure disponible no deja una PREPARE TRANSACTION abierta de forma segura para el cluster remoto.",
    }
    before_count = db.execute_query(
        """
        SELECT COUNT(*) AS relationship_count
        FROM followers
        WHERE follower_id = %s AND following_id = %s;
        """,
        (follower_id, following_id),
    )[0]["relationship_count"]

    conn = db.connect()
    conn.autocommit = False
    try:
        with conn.cursor() as cursor:
            cursor.execute(
                """
                INSERT INTO followers (follower_id, following_id)
                VALUES (%s, %s)
                ON CONFLICT DO NOTHING;
                """,
                (follower_id, following_id),
            )
            cursor.execute("SELECT COUNT(*) FROM pg_locks WHERE pid = pg_backend_pid();")
            lock_count = cursor.fetchone()[0]
            conn.rollback()
    finally:
        conn.autocommit = True

    after_count = db.execute_query(
        """
        SELECT COUNT(*) AS relationship_count
        FROM followers
        WHERE follower_id = %s AND following_id = %s;
        """,
        (follower_id, following_id),
    )[0]["relationship_count"]

    result["locks_seen_inside_transaction"] = lock_count
    result["relationship_count_before"] = before_count
    result["relationship_count_after_rollback"] = after_count
    result["rolled_back"] = before_count == after_count
    return result


def main() -> None:
    load_dotenv()
    db = PostgreSQLConnection(**build_postgres_env_config("primary", "exp4-primary"))

    print("=" * 72)
    print("EXPERIMENTO 4: TRANSACCIONES DISTRIBUIDAS EN POSTGRESQL")
    print("=" * 72)

    try:
        db.connect()
        ensure_support_objects(db)
        follower, following = find_cross_shard_users(db)

        started = time.time()
        with db.get_cursor() as cursor:
            cursor.execute(
                "CALL sp_distributed_follow_2pc(%s, %s);",
                (int(follower["user_id"]), int(following["user_id"])),
            )
        elapsed_ms = round((time.time() - started) * 1000, 4)

        success_views = collect_views(db)
        rollback_views = rollback_controlled_scenario(db, int(follower["user_id"]), int(following["user_id"]))

        payload = {
            "environment": {
                "primary_host": os.getenv("PG_PRIMARY_HOST", "localhost"),
                "primary_port": int(os.getenv("PG_PRIMARY_PORT", "5432")),
                "database": os.getenv("PG_DATABASE", "social_network"),
            },
            "success_scenario": {
                "follower": follower,
                "following": following,
                "elapsed_ms": elapsed_ms,
                "source_shard": follower["shard_id"],
                "target_shard": following["shard_id"],
                "result": "COMMITTED",
                **success_views,
            },
            "rollback_scenario": rollback_views,
            "notes": [
                "El proyecto modela 2PC sobre shards logicos/particiones, no sobre un cluster PostgreSQL multi-write nativo.",
                "Se documenta rollback controlado como aproximacion operativa cuando no conviene dejar prepared transactions abiertas en el entorno compartido.",
            ],
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
