#!/usr/bin/env python3
"""Experimento 3: comparacion synchronous_commit=ON vs OFF en PostgreSQL.

Reutiliza el benchmark preparado por el integrante 1 y guarda un JSON con el
resumen para posterior consolidacion.
"""

from __future__ import annotations

import json
import os
import sys
import time
import uuid
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT / "data") not in sys.path:
    sys.path.insert(0, str(ROOT / "data"))

from db_helpers import PostgreSQLConnection, build_postgres_env_config  # noqa: E402

SQL_PATH = ROOT / "scripts" / "postgres" / "05-bonus-async-replication.sql"


def results_dir() -> Path:
    return ROOT / os.getenv("RESULTS_DIR", "docs/results")


def ensure_results_dir() -> Path:
    current_results_dir = results_dir()
    current_results_dir.mkdir(parents=True, exist_ok=True)
    return current_results_dir


def result_path() -> Path:
    return ensure_results_dir() / "exp3_replication_sync.json"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def connect_raw(cfg: dict):
    return psycopg2.connect(**cfg)


def load_support_sql(db: PostgreSQLConnection) -> None:
    sql_text = SQL_PATH.read_text(encoding="utf-8")
    with db.get_cursor() as cursor:
        cursor.execute(sql_text)


def current_sync_standby_names(cfg: dict) -> str:
    with connect_raw(cfg) as conn:
        with conn.cursor() as cur:
            cur.execute("SHOW synchronous_standby_names;")
            return cur.fetchone()[0]


def set_cluster_sync_replication(cfg: dict, standby_value: str) -> None:
    conn = connect_raw(cfg)
    try:
        conn.autocommit = True
        with conn.cursor() as cur:
            sql_value = standby_value.replace("'", "''")
            cur.execute(f"ALTER SYSTEM SET synchronous_standby_names = '{sql_value}';")
            cur.execute("SELECT pg_reload_conf();")
    finally:
        conn.close()
    time.sleep(1)


def run_mode(db: PostgreSQLConnection, primary_cfg: dict, mode: str, iterations: int, prefix: str) -> dict:
    rows = db.execute_query(
        "SELECT * FROM fn_benchmark_commit_mode(%s, %s, %s);",
        (mode, iterations, prefix),
    )
    if not rows:
        raise RuntimeError(f"No se obtuvo resultado para commit_mode={mode}")

    benchmark = rows[0]
    benchmark["elapsed_ms"] = float(benchmark["elapsed_ms"])
    benchmark["replication_overview"] = db.execute_query("SELECT * FROM v_replication_overview;")
    benchmark["sync_standby_names"] = current_sync_standby_names(primary_cfg)
    benchmark["per_insert_ms"] = round(
        benchmark["elapsed_ms"] / int(benchmark["inserted_rows"]),
        4,
    )
    return benchmark


def main() -> None:
    load_dotenv()
    iterations = int(os.getenv("EXPERIMENT_ITERATIONS", "200"))
    benchmark_prefix = os.getenv("EXPERIMENT_PREFIX", f"exp3_replication_sync_{uuid.uuid4().hex[:8]}")
    primary_cfg = build_postgres_env_config("primary", "exp3-primary")
    db = PostgreSQLConnection(**primary_cfg)

    print("=" * 72)
    print("EXPERIMENTO 3: SYNC VS ASYNC EN POSTGRESQL")
    print("=" * 72)
    print(f"Iteraciones: {iterations}")
    print(f"Prefijo: {benchmark_prefix}")

    try:
        db.connect()
        load_support_sql(db)
        previous_sync_setting = current_sync_standby_names(primary_cfg)

        set_cluster_sync_replication(primary_cfg, 'FIRST 1 ("postgres-replica-1", "postgres-replica-2")')
        sync_result = run_mode(db, primary_cfg, "on", iterations, f"{benchmark_prefix}_sync")

        set_cluster_sync_replication(primary_cfg, "")
        async_result = run_mode(db, primary_cfg, "off", iterations, f"{benchmark_prefix}_async")

        sync_mean = sync_result["per_insert_ms"]
        async_mean = async_result["per_insert_ms"]
        improvement_pct = ((sync_mean - async_mean) / sync_mean) * 100 if sync_mean else 0.0

        payload = {
            "environment": {
                "primary_host": primary_cfg["host"],
                "primary_port": primary_cfg["port"],
                "database": primary_cfg["database"],
            },
            "iterations": iterations,
            "benchmark_prefix": benchmark_prefix,
            "sync_on": sync_result,
            "sync_off": async_result,
            "summary": {
                "sync_per_insert_ms": round(sync_mean, 4),
                "async_per_insert_ms": round(async_mean, 4),
                "async_improvement_pct": round(improvement_pct, 2),
            },
            "cluster_sync_settings": {
                "previous": previous_sync_setting,
                "restored_to": previous_sync_setting,
            },
        }
        save_payload(payload)
        print(json.dumps(payload, indent=2, default=str, ensure_ascii=False))
        print(f"[+] Resultados guardados en {result_path()}")
    except Exception as exc:
        print(f"[!] Error durante el experimento: {exc}")
        raise
    finally:
        try:
            previous = locals().get("previous_sync_setting", "")
            set_cluster_sync_replication(primary_cfg, previous)
        except Exception as restore_exc:
            print(f"[!] No se pudo restaurar synchronous_standby_names: {restore_exc}")
        db.close()


if __name__ == "__main__":
    main()
