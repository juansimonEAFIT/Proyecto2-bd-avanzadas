#!/usr/bin/env python3
"""Experimento 1: Latencia intra-shard en PostgreSQL.

Mide lecturas y escrituras dirigidas a una sola particion de la tabla users.
Guarda un resumen JSON en docs/results/exp1_latency_intra_shard.json.
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

from db_helpers import PerformanceTester, PostgreSQLConnection, build_postgres_env_config  # noqa: E402


def results_dir() -> Path:
    return ROOT / os.getenv("RESULTS_DIR", "docs/results")


def result_path() -> Path:
    current_results_dir = results_dir()
    current_results_dir.mkdir(parents=True, exist_ok=True)
    return current_results_dir / "exp1_latency_intra_shard.json"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def summarize_stats(stats: dict) -> dict:
    keys = [
        "count",
        "requested_iterations",
        "error_count",
        "min",
        "max",
        "mean",
        "median",
        "p95",
        "p99",
        "std_dev",
    ]
    return {key: round(float(stats[key]), 4) if isinstance(stats.get(key), (int, float)) else stats.get(key) for key in keys if key in stats}


def connect_optional(db: PostgreSQLConnection, label: str) -> dict:
    try:
        db.connect()
        return {"available": True, "label": label}
    except Exception as exc:
        return {"available": False, "label": label, "error": str(exc)}


def main() -> None:
    load_dotenv()
    iterations = int(os.getenv("EXPERIMENT_ITERATIONS", "100"))
    primary = PostgreSQLConnection(**build_postgres_env_config("primary", "exp1-primary"))
    replica1 = PostgreSQLConnection(**build_postgres_env_config("replica1", "exp1-replica1"))
    replica2 = PostgreSQLConnection(**build_postgres_env_config("replica2", "exp1-replica2"))

    print("=" * 72)
    print("EXPERIMENTO 1: LATENCIA INTRA-SHARD EN POSTGRESQL")
    print("=" * 72)
    print(f"Iteraciones: {iterations}")

    try:
        primary_state = connect_optional(primary, "primary")
        replica1_state = connect_optional(replica1, "replica1")
        replica2_state = connect_optional(replica2, "replica2")

        if not primary_state["available"]:
            raise RuntimeError(f"No fue posible conectar al primary: {primary_state['error']}")

        primary_tester = PerformanceTester(primary)
        replica1_tester = PerformanceTester(replica1) if replica1_state["available"] else None
        replica2_tester = PerformanceTester(replica2) if replica2_state["available"] else None

        sample_rows = primary.execute_query(
            "SELECT user_id, tableoid::regclass AS partition_name FROM users ORDER BY user_id LIMIT 3;"
        )
        print(f"Particiones muestreadas: {sample_rows}")

        write_stats = primary_tester.measure_insert_latency(
            "users",
            lambda count: {
                "user_id": int(time.time_ns()) + count,
                "username": f"latency_intra_{int(time.time_ns())}_{count}",
                "email": f"latency_intra_{int(time.time_ns())}_{count}@example.com",
                "full_name": "Latency Intra Shard User",
            },
            iterations=iterations,
        )

        sample_user = primary.execute_query(
            """
            SELECT user_id, tableoid::regclass AS partition_name
            FROM users
            ORDER BY user_id
            LIMIT 1;
            """
        )
        read_primary_stats = {}
        read_replica1_stats = {}
        read_replica2_stats = {}
        if sample_user:
            uid = sample_user[0]["user_id"]
            read_query = f"SELECT * FROM users WHERE user_id = {uid};"
            read_primary_stats = primary_tester.measure_select_latency(
                read_query,
                iterations=iterations,
            )
            if replica1_tester:
                read_replica1_stats = replica1_tester.measure_select_latency(
                    read_query,
                    iterations=iterations,
                )
            if replica2_tester:
                read_replica2_stats = replica2_tester.measure_select_latency(
                    read_query,
                    iterations=iterations,
                )

        join_stats = primary_tester.measure_join_latency(
            """
            SELECT
                u.user_id,
                u.username,
                COUNT(p.post_id) AS post_count
            FROM users u
            LEFT JOIN posts p ON p.user_id = u.user_id
            WHERE u.user_id = (SELECT user_id FROM users ORDER BY user_id LIMIT 1)
            GROUP BY u.user_id, u.username;
            """,
            iterations=max(20, iterations // 5),
        )

        payload = {
            "environment": {
                "primary_host": os.getenv("PG_PRIMARY_HOST", "localhost"),
                "primary_port": int(os.getenv("PG_PRIMARY_PORT", "5432")),
                "replica1_host": os.getenv("PG_REPLICA1_HOST", "localhost"),
                "replica1_port": int(os.getenv("PG_REPLICA1_PORT", "5433")),
                "replica2_host": os.getenv("PG_REPLICA2_HOST", "localhost"),
                "replica2_port": int(os.getenv("PG_REPLICA2_PORT", "5434")),
                "database": os.getenv("PG_DATABASE", "social_network"),
            },
            "connectivity": {
                "primary": primary_state,
                "replica1": replica1_state,
                "replica2": replica2_state,
            },
            "iterations": iterations,
            "sample_partitions": sample_rows,
            "sample_user": sample_user,
            "write_primary": summarize_stats(write_stats),
            "read_primary": summarize_stats(read_primary_stats),
            "read_replica1": summarize_stats(read_replica1_stats),
            "read_replica2": summarize_stats(read_replica2_stats),
            "secondary_join_metric": summarize_stats(join_stats),
            "notes": [
                "La metrica principal de este experimento es la latencia de escritura en el primary y la lectura por PK en primary y replicas.",
                "El join se conserva como metrica secundaria para contexto, no como indicador principal de intra-shard.",
            ],
        }
        save_payload(payload)
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print(f"[+] Resultados guardados en {result_path()}")
    except Exception as exc:
        print(f"[!] Error durante el experimento: {exc}")
        raise
    finally:
        primary.close()
        replica1.close()
        replica2.close()


if __name__ == "__main__":
    main()
