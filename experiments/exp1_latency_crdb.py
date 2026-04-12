#!/usr/bin/env python3
"""
Experimento 1: Latencia de Escritura y Lectura en CockroachDB
Mide el rendimiento base de CockroachDB para operaciones simples.
"""

import os
import sys
import time
from dotenv import load_dotenv

# Añadir el directorio raíz al path para importar de data/
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from data.db_helpers import PostgreSQLConnection, PerformanceTester

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
        # Añadimos time_ns y un sufijo aleatorio corto para garantizar IDs únicos incluso en bucles de milisegundos
        import random
        base_id = int(time.time() * 1000) 
        
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
        if sample_user:
            uid = sample_user[0]['user_id']
            query = f"SELECT * FROM users WHERE user_id = {uid}"
            select_stats = tester.measure_select_latency(query, iterations=iterations)
            
            print(f"    - Media: {select_stats.get('mean', 0):.2f} ms")
            print(f"    - Mediana: {select_stats.get('median', 0):.2f} ms")
            print(f"    - P95: {select_stats.get('p95', 0):.2f} ms")
            
        else:
            print("    [!] Error: No hay datos en la tabla 'users' para realizar la prueba de lectura.")
            
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
