#!/usr/bin/env python3
"""Experimento 5: failover y recuperacion manual en PostgreSQL.

Registra el estado actual del primary y las replicas, y deja un procedimiento
guiado para ejecutar failover manual en AWS sin alterar el entorno por defecto.
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

from db_helpers import PostgreSQLConnection, PerformanceTester, build_postgres_env_config  # noqa: E402


def results_dir() -> Path:
    return ROOT / os.getenv("RESULTS_DIR", "docs/results")


def result_path() -> Path:
    current_results_dir = results_dir()
    current_results_dir.mkdir(parents=True, exist_ok=True)
    return current_results_dir / "exp5_failover_recovery.json"


def save_payload(payload: dict) -> None:
    with result_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def collect_node_state(role: str) -> dict:
    cfg = build_postgres_env_config(role, f"exp5-{role}")
    db = PostgreSQLConnection(**cfg)
    try:
        db.connect()
        recovery_state = db.execute_query(
            "SELECT pg_is_in_recovery() AS is_in_recovery, now() AS observed_at;"
        )[0]
        sample_read = db.execute_query(
            "SELECT user_id, username FROM users ORDER BY user_id LIMIT 1;"
        )
        return {
            "role": role,
            "host": cfg["host"],
            "port": cfg["port"],
            "is_in_recovery": recovery_state["is_in_recovery"],
            "observed_at": recovery_state["observed_at"],
            "sample_read": sample_read,
        }
    except Exception as exc:
        return {
            "role": role,
            "host": cfg["host"],
            "port": cfg["port"],
            "available": False,
            "error": str(exc),
        }
    finally:
        db.close()


def main() -> None:
    load_dotenv()
    primary_cfg = build_postgres_env_config("primary", "exp5-primary")
    db = PostgreSQLConnection(**primary_cfg)

    print("=" * 72)
    print("EXPERIMENTO 5: FAILOVER Y RECUPERACION EN POSTGRESQL")
    print("=" * 72)

    try:
        db.connect()
        tester = PerformanceTester(db)
        replication = tester.get_replication_status()

        payload = {
            "mode": os.getenv("FAILOVER_MODE", "dry-run"),
            "environment": {
                "primary_host": primary_cfg["host"],
                "primary_port": primary_cfg["port"],
                "database": primary_cfg["database"],
            },
            "pre_failover_state": {
                "primary": collect_node_state("primary"),
                "replica1": collect_node_state("replica1"),
                "replica2": collect_node_state("replica2"),
                "replication_status": replication,
            },
            "manual_commands": [
                "ssh -i .\\P2-bd-avanzadas.pem ubuntu@54.84.181.98",
                "cd ~/proyecto2",
                "sudo docker stop postgres-primary",
                "sudo docker exec -it postgres-replica-1 psql -U admin -d social_network -c \"SELECT pg_promote();\"",
                "sudo docker exec -it postgres-replica-1 psql -U admin -d social_network -c \"SELECT pg_is_in_recovery();\"",
                "sudo docker exec -it postgres-replica-1 psql -U admin -d social_network -c \"SELECT count(*) FROM users;\"",
            ],
            "recovery_steps": [
                "detener el primary y confirmar que deja de responder",
                "promover postgres-replica-1 con pg_promote()",
                "verificar que pg_is_in_recovery() devuelva false en la nueva primary",
                "actualizar temporalmente el host de escritura de la aplicacion hacia la replica promovida",
                "validar lectura y una escritura de prueba en la nueva primary",
                "reconstruir el nodo original como replica antes de volver a topologia estable",
            ],
            "notes": [
                "Este script no ejecuta failover real por defecto; deja evidencia y procedimiento reproducible en modo dry-run.",
                "El costo operativo del failover en PostgreSQL sigue siendo manual frente a motores distribuidos nativos.",
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
