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

from db_helpers import PerformanceTester, PostgreSQLConnection  # noqa: E402

RESULTS_DIR = ROOT / "docs" / "results"


def result_path() -> Path:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    return RESULTS_DIR / "exp1_latency_intra_shard.json"


def build_db_config() -> dict:
    return {
        "host": os.getenv("PG_HOST", os.getenv("CRDB_HOST", "localhost")),
        "port": int(os.getenv("PG_PORT", 5432)),
        "database": os.getenv("PG_DATABASE", "social_network"),
        "user": os.getenv("PG_USER", "admin"),
        "password": os.getenv("PG_PASSWORD", "admin123"),
    }


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def main() -> None:
    load_dotenv()
    iterations = int(os.getenv("EXPERIMENT_ITERATIONS", "100"))
    db = PostgreSQLConnection(**build_db_config())

    print("=" * 72)
    print("EXPERIMENTO 1: LATENCIA INTRA-SHARD EN POSTGRESQL")
    print("=" * 72)
    print(f"Iteraciones: {iterations}")

    try:
        db.connect()
        tester = PerformanceTester(db)

        sample_rows = db.execute_query(
            "SELECT user_id, tableoid::regclass AS partition_name FROM users ORDER BY user_id LIMIT 3;"
        )
        print(f"Particiones muestreadas: {sample_rows}")

        write_stats = tester.measure_insert_latency(
            "users",
            lambda count: {
                "user_id": int(time.time_ns()) + count,
                "username": f"latency_intra_{int(time.time_ns())}_{count}",
                "email": f"latency_intra_{int(time.time_ns())}_{count}@example.com",
                "full_name": "Latency Intra Shard User",
            },
            iterations=iterations,
        )

        sample_user = db.execute_query("SELECT user_id FROM users ORDER BY user_id LIMIT 1;")
        read_stats = {}
        if sample_user:
            uid = sample_user[0]["user_id"]
            read_stats = tester.measure_select_latency(
                f"SELECT * FROM users WHERE user_id = {uid};",
                iterations=iterations,
            )

        join_stats = tester.measure_join_latency(
            "SELECT u.user_id, u.username, COUNT(p.post_id) FROM users u LEFT JOIN posts p ON p.user_id = u.user_id GROUP BY u.user_id, u.username LIMIT 1;",
            iterations=max(20, iterations // 5),
        )

        payload = {
            "iterations": iterations,
            "write_mean_ms": round(float(write_stats.get("mean", 0.0)), 3),
            "write_median_ms": round(float(write_stats.get("median", 0.0)), 3),
            "write_p95_ms": round(float(write_stats.get("p95", 0.0)), 3),
            "read_mean_ms": round(float(read_stats.get("mean", 0.0)), 3),
            "read_median_ms": round(float(read_stats.get("median", 0.0)), 3),
            "read_p95_ms": round(float(read_stats.get("p95", 0.0)), 3),
            "join_mean_ms": round(float(join_stats.get("mean", 0.0)), 3),
            "join_median_ms": round(float(join_stats.get("median", 0.0)), 3),
            "join_p95_ms": round(float(join_stats.get("p95", 0.0)), 3),
            "sample_partitions": sample_rows,
        }
        save_payload(payload)
        print(json.dumps(payload, indent=2, ensure_ascii=False))
        print(f"[+] Resultados guardados en {result_path()}")
    except Exception as exc:
        print(f"[!] Error durante el experimento: {exc}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
