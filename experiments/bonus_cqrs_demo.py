#!/usr/bin/env python3
import json
import time
from datetime import datetime, timezone
from pathlib import Path
import psycopg2

ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "docs" / "results"
RESULT_PATH = RESULTS_DIR / "bonus_cqrs_demo.json"

COMMAND_CFG = {
    "host": "localhost",
    "port": 5442,
    "database": "social_command",
    "user": "admin",
    "password": "admin123",
}

QUERY_CFG = {
    "host": "localhost",
    "port": 5443,
    "database": "social_query",
    "user": "admin",
    "password": "admin123",
}


def get_conn(cfg):
    return psycopg2.connect(**cfg)


def create_post_and_outbox_event(user_id: int, content: str):
    conn = get_conn(COMMAND_CFG)
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("CALL sp_cqrs_create_post(%s, %s);", (user_id, content))
    finally:
        conn.close()


def project_events_to_read_model(batch_size: int = 100):
    command_conn = get_conn(COMMAND_CFG)
    query_conn = get_conn(QUERY_CFG)
    projected = 0

    try:
        with command_conn, query_conn:
            with command_conn.cursor() as ccur, query_conn.cursor() as qcur:
                ccur.execute(
                    """
                    SELECT event_id, payload
                    FROM event_outbox
                    WHERE processed = FALSE
                    ORDER BY event_id
                    LIMIT %s
                    """,
                    (batch_size,),
                )
                rows = ccur.fetchall()

                for event_id, payload in rows:
                    qcur.execute(
                        """
                        INSERT INTO posts_read_model (post_id, user_id, content, created_at)
                        VALUES (%s, %s, %s, %s)
                        ON CONFLICT (post_id) DO UPDATE
                        SET content = EXCLUDED.content,
                            indexed_at = CURRENT_TIMESTAMP
                        """,
                        (
                            payload["post_id"],
                            payload["user_id"],
                            payload["content"],
                            payload["created_at"],
                        ),
                    )

                    ccur.execute(
                        "UPDATE event_outbox SET processed = TRUE WHERE event_id = %s",
                        (event_id,),
                    )
                    projected += 1
    finally:
        command_conn.close()
        query_conn.close()

    return projected


def query_user_feed(user_id: int):
    conn = get_conn(QUERY_CFG)
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT post_id, user_id, content, created_at
                    FROM posts_read_model
                    WHERE user_id = %s
                    ORDER BY created_at DESC
                    LIMIT 20
                    """,
                    (user_id,),
                )
                return cur.fetchall()
    finally:
        conn.close()


if __name__ == "__main__":
    user_id = 101
    create_post_and_outbox_event(user_id, "CQRS bonus post for distributed databases")
    projected = project_events_to_read_model()
    feed = query_user_feed(user_id)

    payload = {
        "executed_at_utc": datetime.now(timezone.utc).isoformat(),
        "user_id": user_id,
        "projected_events": projected,
        "feed_size": len(feed),
        "feed_preview": feed[:5],
    }
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    with RESULT_PATH.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, default=str, indent=2, ensure_ascii=False)

    print("CQRS demo completed")
    print(f"Projected events: {projected}")
    print(json.dumps(feed, default=str, indent=2))
    print(f"[+] Resultado guardado en {RESULT_PATH}")
