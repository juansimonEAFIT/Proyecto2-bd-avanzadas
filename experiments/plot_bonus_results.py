#!/usr/bin/env python3
"""Genera graficos a partir de los resultados JSON del bonus."""

from __future__ import annotations

import json
from pathlib import Path

import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "docs" / "results"
IMAGES_DIR = ROOT / "docs" / "images"


def load_json(path: Path):
    if not path.exists():
        return None
    with path.open("r", encoding="utf-8-sig") as handle:
        return json.load(handle)


def plot_async_replication(data: dict) -> None:
    summary = data.get("summary", {})
    sync_ms = summary.get("sync_per_insert_ms", 0)
    async_ms = summary.get("async_per_insert_ms", 0)

    labels = ["Sync", "Async"]
    values = [sync_ms, async_ms]
    colors = ["#3a78c2", "#2ca58d"]

    plt.figure(figsize=(7, 5))
    bars = plt.bar(labels, values, color=colors)
    plt.title("PostgreSQL: Sync vs Async por insercion")
    plt.ylabel("ms por insercion")
    for bar in bars:
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width() / 2, height, f"{height:.4f}", ha="center", va="bottom")
    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "bonus_async_replication.png")
    plt.close()


def plot_quorum_latency(data: dict) -> None:
    latency = data.get("latency_ms", {})
    labels = ["Min", "Avg", "Max"]
    values = [
        latency.get("minimum", 0),
        latency.get("average", 0),
        latency.get("maximum", 0),
    ]

    plt.figure(figsize=(7, 5))
    bars = plt.bar(labels, values, color=["#66a61e", "#e6ab02", "#d95f02"])
    plt.title("CockroachDB: Latencia con geodistribucion")
    plt.ylabel("ms")
    for bar in bars:
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width() / 2, height, f"{height:.2f}", ha="center", va="bottom")

    quorum_rejected = data.get("quorum_write_rejected", False)
    status = "SI" if quorum_rejected else "NO"
    plt.figtext(0.5, 0.01, f"Escritura rechazada por quorum insuficiente: {status}", ha="center")
    plt.tight_layout(rect=[0, 0.04, 1, 1])
    plt.savefig(IMAGES_DIR / "bonus_quorum_latency.png")
    plt.close()


def plot_cqrs_and_saga(cqrs: dict, saga: dict) -> None:
    projected = cqrs.get("projected_events", 0)
    feed_size = cqrs.get("feed_size", 0)
    saga_count = saga.get("count", 0)

    labels = ["CQRS projected", "CQRS feed size", "SAGA registros"]
    values = [projected, feed_size, saga_count]

    plt.figure(figsize=(8, 5))
    bars = plt.bar(labels, values, color=["#4e79a7", "#59a14f", "#9c755f"])
    plt.title("Resumen CQRS y SAGA")
    plt.ylabel("conteo")
    for bar in bars:
        height = bar.get_height()
        plt.text(bar.get_x() + bar.get_width() / 2, height, f"{int(height)}", ha="center", va="bottom")
    plt.tight_layout()
    plt.savefig(IMAGES_DIR / "bonus_cqrs_saga.png")
    plt.close()


def main() -> None:
    IMAGES_DIR.mkdir(parents=True, exist_ok=True)

    async_data = load_json(RESULTS_DIR / "bonus_async_replication_postgres.json")
    quorum_data = load_json(RESULTS_DIR / "bonus_quorum_geodistribution.json")
    cqrs_data = load_json(RESULTS_DIR / "bonus_cqrs_demo.json")
    saga_data = load_json(RESULTS_DIR / "bonus_saga_postgres.json")

    if async_data:
        plot_async_replication(async_data)
        print("[+] bonus_async_replication.png generado")
    else:
        print("[!] Falta bonus_async_replication_postgres.json")

    if quorum_data:
        plot_quorum_latency(quorum_data)
        print("[+] bonus_quorum_latency.png generado")
    else:
        print("[!] Falta bonus_quorum_geodistribution.json")

    if cqrs_data and saga_data:
        plot_cqrs_and_saga(cqrs_data, saga_data)
        print("[+] bonus_cqrs_saga.png generado")
    else:
        print("[!] Falta bonus_cqrs_demo.json o bonus_saga_postgres.json")


if __name__ == "__main__":
    main()
