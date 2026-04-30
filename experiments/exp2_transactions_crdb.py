#!/usr/bin/env python3
"""
Experimento 2: Transacciones ACID Distribuidas en CockroachDB
Demuestra la atomicidad y consistencia en un entorno distribuido nativo.
"""

import os
import sys
import time
from dotenv import load_dotenv

# Añadir el directorio raíz al path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from data.db_helpers import PostgreSQLConnection

def test_distributed_transaction(db: PostgreSQLConnection, follower_id: int, following_id: int, simulate_error: bool = False):
    """Ejecuta una transacción multi-tabla y opcionalmente simula un error"""
    print(f"\n[+] Iniciando transacción: User {follower_id} sigue a User {following_id}")
    
    try:
        with db.get_cursor() as cursor:
            # 1. Insertar en tabla followers
            cursor.execute(
                "INSERT INTO followers (follower_id, following_id, created_at) VALUES (%s, %s, now())",
                (follower_id, following_id)
            )
            print("    - Registro en 'followers' creado.")
            
            # 2. Actualizar contador de seguidores
            cursor.execute(
                "UPDATE users SET follower_count = follower_count + 1 WHERE user_id = %s",
                (following_id,)
            )
            print("    - Contador 'follower_count' actualizado.")
            
            # 3. Actualizar contador de seguidos
            cursor.execute(
                "UPDATE users SET following_count = following_count + 1 WHERE user_id = %s",
                (follower_id,)
            )
            print("    - Contador 'following_count' actualizado.")
            
            if simulate_error:
                print("    [!] Simulando error inesperado antes del COMMIT...")
                raise Exception("Error provocado para probar ROLLBACK")
                
        print("[OK] Transacción completada con éxito (COMMIT automático).")
        return True
    except Exception as e:
        print(f"[ERROR] Transacción fallida: {e}")
        print("[OK] Rollback realizado automáticamente por el context manager.")
        return False

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
    print("EXPERIMENTO 2: TRANSACCIONES DISTRIBUIDAS (ACID) - COCKROACHDB")
    print("=" * 60)
    
    try:
        db.connect()
        
        # Obtener dos IDs de usuarios reales
        users = db.execute_query("SELECT user_id FROM users LIMIT 10")
        if len(users) < 2:
            print("[!] Error: No hay suficientes usuarios para la prueba.")
            return
            
        u1, u2 = users[0]['user_id'], users[1]['user_id']
        
        # CASO 1: Transacción Exitosa
        print("\n--- CASO 1: Éxito ---")
        test_distributed_transaction(db, u1, u2)
        
        # Verificar cambios
        res = db.execute_query(f"SELECT user_id, follower_count, following_count FROM users WHERE user_id IN ({u1}, {u2})")
        print(f"Estado final: {res}")
        
        # CASO 2: Transacción con Error (Rollback)
        print("\n--- CASO 2: Error y Rollback ---")
        test_distributed_transaction(db, u2, u1, simulate_error=True)
        
        # Verificar que no hubo cambios
        res_after = db.execute_query(f"SELECT user_id, follower_count, following_count FROM users WHERE user_id IN ({u1}, {u2})")
        print(f"Estado final (debe ser igual al anterior): {res_after}")
        
    except Exception as e:
        print(f"[!] Error: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    main()
