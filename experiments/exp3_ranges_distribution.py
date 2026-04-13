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
        
        # 1. Consultar rangos por tabla
        print("\n[1] Distribución de rangos por tabla (crdb_internal.table_spans):")
        query_ranges = """
            SELECT 
                table_name,
                range_count,
                ROUND(size_bytes / 1024.0 / 1024.0, 2) AS size_mb
            FROM crdb_internal.table_spans
            WHERE table_name IN ('users', 'posts', 'comments', 'followers')
            ORDER BY range_count DESC;
        """
        
        results = db.execute_query(query_ranges)
        
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
