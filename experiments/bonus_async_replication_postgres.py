#!/usr/bin/env python3
"""
Benchmark reproducible para comparar replicacion sincronica vs asincronica
en el cluster PostgreSQL del proyecto.
"""

import json
import sys
import time
import uuid
from pathlib import Path

import psycopg2

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT / "data") not in sys.path:
    sys.path.insert(0, str(ROOT / "data"))

from db_helpers import PostgreSQLConnection  # noqa: E402

PRIMARY_CFG = {
    "host": "localhost",
    "port": 5432,
    "database": "social_network",
    "user": "admin",
    "password": "admin123",
}

REPLICA_CFGS = [
    {
        "name": "postgres-replica-1",
        "host": "localhost",
        "port": 5433,
        "database": "social_network",
        "user": "admin",
        "password": "admin123",
    },
    {
        "name": "postgres-replica-2",
        "host": "localhost",
        "port": 5434,
        "database": "social_network",
        "user": "admin",
        "password": "admin123",
    },
]


def connect_raw(cfg):
    return psycopg2.connect(
        host=cfg["host"],
        port=cfg["port"],
        database=cfg["database"],
        user=cfg["user"],
        password=cfg["password"],
    )


def ensure_async_sql_loaded():
    sql_path = ROOT / "scripts" / "postgres" / "05-bonus-async-replication.sql"
    with connect_raw(PRIMARY_CFG) as conn:
        with conn.cursor() as cur:
            cur.execute(sql_path.read_text(encoding="utf-8"))


def set_cluster_sync_replication(enabled: bool):
    standby_value = 'FIRST 1 ("postgres-replica-1", "postgres-replica-2")' if enabled else ""
    sql_value = standby_value.replace("'", "''")
    conn = connect_raw(PRIMARY_CFG)
    try:
        conn.autocommit = True
        with conn.cursor() as cur:
            cur.execute(f"ALTER SYSTEM SET synchronous_standby_names = '{sql_value}';")
            cur.execute("SELECT pg_reload_conf();")
    finally:
        conn.close()
    time.sleep(1)


def current_sync_standby_names():
    with connect_raw(PRIMARY_CFG) as conn:
        with conn.cursor() as cur:
            cur.execute("SHOW synchronous_standby_names;")
            return cur.fetchone()[0]


def wait_for_replicas(pattern: str, expected_count: int, timeout_seconds: int = 15):
    deadline = time.time() + timeout_seconds
    observations = []

    while time.time() < deadline:
        observations = []
        all_synced = True

        for cfg in REPLICA_CFGS:
            conn = connect_raw(cfg)
            try:
                with conn.cursor() as cur:
                    cur.execute(
                        """
                        SELECT
                            COUNT(*) AS visible_rows,
                            pg_is_in_recovery() AS is_replica,
                            NOW() - pg_last_xact_replay_timestamp() AS replay_delay
                        FROM users
                        WHERE username LIKE %s;
                        """,
                        (pattern,),
                    )
                    visible_rows, is_replica, replay_delay = cur.fetchone()
            finally:
                conn.close()

            observations.append(
                {
                    "replica": cfg["name"],
                    "visible_rows": visible_rows,
                    "is_replica": is_replica,
                    "replay_delay": None if replay_delay is None else str(replay_delay),
                }
            )
            if visible_rows < expected_count:
                all_synced = False

        if all_synced:
            return observations

        time.sleep(1)

    return observations


def run_benchmark(commit_mode: str, iterations: int, prefix: str):
    primary = PostgreSQLConnection(**PRIMARY_CFG)
    primary.connect()
    try:
        result = primary.execute_query(
            """
            SELECT *
            FROM fn_benchmark_commit_mode(%s, %s, %s);
            """,
            (commit_mode, iterations, prefix),
        )[0]
        result["elapsed_ms"] = float(result["elapsed_ms"])
        replication = primary.execute_query("SELECT * FROM v_replication_overview;")
        primary_count = primary.execute_query(
            """
            SELECT COUNT(*) AS visible_rows
            FROM users
            WHERE username LIKE %s;
            """,
            (f"{prefix}_{commit_mode}_%",),
        )[0]["visible_rows"]
    finally:
        primary.close()

    replica_counts = wait_for_replicas(f"{prefix}_{commit_mode}_%", primary_count)
    result["rows_visible_replicas"] = replica_counts
    result["replication_status"] = replication
    return result


def summarize(sync_result, async_result):
    sync_mean = sync_result["elapsed_ms"] / sync_result["inserted_rows"]
    async_mean = async_result["elapsed_ms"] / async_result["inserted_rows"]
    improvement_pct = ((sync_mean - async_mean) / sync_mean) * 100 if sync_mean else 0
    return {
        "sync_per_insert_ms": round(float(sync_mean), 4),
        "async_per_insert_ms": round(float(async_mean), 4),
        "async_improvement_pct": round(float(improvement_pct), 2),
    }


def main():
    iterations = 200
    base_prefix = f"bonus_async_{uuid.uuid4().hex[:8]}"

    ensure_async_sql_loaded()

    print("=" * 72)
    print("BONUS: REPLICACION SINCRONICA VS ASINCRONICA EN POSTGRESQL")
    print("=" * 72)
    print(f"Prefijo base del benchmark: {base_prefix}")
    print(f"Iteraciones por modo: {iterations}")

    try:
        set_cluster_sync_replication(True)
        sync_result = run_benchmark("on", iterations, base_prefix)
        sync_result["cluster_sync_setting"] = current_sync_standby_names()

        set_cluster_sync_replication(False)
        async_result = run_benchmark("off", iterations, base_prefix)
        async_result["cluster_sync_setting"] = current_sync_standby_names()
    finally:
        set_cluster_sync_replication(False)

    summary = summarize(sync_result, async_result)

    payload = {
        "benchmark_prefix": base_prefix,
        "iterations": iterations,
        "sync_on": sync_result,
        "sync_off": async_result,
        "summary": summary,
    }

    print(json.dumps(payload, indent=2, default=str))


if __name__ == "__main__":
    main()
