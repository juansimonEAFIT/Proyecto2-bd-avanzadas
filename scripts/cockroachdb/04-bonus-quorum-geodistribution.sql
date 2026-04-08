-- BONUS: Quorum y geodistribucion en CockroachDB

-- Ver zonas actuales
SELECT * FROM crdb_internal.zones;

-- Ver estado de ranges y replicas
SELECT range_id, start_key_pretty, end_key_pretty, replicas
FROM crdb_internal.ranges
LIMIT 50;

-- Ejemplo de configuracion de replicas (ajustar segun entorno)
-- ALTER TABLE users CONFIGURE ZONE USING num_replicas = 3;
-- ALTER TABLE posts CONFIGURE ZONE USING num_replicas = 3;

-- Simulacion conceptual de quorum:
-- 1) Confirmar 3 nodos activos
-- 2) Detener 2 nodos
-- 3) Intentar escritura y observar si se bloquea por falta de quorum

-- Ver estado de nodos
SHOW NODES;
