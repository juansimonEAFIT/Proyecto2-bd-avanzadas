-- Consultas de monitoreo comunes para el proyecto

-- PostgreSQL: conexiones activas
-- SELECT datname, usename, state, query_start, query FROM pg_stat_activity;

-- PostgreSQL: estado de replicacion
-- SELECT * FROM pg_stat_replication;

-- CockroachDB: estado de nodos
-- SHOW NODES;

-- CockroachDB: estado de ranges
-- SELECT range_id, start_key_pretty, end_key_pretty, replicas FROM crdb_internal.ranges LIMIT 100;
