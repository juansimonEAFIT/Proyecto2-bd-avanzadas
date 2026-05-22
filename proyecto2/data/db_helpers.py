#!/usr/bin/env python3
"""
SOCIAL NETWORK - Utilidades para Conexión y Pruebas
Facilita la conexión a bases de datos y ejecución de experimentos
"""

import psycopg2
from psycopg2 import sql, extras
import time
import os
from typing import List, Dict, Any
from contextlib import contextmanager


def build_postgres_env_config(role: str = "primary", application_name: str = None) -> Dict[str, Any]:
    """Construye configuracion de PostgreSQL a partir del .env.

    role:
    - primary
    - replica1
    - replica2
    """
    role_map = {
        "primary": ("PG_PRIMARY_HOST", "PG_PRIMARY_PORT"),
        "replica1": ("PG_REPLICA1_HOST", "PG_REPLICA1_PORT"),
        "replica2": ("PG_REPLICA2_HOST", "PG_REPLICA2_PORT"),
    }
    host_key, port_key = role_map.get(role, role_map["primary"])
    config = {
        "host": os.getenv(host_key, "localhost"),
        "port": int(os.getenv(port_key, 5432)),
        "database": os.getenv("PG_DATABASE", "social_network"),
        "user": os.getenv("PG_USER", "admin"),
        "password": os.getenv("PG_PASSWORD", "admin123"),
        "connect_timeout": int(os.getenv("PG_CONNECT_TIMEOUT", "10")),
    }
    if application_name:
        config["application_name"] = application_name
    return config


class PostgreSQLConnection:
    """Gestor de conexiones a PostgreSQL"""
    
    def __init__(self, host: str, port: int = 5432, database: str = 'social_network',
                 user: str = 'admin', password: str = 'admin123',
                 connect_timeout: int = 10, application_name: str = None):
        self.host = host
        self.port = port
        self.database = database
        self.user = user
        self.password = password
        self.connect_timeout = connect_timeout
        self.application_name = application_name
        self.conn = None

    def connect(self):
        """Establece conexión con la base de datos"""
        kwargs = {
            "host": self.host,
            "port": self.port,
            "database": self.database,
            "user": self.user,
            "password": self.password,
            "connect_timeout": self.connect_timeout,
        }
        if self.application_name:
            kwargs["application_name"] = self.application_name
        self.conn = psycopg2.connect(
            **kwargs
        )
        return self.conn

    @contextmanager
    def get_cursor(self):
        """Context manager para obtener cursor"""
        if not self.conn:
            self.connect()
        
        cursor = self.conn.cursor()
        try:
            yield cursor
            self.conn.commit()
        except Exception as e:
            self.conn.rollback()
            raise e
        finally:
            cursor.close()

    def execute_query(self, query: str, params: tuple = ()) -> List[Dict]:
        """Ejecuta una query SELECT y retorna resultados"""
        with self.get_cursor() as cursor:
            cursor.execute(query, params)
            columns = [desc[0] for desc in cursor.description]
            return [dict(zip(columns, row)) for row in cursor.fetchall()]

    def execute_update(self, query: str, params: tuple = ()):
        """Ejecuta una query de actualización (INSERT, UPDATE, DELETE)"""
        with self.get_cursor() as cursor:
            cursor.execute(query, params)
            return cursor.rowcount

    def execute_batch(self, query: str, data: List[tuple]):
        """Ejecuta múltiples operaciones en batch"""
        with self.get_cursor() as cursor:
            cursor.executemany(query, data)
            return cursor.rowcount

    def close(self):
        """Cierra la conexión"""
        if self.conn:
            self.conn.close()


class PerformanceTester:
    """Pruebas de rendimiento para bases de datos distribuidas"""
    
    def __init__(self, db_conn: PostgreSQLConnection):
        self.db = db_conn

    def measure_insert_latency(self, table: str, values, iterations: int = 100) -> Dict:
        """Mide la latencia de inserciones"""
        latencies = []
        error_count = 0
        
        for i in range(iterations):
            start = time.time()
            
            # Generar datos en cada iteración si se pasó un generador (lambda)
            current_values = values(i) if callable(values) else values
            
            # Preparar query
            columns = list(current_values.keys())
            placeholders = ', '.join(['%s'] * len(columns))
            query = f"INSERT INTO {table} ({', '.join(columns)}) VALUES ({placeholders})"
            
            # Ejecutar
            try:
                self.db.execute_update(query, tuple(current_values.values()))
                latency = (time.time() - start) * 1000  # Convert to ms
                latencies.append(latency)
            except Exception as e:
                error_count += 1
                print(f"Error en iteración {i}: {e}")
        
        return self._calculate_stats(latencies, error_count=error_count, requested_iterations=iterations)

    def measure_select_latency(self, query: str, iterations: int = 100) -> Dict:
        """Mide la latencia de selecciones"""
        latencies = []
        error_count = 0
        
        for i in range(iterations):
            start = time.time()
            
            try:
                self.db.execute_query(query)
                latency = (time.time() - start) * 1000  # Convert to ms
                latencies.append(latency)
            except Exception as e:
                error_count += 1
                print(f"Error en iteración {i}: {e}")
        
        return self._calculate_stats(latencies, error_count=error_count, requested_iterations=iterations)

    def measure_join_latency(self, query: str, iterations: int = 100) -> Dict:
        """Mide la latencia de joins (puede ser inter-shard)"""
        latencies = []
        error_count = 0
        
        for i in range(iterations):
            start = time.time()
            
            try:
                self.db.execute_query(query)
                latency = (time.time() - start) * 1000
                latencies.append(latency)
            except Exception as e:
                error_count += 1
                print(f"Error en iteración {i}: {e}")
        
        return self._calculate_stats(latencies, error_count=error_count, requested_iterations=iterations)

    def measure_transaction_latency(self, operations: List[str], iterations: int = 100) -> Dict:
        """Mide la latencia de transacciones complejas"""
        latencies = []
        error_count = 0
        
        for i in range(iterations):
            start = time.time()
            
            try:
                with self.db.get_cursor() as cursor:
                    for op in operations:
                        cursor.execute(op)
                
                latency = (time.time() - start) * 1000
                latencies.append(latency)
            except Exception as e:
                error_count += 1
                print(f"Error en iteración {i}: {e}")
        
        return self._calculate_stats(latencies, error_count=error_count, requested_iterations=iterations)

    def get_table_stats(self, table: str) -> Dict:
        """Obtiene estadísticas de una tabla"""
        query = f"""
            SELECT 
                schemaname,
                tablename,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
                n_live_tup as row_count
            FROM pg_stat_user_tables
            WHERE tablename = %s
        """
        
        results = self.db.execute_query(query, (table,))
        return results[0] if results else None

    def get_partition_distribution(self, table: str) -> List[Dict]:
        """Obtiene información sobre la distribución en particiones"""
        query = f"""
            SELECT 
                schemaname,
                tablename,
                pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
                n_live_tup as row_count
            FROM pg_stat_user_tables
            WHERE tablename LIKE %s
            ORDER BY tablename
        """
        
        pattern = f"{table}_%"
        return self.db.execute_query(query, (pattern,))

    def get_replication_status(self) -> List[Dict]:
        """Obtiene el estado de la replicación"""
        query = """
            SELECT 
                application_name,
                client_addr,
                state,
                write_lag,
                flush_lag,
                replay_lag
            FROM pg_stat_replication
        """
        
        return self.db.execute_query(query)

    def _calculate_stats(self, values: List[float], error_count: int = 0, requested_iterations: int = None) -> Dict:
        """Calcula estadísticas de un conjunto de valores"""
        if not values:
            return {
                'count': 0,
                'requested_iterations': requested_iterations or 0,
                'error_count': error_count,
            }
        
        values.sort()
        n = len(values)
        mean = sum(values) / n
        
        return {
            'count': n,
            'requested_iterations': requested_iterations or n,
            'error_count': error_count,
            'min': min(values),
            'max': max(values),
            'mean': mean,
            'median': values[n // 2],
            'p95': values[min(n - 1, int(n * 0.95))],
            'p99': values[min(n - 1, int(n * 0.99))],
            'std_dev': (sum((x - mean) ** 2 for x in values) / n) ** 0.5
        }


class DistributedTransactionTester:
    """Utilidades para probar transacciones distribuidas (2PC)"""
    
    def __init__(self, primary_conn: PostgreSQLConnection, replica_conn: PostgreSQLConnection = None):
        self.primary = primary_conn
        self.replica = replica_conn

    def test_2pc_simple(self, operation_id: str):
        """Prueba de 2PC simple"""
        try:
            # Prepare
            query = f"PREPARE TRANSACTION '{operation_id}';"
            self.primary.execute_update(query)
            print(f"2PC Prepared: {operation_id}")
            
            # Ver transacciones preparadas
            tx_list = self.primary.execute_query("SELECT * FROM pg_prepared_xacts;")
            print(f"Prepared transactions: {len(tx_list)}")
            
            return True
        except Exception as e:
            print(f"Error en 2PC: {e}")
            return False

    def test_2pc_commit(self, operation_id: str):
        """Commit de transacción preparada"""
        try:
            query = f"COMMIT PREPARED '{operation_id}';"
            self.primary.execute_update(query)
            print(f"2PC Committed: {operation_id}")
            return True
        except Exception as e:
            print(f"Error en commit: {e}")
            return False

    def test_2pc_rollback(self, operation_id: str):
        """Rollback de transacción preparada"""
        try:
            query = f"ROLLBACK PREPARED '{operation_id}';"
            self.primary.execute_update(query)
            print(f"2PC Rolled back: {operation_id}")
            return True
        except Exception as e:
            print(f"Error en rollback: {e}")
            return False


if __name__ == "__main__":
    # Ejemplo de uso
    db = PostgreSQLConnection(
        host='localhost',
        port=5432,
        database='social_network',
        user='admin',
        password='admin123'
    )
    
    try:
        db.connect()
        print("Conexión establecida!")
        
        # Prueba de tester de rendimiento
        tester = PerformanceTester(db)
        
        # Medir estadísticas de tabla
        stats = tester.get_table_stats('users')
        print(f"Estadísticas de tabla users: {stats}")
        
        # Medir estado de replicación
        repl_status = tester.get_replication_status()
        print(f"Estado de replicación: {repl_status}")
        
    except Exception as e:
        print(f"Error: {e}")
    finally:
        db.close()

