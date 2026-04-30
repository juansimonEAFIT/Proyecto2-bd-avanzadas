#!/usr/bin/env python3
import json
import psycopg2

PG_CFG = {
    "host": "localhost",
    "port": 5432,
    "database": "social_network",
    "user": "admin",
    "password": "admin123",
}


def run_saga(user_id: int, content: str):
    conn = psycopg2.connect(**PG_CFG)
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute("CALL sp_saga_publish_post_with_notifications(%s, %s);", (user_id, content))
    finally:
        conn.close()


def show_recent_sagas(limit: int = 10):
    conn = psycopg2.connect(**PG_CFG)
    try:
        with conn:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    SELECT saga_id, saga_status, step_name, created_at, updated_at
                    FROM saga_instances
                    ORDER BY created_at DESC
                    LIMIT %s
                    """,
                    (limit,),
                )
                return cur.fetchall()
    finally:
        conn.close()


if __name__ == "__main__":
    run_saga(1, "SAGA bonus workflow test")
    rows = show_recent_sagas()
    print("SAGA demo completed")
    print(json.dumps(rows, default=str, indent=2))
