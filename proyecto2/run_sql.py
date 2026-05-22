import sys
import psycopg2
import time

def run_sql_file(filepath):
    print(f"\n[*] Ejecutando: {filepath}")
    
    with open(filepath, 'r', encoding='utf-8') as f:
        sql_content = f.read()
    
    # 1. Crear base de datos target si no existe
    conn = None
    for attempt in range(5):
        try:
            conn = psycopg2.connect(
                host="127.0.0.1",
                port=26257,
                user="root",
                dbname="defaultdb",
                sslmode="disable"
            )
            conn.autocommit = True
            break
        except Exception as e:
            time.sleep(2)
            
    if conn is None:
        print("[!] ERROR: No se conectó a la DB en 127.0.0.1:26257")
        sys.exit(1)
        
    cursor = conn.cursor()
    try:
        cursor.execute("CREATE DATABASE social_network;")
    except:
        pass
    conn.close()
    
    # 2. Conectar a social_network para inyectar datos
    conn = psycopg2.connect(
        host="127.0.0.1",
        port=26257,
        user="root",
        dbname="social_network",
        sslmode="disable"
    )
    conn.autocommit = True
    cursor = conn.cursor()
    
    statements = sql_content.split(';')
    executed = 0
    errors = 0
    
    for stmt in statements:
        lines = [line for line in stmt.split('\n') if line.strip() and not line.strip().startswith('--')]
        clean_stmt = '\n'.join(lines).strip()
        
        if not clean_stmt:
            continue
            
        try:
            cursor.execute(clean_stmt)
            executed += 1
        except Exception as e:
            errors += 1
            print(f"    WARN: {str(e).strip()[:100]}")
            
    cursor.close()
    conn.close()
    print(f"[+] Completado: {executed} ejecutadas, {errors} advertencias.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    
    for filepath in sys.argv[1:]:
        run_sql_file(filepath)
    print("\n[OK] Listo.")
