#!/usr/bin/env python3
"""Experimento 3: comparacion synchronous_commit=ON vs OFF en PostgreSQL.

Reutiliza el benchmark preparado por el integrante 1 y guarda un JSON con el
resumen para posterior consolidacion.
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
SQL_PATH = ROOT / "scripts" / "postgres" / "05-bonus-async-replication.sql"

PRIMARY_CFG = {
    "host": os.getenv("PG_HOST", os.getenv("CRDB_HOST", "localhost")),
    "port": int(os.getenv("PG_PORT", 5432)),
    "database": os.getenv("PG_DATABASE", "social_network"),
    "user": os.getenv("PG_USER", "admin"),
    "password": os.getenv("PG_PASSWORD", "admin123"),
}


def ensure_results_dir() -> Path:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    return RESULTS_DIR


def result_path() -> Path:
    return ensure_results_dir() / "exp3_replication_sync.json"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def load_support_sql(db: PostgreSQLConnection) -> None:
    sql_text = SQL_PATH.read_text(encoding="utf-8")
    with db.get_cursor() as cursor:
        cursor.execute(sql_text)


def run_mode(db: PostgreSQLConnection, mode: str, iterations: int, prefix: str) -> dict:
    rows = db.execute_query(
        "SELECT * FROM fn_benchmark_commit_mode(%s, %s, %s);",
        (mode, iterations, prefix),
    )
    if not rows:
        raise RuntimeError(f"No se obtuvo resultado para commit_mode={mode}")
    benchmark = rows[0]
    replication = db.execute_query("SELECT * FROM v_replication_overview;")
    benchmark["replication_overview"] = replication
    return benchmark


def main() -> None:
    load_dotenv()
    iterations = int(os.getenv("EXPERIMENT_ITERATIONS", "200"))
    benchmark_prefix = os.getenv("EXPERIMENT_PREFIX", "exp3_replication_sync")
    db = PostgreSQLConnection(**PRIMARY_CFG)

    print("=" * 72)
    print("EXPERIMENTO 3: SYNC VS ASYNC EN POSTGRESQL")
    print("=" * 72)
    print(f"Iteraciones: {iterations}")
    print(f"Prefijo: {benchmark_prefix}")

    try:
        db.connect()
        load_support_sql(db)

        sync_result = run_mode(db, "on", iterations, f"{benchmark_prefix}_sync")
        async_result = run_mode(db, "off", iterations, f"{benchmark_prefix}_async")

        sync_mean = float(sync_result["elapsed_ms"]) / int(sync_result["inserted_rows"])
        async_mean = float(async_result["elapsed_ms"]) / int(async_result["inserted_rows"])
        improvement_pct = ((sync_mean - async_mean) / sync_mean) * 100 if sync_mean else 0.0

        payload = {
            "iterations": iterations,
            "sync_on": sync_result,
            "sync_off": async_result,
            "summary": {
                "sync_per_insert_ms": round(sync_mean, 4),
                "async_per_insert_ms": round(async_mean, 4),
                "async_improvement_pct": round(improvement_pct, 2),
            },
        }
        save_payload(payload)
        print(json.dumps(payload, indent=2, default=str, ensure_ascii=False))
        print(f"[+] Resultados guardados en {result_path()}")
    except Exception as exc:
        print(f"[!] Error durante el experimento: {exc}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    main()
