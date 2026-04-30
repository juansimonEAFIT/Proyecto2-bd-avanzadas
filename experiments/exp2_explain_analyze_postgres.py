#!/usr/bin/env python3
"""Experimento 2: EXPLAIN / EXPLAIN ANALYZE en PostgreSQL.

Ejecuta los planes de consulta mas importantes del frente PostgreSQL y guarda
un resumen reproducible en docs/results/postgres_explain_analyze.json.
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path
from typing import Any

import matplotlib.pyplot as plt
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT / "data") not in sys.path:
    sys.path.insert(0, str(ROOT / "data"))

from db_helpers import PostgreSQLConnection, build_postgres_env_config  # noqa: E402


def results_dir() -> Path:
    return ROOT / os.getenv("RESULTS_DIR", "docs/results")


def result_path() -> Path:
    current_results_dir = results_dir()
    current_results_dir.mkdir(parents=True, exist_ok=True)
    return current_results_dir / "postgres_explain_analyze.json"


def image_path() -> Path:
    images_dir = ROOT / "docs" / "images"
    images_dir.mkdir(parents=True, exist_ok=True)
    return images_dir / "postgres_explain_analyze.png"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def collect_node_types(plan_node: dict[str, Any], collector: list[str]) -> None:
    collector.append(plan_node.get("Node Type", "Unknown"))
    for child in plan_node.get("Plans", []) or []:
        collect_node_types(child, collector)


def summarize_plan(plan_wrapper: dict[str, Any]) -> dict[str, Any]:
    plan_root = plan_wrapper.get("Plan", {})
    node_types: list[str] = []
    collect_node_types(plan_root, node_types)
    return {
        "planning_time_ms": round(float(plan_wrapper.get("Planning Time", 0.0)), 4),
        "execution_time_ms": round(float(plan_wrapper.get("Execution Time", 0.0)), 4),
        "plan_rows": plan_root.get("Plan Rows"),
        "actual_rows": plan_root.get("Actual Rows"),
        "node_types": node_types,
        "root_node_type": plan_root.get("Node Type"),
    }


def explain_json(db: PostgreSQLConnection, query: str, params: tuple = (), rollback_after: bool = False) -> list[dict]:
    if not db.conn:
        db.connect()

    cursor = db.conn.cursor()
    try:
        cursor.execute(f"EXPLAIN (ANALYZE, VERBOSE, BUFFERS, FORMAT JSON) {query}", params)
        explain_result = cursor.fetchone()[0]
        if rollback_after:
            db.conn.rollback()
        else:
            db.conn.commit()
        return explain_result
    except Exception:
        db.conn.rollback()
        raise
    finally:
        cursor.close()


def create_chart(payload: dict) -> None:
    labels = []
    values = []
    for case_name, case_payload in payload["cases"].items():
        labels.append(case_name.replace("_", "\n"))
        values.append(case_payload["summary"]["execution_time_ms"])

    plt.figure(figsize=(9, 5))
    plt.bar(labels, values, color=["#336791", "#4c9f70", "#e09f3e", "#9c6644"])
    plt.ylabel("Execution Time (ms)")
    plt.title("PostgreSQL EXPLAIN ANALYZE")
    plt.tight_layout()
    plt.savefig(image_path())
    plt.close()


def main() -> None:
    load_dotenv()
    db = PostgreSQLConnection(**build_postgres_env_config("primary", "exp2-explain"))

    print("=" * 72)
    print("EXPERIMENTO 2: EXPLAIN / EXPLAIN ANALYZE EN POSTGRESQL")
    print("=" * 72)

    try:
        db.connect()
        sample_user = db.execute_query(
            """
            SELECT user_id, username
            FROM users
            ORDER BY user_id
            LIMIT 1;
            """
        )[0]

        explain_cases = {
            "insert_partitioned_users": {
                "query": """
                    INSERT INTO users (username, email, full_name)
                    VALUES (%s, %s, %s)
                """,
                "params": (
                    f"explain_insert_{int(time.time())}",
                    f"explain_insert_{int(time.time())}@example.com",
                    "Explain Analyze User",
                ),
                "rollback_after": True,
                "purpose": "Valida el costo de insercion sobre tabla particionada por hash.",
            },
            "intra_shard_lookup": {
                "query": """
                    SELECT u.user_id, u.username, COUNT(p.post_id) AS post_count
                    FROM users u
                    LEFT JOIN posts p ON u.user_id = p.user_id
                    WHERE u.user_id = %s
                    GROUP BY u.user_id, u.username
                """,
                "params": (sample_user["user_id"],),
                "rollback_after": False,
                "purpose": "Consulta localizada por PK sobre un usuario puntual.",
            },
            "inter_shard_join": {
                "query": """
                    SELECT
                        u.username,
                        COUNT(DISTINCT p.post_id) AS num_posts,
                        COUNT(DISTINCT pl.like_id) AS num_likes,
                        COUNT(DISTINCT f.follower_id) AS num_followers
                    FROM users u
                    LEFT JOIN posts p ON u.user_id = p.user_id
                    LEFT JOIN post_likes pl ON p.post_id = pl.post_id
                    LEFT JOIN followers f ON u.user_id = f.following_id
                    GROUP BY u.user_id, u.username
                    LIMIT 100
                """,
                "params": (),
                "rollback_after": False,
                "purpose": "Join distribuido entre varias tablas y particiones logicas.",
            },
            "distributed_aggregation_posts": {
                "query": """
                    SELECT
                        EXTRACT(DATE FROM created_at) AS creation_date,
                        COUNT(*) AS num_posts,
                        AVG(like_count) AS avg_likes
                    FROM posts
                    WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
                    GROUP BY EXTRACT(DATE FROM created_at)
                    ORDER BY creation_date DESC
                """,
                "params": (),
                "rollback_after": False,
                "purpose": "Agregacion sobre la tabla particionada por rango de fecha.",
            },
        }

        payload = {
            "environment": {
                "primary_host": os.getenv("PG_PRIMARY_HOST", "localhost"),
                "primary_port": int(os.getenv("PG_PRIMARY_PORT", "5432")),
                "database": os.getenv("PG_DATABASE", "social_network"),
            },
            "sample_user": sample_user,
            "cases": {},
        }

        for case_name, case in explain_cases.items():
            explain_result = explain_json(
                db,
                case["query"],
                params=case["params"],
                rollback_after=case["rollback_after"],
            )
            plan_wrapper = explain_result[0]
            payload["cases"][case_name] = {
                "purpose": case["purpose"],
                "summary": summarize_plan(plan_wrapper),
                "plan": plan_wrapper,
            }
            print(
                f"[+] {case_name}: execution={payload['cases'][case_name]['summary']['execution_time_ms']} ms"
            )

        save_payload(payload)
        create_chart(payload)
        print(f"[+] Resultados guardados en {result_path()}")
        print(f"[+] Grafico guardado en {image_path()}")
    finally:
        db.close()


if __name__ == "__main__":
    main()
