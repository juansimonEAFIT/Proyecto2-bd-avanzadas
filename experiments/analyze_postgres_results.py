#!/usr/bin/env python3
"""Consolida resultados PostgreSQL en un resumen final y genera gráficas.

Este script lee los JSON guardados por los experimentos del integrante 3 y deja
una comparativa final en docs/results/postgres_summary.json.
"""

from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "docs" / "results"
IMAGES_DIR = ROOT / "docs" / "images"
SUMMARY_PATH = RESULTS_DIR / "postgres_summary.json"

FILES = {
    "exp1": RESULTS_DIR / "exp1_latency_intra_shard.json",
    "exp3": RESULTS_DIR / "exp3_replication_sync.json",
    "exp4": RESULTS_DIR / "exp4_distributed_transactions.json",
    "exp5": RESULTS_DIR / "exp5_failover_recovery.json",
}


def load_json(path: Path):
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def save_summary(payload: dict) -> None:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    with SUMMARY_PATH.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, default=str, ensure_ascii=False)


def create_compare_plot(summary: dict) -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)
    labels = ["Intra-shard write", "Intra-shard read", "Sync write", "Async write"]
    values = [
        summary.get("exp1", {}).get("write_mean_ms", 0.0),
        summary.get("exp1", {}).get("read_mean_ms", 0.0),
        summary.get("exp3", {}).get("summary", {}).get("sync_per_insert_ms", 0.0),
        summary.get("exp3", {}).get("summary", {}).get("async_per_insert_ms", 0.0),
    ]
    plt.figure(figsize=(10, 5))
    plt.bar(labels, values, color=["#336791", "#4c9f70", "#6aa4ff", "#69d2e7"])
    plt.ylabel("ms")
    plt.title("Resumen de latencias PostgreSQL")
    plt.xticks(rotation=20, ha="right")
    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "postgres_summary_latency.png")
    plt.close()


def main() -> None:
    summary = {key: load_json(path) for key, path in FILES.items()}
    save_summary(summary)
    create_compare_plot(summary)
    print(json.dumps(summary, indent=2, default=str, ensure_ascii=False))
    print(f"[+] Resumen guardado en {SUMMARY_PATH}")


if __name__ == "__main__":
    main()
