import os
import urllib
import pandas as pd
from sqlalchemy import create_engine
from dotenv import load_dotenv

def get_engine():
    """Configura el motor de base de datos usando SQLAlchemy y pyodbc."""
    # Cargar variables de entorno desde .env si existe
    load_dotenv()
    
    # Parámetros desde el .env o valores por defecto
    # IMPORTANTE: Para SQL Server en Windows, el DRIVER por defecto suele ser 'ODBC Driver 17 for SQL Server' o similar
    server = os.getenv('DB_SERVER', 'localhost,1433')
    database = os.getenv('DB_NAME', 'BI_Staging')
    username = os.getenv('DB_USER', 'retail_admin')
    password = os.getenv('DB_PASSWORD', 'admin123')
    
    # Crear string de conexión ODBC
    # Usa Trusted_Connection=yes si quieres autenticación de Windows local,
    # pero aquí usaremos usuario y contraseña como pide el proyecto.
    params = urllib.parse.quote_plus(
        f"DRIVER={{ODBC Driver 17 for SQL Server}};"
        f"SERVER={server};"
        f"DATABASE={database};"
        f"UID={username};"
        f"PWD={password}"
    )
    
    engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")
    return engine

def load_metas(engine):
    """Carga metas_mensuales.csv en STG_MetasExternas."""
    print("Cargando metas_mensuales.csv...")
    file_path = os.path.join('..', '05_external_sources', 'metas_mensuales.csv')
    
    if not os.path.exists(file_path):
        print(f"Error: No se encontró {file_path}")
        return
        
    df = pd.read_csv(file_path)
    
    try:
        # Se insertan los datos usando pandas.to_sql
        # No especificamos las columnas de auditoria (Fuente, FechaCarga, etc.) 
        # para que SQL Server utilice los valores DEFAULT definidos en la tabla.
        
        # Primero vaciamos la tabla de staging
        from sqlalchemy import text
        with engine.begin() as conn:
            conn.execute(text("TRUNCATE TABLE STG_MetasExternas"))
            
        df.to_sql('STG_MetasExternas', con=engine, if_exists='append', index=False)
        print(f"Éxito: Se cargaron {len(df)} registros en STG_MetasExternas.")
    except Exception as e:
        print(f"Error cargando metas: {e}")

def load_inventario(engine):
    """Carga inventario_fisico.csv en STG_InventarioFisico."""
    print("Cargando inventario_fisico.csv...")
    file_path = os.path.join('..', '05_external_sources', 'inventario_fisico.csv')
    
    if not os.path.exists(file_path):
        print(f"Error: No se encontró {file_path}")
        return
        
    df = pd.read_csv(file_path)
    
    try:
        from sqlalchemy import text
        with engine.begin() as conn:
            conn.execute(text("TRUNCATE TABLE STG_InventarioFisico"))
            
        df.to_sql('STG_InventarioFisico', con=engine, if_exists='append', index=False)
        print(f"Éxito: Se cargaron {len(df)} registros en STG_InventarioFisico.")
    except Exception as e:
        print(f"Error cargando inventario: {e}")

if __name__ == "__main__":
    print("Iniciando carga de archivos CSV al área de Staging...")
    engine = get_engine()
    
    load_metas(engine)
    load_inventario(engine)
    
    print("Proceso finalizado.")
