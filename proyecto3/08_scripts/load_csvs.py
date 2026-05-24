import os
import csv
import pyodbc
from dotenv import load_dotenv

def get_connection():
    """Establece una conexión directa de pyodbc a la base de datos BI_Staging."""
    load_dotenv()
    server = os.getenv('DB_SERVER', 'localhost,1433')
    database = os.getenv('DB_NAME', 'BI_Staging')
    username = os.getenv('DB_USER', 'retail_admin')
    password = os.getenv('DB_PASSWORD', 'admin123')
    
    conn_str = (
        f"DRIVER={{SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password}"
    )
    
    # Autocommit True para que los cambios se guarden inmediatamente sin transacciones manuales
    conn = pyodbc.connect(conn_str, autocommit=True)
    return conn

def load_metas(conn):
    """Carga metas_mensuales.csv en STG_MetasExternas."""
    print("Cargando metas_mensuales.csv...")
    file_path = os.path.join('..', '05_external_sources', 'metas_mensuales.csv')
    
    if not os.path.exists(file_path):
        print(f"Error: No se encontró {file_path}")
        return
        
    cursor = conn.cursor()
    # Primero vaciamos la tabla de staging
    cursor.execute("TRUNCATE TABLE STG_MetasExternas")
    
    with open(file_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        count = 0
        for row in reader:
            # Anio,Mes,NombreTienda,NombreCategoria,ValorMeta
            anio = int(row['Anio'])
            mes = int(row['Mes'])
            tienda = row['NombreTienda']
            categoria = row['NombreCategoria']
            meta = float(row['ValorMeta'])
            
            cursor.execute(
                "INSERT INTO STG_MetasExternas (Anio, Mes, NombreTienda, NombreCategoria, ValorMeta) "
                "VALUES (?, ?, ?, ?, ?)",
                (anio, mes, tienda, categoria, meta)
            )
            count += 1
            
    cursor.close()
    print(f"Éxito: Se cargaron {count} registros en STG_MetasExternas.")

def load_inventario(conn):
    """Carga inventario_fisico.csv en STG_InventarioFisico."""
    print("Cargando inventario_fisico.csv...")
    file_path = os.path.join('..', '05_external_sources', 'inventario_fisico.csv')
    
    if not os.path.exists(file_path):
        print(f"Error: No se encontró {file_path}")
        return
        
    cursor = conn.cursor()
    # Primero vaciamos la tabla de staging
    cursor.execute("TRUNCATE TABLE STG_InventarioFisico")
    
    with open(file_path, mode='r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        count = 0
        for row in reader:
            # FechaConteo,CodigoSKU,NombreTienda,StockContado,StockSistema,Diferencia,Observacion
            fecha = row['FechaConteo']
            sku = row['CodigoSKU']
            tienda = row['NombreTienda']
            stock_contado = int(row['StockContado'])
            stock_sistema = int(row['StockSistema'])
            diferencia = int(row['Diferencia'])
            observacion = row['Observacion']
            
            cursor.execute(
                "INSERT INTO STG_InventarioFisico (FechaConteo, CodigoSKU, NombreTienda, StockContado, StockSistema, Diferencia, Observacion) "
                "VALUES (?, ?, ?, ?, ?, ?, ?)",
                (fecha, sku, tienda, stock_contado, stock_sistema, diferencia, observacion)
            )
            count += 1
            
    cursor.close()
    print(f"Éxito: Se cargaron {count} registros en STG_InventarioFisico.")

if __name__ == "__main__":
    print("Iniciando carga de archivos CSV al área de Staging (vía pyodbc nativo)...")
    try:
        conn = get_connection()
        load_metas(conn)
        load_inventario(conn)
        conn.close()
        print("Proceso finalizado.")
    except Exception as e:
        print(f"Ocurrió un error en la carga de CSVs: {e}")
