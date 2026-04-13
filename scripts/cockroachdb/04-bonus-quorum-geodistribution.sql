-- BONUS: Geodistribucion + quorum en CockroachDB
-- Ejecutar en el nodo 1 del cluster de latencia.

CREATE DATABASE IF NOT EXISTS bonus_geo;
USE bonus_geo;

-- Habilita consultas de diagnostico en crdb_internal para entorno de laboratorio.
SET allow_unsafe_internals = true;

-- Tabla simple para medir escrituras mientras se inyecta latencia.
CREATE TABLE IF NOT EXISTS geo_ping (
	id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
	writer_region STRING NOT NULL,
	payload STRING,
	created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Garantiza factor de replicacion 3 para el escenario de quorum.
ALTER DATABASE bonus_geo CONFIGURE ZONE USING num_replicas = 3;

-- Verifica localities de nodos (base de geodistribucion).
SELECT node_id, locality, sql_address, is_live
FROM crdb_internal.gossip_nodes
ORDER BY node_id;

-- Valida estado de replicas por range.
SELECT range_id, replicas
FROM crdb_internal.ranges
LIMIT 30;

-- Insercion de sanity check.
INSERT INTO geo_ping (writer_region, payload)
VALUES ('bootstrap', 'init ok');

SELECT count(*) AS total_rows, min(created_at) AS first_write, max(created_at) AS last_write
FROM geo_ping;

-- Recomendacion para prueba de quorum (desde PowerShell):
-- 1) detener 2 nodos
-- 2) intentar INSERT en bonus_geo.geo_ping
-- 3) validar error por quorum insuficiente
