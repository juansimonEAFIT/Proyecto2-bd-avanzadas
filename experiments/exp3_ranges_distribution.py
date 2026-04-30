#!/usr/bin/env python3
"""
Experimento 3: Distribución Automática de Rangos (Range Spans)
Observa cómo CockroachDB gestiona el sharding de forma transparente.
"""

import os
import sys
from dotenv import load_dotenv

# Añadir el directorio raíz al path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from data.db_helpers import PostgreSQLConnection

def main():
    load_dotenv()
    
    db_config = {
        'host': os.getenv('CRDB_HOST', 'localhost'),
        'port': int(os.getenv('CRDB_PORT', 26257)),
        'database': os.getenv('CRDB_DATABASE', 'social_network'),
        'user': os.getenv('CRDB_USER', 'root'),
        'password': os.getenv('CRDB_PASSWORD', 'admin123')
    }
    
    db = PostgreSQLConnection(**db_config)
    
    print("=" * 60)
    print("EXPERIMENTO 3: AUTO-SHARDING Y RANGOS (COCKROACHDB)")
    print("=" * 60)
    
    try:
        db.connect()
        db.execute_update("SET allow_unsafe_internals = true")
        
        # 1. Consultar rangos por tabla (compatible con versiones recientes)
        print("\n[1] Distribución de rangos por tabla (SHOW RANGES):")
        table_names = ["users", "posts", "comments", "followers"]
        results = []
        for name in table_names:
            range_rows = db.execute_query(f"SHOW RANGES FROM TABLE {name};")
            results.append(
                {
                    "table_name": name,
                    "range_count": len(range_rows),
                    "size_mb": 0.0,
                }
            )
        results.sort(key=lambda r: r["range_count"], reverse=True)
        
        if results:
            print(f"{'Tabla':<15} | {'Rangos':<8} | {'Tamaño (MB)':<10}")
            print("-" * 40)
            for row in results:
                print(f"{row['table_name']:<15} | {row['range_count']:<8} | {row['size_mb']:<10}")
        else:
            print("    [!] No se pudieron obtener estadísticas de rangos (¿permisos?).")
            
        # 2. Explicación técnica
        print("\n[2] Análisis de Distribución:")
        print("    - A diferencia de PostgreSQL (sharding manual), CockroachDB")
        print("      divide los datos en rangos de ~64MB automáticamente.")
        print("    - Cada rango es una unidad de replicación (via Raft).")
        print("    - Si una tabla crece, CockroachDB divide el rango y lo")
        print("      mueve a un nodo con menos carga (Rebalancing).")
        
        # 3. Ver replicas de rangos (si es posible)
        print("\n[3] Replicación y Consenso:")
        print("    - Por defecto, cada rango tiene 3 réplicas.")
        print("    - Solo una réplica es el 'Leaseholder' (Líder) para lecturas/escrituras.")
        
    except Exception as e:
        print(f"[!] Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
