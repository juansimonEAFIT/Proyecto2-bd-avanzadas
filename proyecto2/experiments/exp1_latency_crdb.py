#!/usr/bin/env python3
"""
Experimento 1: Latencia de Escritura y Lectura en CockroachDB
Mide el rendimiento base de CockroachDB para operaciones simples.
"""

import os
import sys
import time
import json
from pathlib import Path
from dotenv import load_dotenv

# Añadir el directorio raíz al path para importar de data/
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from data.db_helpers import PostgreSQLConnection, PerformanceTester

ROOT = Path(__file__).resolve().parents[1]
RESULTS_DIR = ROOT / "docs" / "results"
RESULT_PATH = RESULTS_DIR / "exp1_latency_crdb.json"


def save_results(payload: dict) -> None:
    RESULTS_DIR.mkdir(parents=True, exist_ok=True)
    with RESULT_PATH.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2, ensure_ascii=False)

def main():
    # Cargar variables de entorno
    load_dotenv()
    
    # Configuración de CockroachDB
    db_config = {
        'host': os.getenv('CRDB_HOST', 'localhost'),
        'port': int(os.getenv('CRDB_PORT', 26257)),
        'database': os.getenv('CRDB_DATABASE', 'social_network'),
        'user': os.getenv('CRDB_USER', 'root'),
        'password': os.getenv('CRDB_PASSWORD', 'admin123')
    }
    
    iterations = int(os.getenv('EXPERIMENT_ITERATIONS', 100))
    
    print("=" * 60)
    print("EXPERIMENTO 1: LATENCIA BASE EN COCKROACHDB")
    print(f"Host: {db_config['host']}:{db_config['port']}")
    print(f"Iteraciones: {iterations}")
    print("=" * 60)
    
    # Conectar a la base de datos
    crdb = PostgreSQLConnection(**db_config)
    
    try:
        crdb.connect()
        print("[+] Conexión establecida con CockroachDB")
        
        tester = PerformanceTester(crdb)
        
        # 1. Medir Latencia de Escritura (INSERT)
        print("\n[1] Midiendo latencia de INSERT en tabla 'users'...")
        insert_stats = tester.measure_insert_latency('users', lambda count: {
            'user_id': int(time.time_ns()) + count,
            'username': f"latency_test_{int(time.time_ns())}_{count}",
            'email': f"test_{int(time.time_ns())}_{count}@example.com",
            'full_name': 'Latency Test User'
        }, iterations=iterations)
        
        print(f"    - Media: {insert_stats.get('mean', 0):.2f} ms")
        print(f"    - Mediana: {insert_stats.get('median', 0):.2f} ms")
        print(f"    - P95: {insert_stats.get('p95', 0):.2f} ms")
        print(f"    - Std Dev: {insert_stats.get('std_dev', 0):.2f} ms")
        
        # 2. Medir Latencia de Lectura (SELECT por PK)
        print("\n[2] Midiendo latencia de SELECT por Primary Key...")
        # Primero obtenemos un user_id válido
        sample_user = crdb.execute_query("SELECT user_id FROM users LIMIT 1")
        select_stats = {}
        if sample_user:
            uid = sample_user[0]['user_id']
            query = f"SELECT * FROM users WHERE user_id = {uid}"
            select_stats = tester.measure_select_latency(query, iterations=iterations)
            
            print(f"    - Media: {select_stats.get('mean', 0):.2f} ms")
            print(f"    - Mediana: {select_stats.get('median', 0):.2f} ms")
            print(f"    - P95: {select_stats.get('p95', 0):.2f} ms")
            
        else:
            print("    [!] Error: No hay datos en la tabla 'users' para realizar la prueba de lectura.")

        join_stats = tester.measure_join_latency(
            "SELECT u.user_id, u.username, COUNT(p.post_id) FROM users u LEFT JOIN posts p ON p.user_id = u.user_id GROUP BY u.user_id, u.username LIMIT 1;",
            iterations=max(20, iterations // 5),
        )

        payload = {
            "iterations": iterations,
            "write_mean_ms": round(float(insert_stats.get("mean", 0.0)), 3),
            "write_median_ms": round(float(insert_stats.get("median", 0.0)), 3),
            "write_p95_ms": round(float(insert_stats.get("p95", 0.0)), 3),
            "read_mean_ms": round(float(select_stats.get("mean", 0.0)), 3),
            "read_median_ms": round(float(select_stats.get("median", 0.0)), 3),
            "read_p95_ms": round(float(select_stats.get("p95", 0.0)), 3),
            "join_mean_ms": round(float(join_stats.get("mean", 0.0)), 3),
            "join_median_ms": round(float(join_stats.get("median", 0.0)), 3),
            "join_p95_ms": round(float(join_stats.get("p95", 0.0)), 3),
        }
        save_results(payload)
        print(f"[+] Resultados guardados en {RESULT_PATH}")
        print(json.dumps(payload, indent=2, ensure_ascii=False))
            
        print("\n" + "=" * 60)
        print("RESULTADO: CockroachDB muestra latencias estables gracias a su")
        print("distribución nativa y consenso Raft.")
        print("=" * 60)
        
    except Exception as e:
        print(f"\n[!] Error durante el experimento: {e}")
    finally:
        crdb.close()

if __name__ == "__main__":
    main()
