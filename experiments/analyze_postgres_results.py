#!/usr/bin/env python3
"""Consolida resultados PostgreSQL en un resumen final y genera gráficas.

Este script lee los JSON guardados por los experimentos del integrante 3 y deja
una comparativa final en docs/results/postgres_summary.json.
"""

from __future__ import annotations

import json
import os
from pathlib import Path

import matplotlib.pyplot as plt
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parents[1]
IMAGES_DIR = ROOT / "docs" / "images"


def results_dir() -> Path:
    return ROOT / os.getenv("RESULTS_DIR", "docs/results")


def summary_path() -> Path:
    return results_dir() / "postgres_summary.json"

FILES = {
    "exp1": "exp1_latency_intra_shard.json",
    "exp3": "exp3_replication_sync.json",
    "exp4": "exp4_distributed_transactions.json",
    "exp5": "exp5_failover_recovery.json",
}


def load_json(path: Path):
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def save_summary(payload: dict) -> None:
    current_results_dir = results_dir()
    current_results_dir.mkdir(parents=True, exist_ok=True)
    with summary_path().open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def create_compare_plot(summary: dict) -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    exp1_metrics = summary.get("experiments", {}).get("exp1", {}).get("metrics", {})
    exp3_metrics = summary.get("experiments", {}).get("exp3", {}).get("metrics", {})
    labels = ["Intra-shard write", "Intra-shard read", "Sync write", "Async write"]
    values = [
        exp1_metrics.get("write_mean_ms", 0.0),
        exp1_metrics.get("read_primary_mean_ms", 0.0),
        exp3_metrics.get("sync_per_insert_ms", 0.0),
        exp3_metrics.get("async_per_insert_ms", 0.0),
    ]
    plt.figure(figsize=(10, 5))
    plt.bar(labels, values, color=["#336791", "#4c9f70", "#6aa4ff", "#69d2e7"])
    plt.ylabel("ms")
    plt.title("Resumen de latencias PostgreSQL")
    plt.xticks(rotation=20, ha="right")
    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "postgres_summary_latency.png")
    plt.close()


def create_sync_plot(summary: dict) -> None:
    exp3 = summary.get("experiments", {}).get("exp3", {})
    if not exp3.get("available"):
        return

    sync_value = exp3.get("metrics", {}).get("sync_per_insert_ms", 0.0)
    async_value = exp3.get("metrics", {}).get("async_per_insert_ms", 0.0)
    plt.figure(figsize=(7, 5))
    plt.bar(["sync_on", "sync_off"], [sync_value, async_value], color=["#3a5ba0", "#2d936c"])
    plt.ylabel("ms por insercion")
    plt.title("Replicacion sincronica vs asincronica")
    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "postgres_replication_sync_vs_async.png")
    plt.close()


def create_intra_shard_nodes_plot(summary: dict) -> None:
    exp1 = summary.get("experiments", {}).get("exp1", {})
    if not exp1.get("available"):
        return

    metrics = exp1.get("metrics", {})
    labels = ["Primary Write", "Primary Read", "Replica 1 Read", "Replica 2 Read"]
    values = [
        metrics.get("write_mean_ms", 0.0),
        metrics.get("read_primary_mean_ms", 0.0),
        metrics.get("read_replica1_mean_ms", 0.0),
        metrics.get("read_replica2_mean_ms", 0.0),
    ]
    plt.figure(figsize=(8, 5))
    plt.bar(labels, values, color=["#336791", "#4c9f70", "#e09f3e", "#9c6644"])
    plt.ylabel("ms")
    plt.title("PostgreSQL: primary vs replicas")
    plt.xticks(rotation=15, ha="right")
    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "postgres_intra_shard_nodes.png")
    plt.close()


def extract_experiment_summary(name: str, payload: dict | None) -> dict:
    if not payload:
        return {
            "available": False,
            "status": "pending",
            "metrics": {},
            "interpretation": f"{name} aun no tiene resultados persistidos.",
        }

    if name == "exp1":
        return {
            "available": True,
            "status": "ok",
            "metrics": {
                "write_mean_ms": payload.get("write_primary", {}).get("mean", 0.0),
                "read_primary_mean_ms": payload.get("read_primary", {}).get("mean", 0.0),
                "read_replica1_mean_ms": payload.get("read_replica1", {}).get("mean", 0.0),
                "read_replica2_mean_ms": payload.get("read_replica2", {}).get("mean", 0.0),
            },
            "interpretation": "La linea base compara escritura en el primary y lecturas por PK entre primary y replicas.",
        }

    if name == "exp3":
        return {
            "available": True,
            "status": "ok",
            "metrics": payload.get("summary", {}),
            "interpretation": "Este experimento cuantifica el costo de habilitar confirmacion sincronica de replicas.",
        }

    if name == "exp4":
        return {
            "available": True,
            "status": payload.get("result", payload.get("success_scenario", {}).get("result", "ok")).lower(),
            "metrics": {
                "elapsed_ms": payload.get("success_scenario", {}).get("elapsed_ms", 0.0),
                "source_shard": payload.get("success_scenario", {}).get("source_shard"),
                "target_shard": payload.get("success_scenario", {}).get("target_shard"),
            },
            "interpretation": "Se documenta coordinacion manual entre shards logicos y una aproximacion de rollback controlado.",
        }

    if name == "exp5":
        return {
            "available": True,
            "status": "dry-run" if payload.get("mode") == "dry-run" else "ok",
            "metrics": {
                "replica_count": len(payload.get("pre_failover_state", {}).get("replication_status", [])),
            },
            "interpretation": "El failover queda documentado como procedimiento manual con evidencia del estado previo.",
        }

    return {"available": True, "status": "ok", "metrics": {}, "interpretation": ""}


def main() -> None:
    load_dotenv()
    raw_results = {key: load_json(results_dir() / filename) for key, filename in FILES.items()}
    summary = {
        "experiments": {
            key: extract_experiment_summary(key, payload)
            for key, payload in raw_results.items()
        },
        "raw_files_present": {
            key: payload is not None
            for key, payload in raw_results.items()
        },
        "source_files": {
            key: str(results_dir() / filename)
            for key, filename in FILES.items()
        },
    }
    save_summary(summary)
    create_compare_plot(summary)
    create_sync_plot(summary)
    create_intra_shard_nodes_plot(summary)
    print(json.dumps(summary, indent=2, default=str, ensure_ascii=False))
    print(f"[+] Resumen guardado en {summary_path()}")


if __name__ == "__main__":
    main()
