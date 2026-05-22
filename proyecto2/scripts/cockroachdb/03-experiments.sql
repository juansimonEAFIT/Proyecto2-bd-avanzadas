-- ============================================================================
-- EXPERIMENTOS Y QUERIES PARA COCKROACHDB
-- ============================================================================

-- ============================================================================
-- EXPERIMENTO 1: Info de distribución en CockroachDB
-- ============================================================================

-- Ver información de rangos (ranges) - distribución automática
SELECT 
    table_name,
    COUNT(*) as num_ranges,
    SUM(size_bytes) / 1024.0 / 1024.0 as size_mb
FROM crdb_internal.ranges
GROUP BY table_name
ORDER BY table_name;

-- ============================================================================
-- EXPERIMENTO 2: Latencia de escritura - Transacción simple
-- ============================================================================

-- BEGIN;
-- INSERT INTO users (user_id, username, email, full_name)
-- VALUES (99999, 'test_user', 'test@example.com', 'Test User');
-- COMMIT;

-- ============================================================================
-- EXPERIMENTO 3: Query dentro de un range (intra-shard)
-- ============================================================================

-- EXPLAIN ANALYZE SELECT u.*, COUNT(p.post_id) as post_count
-- FROM users u
-- LEFT JOIN posts p ON u.user_id = p.user_id
-- WHERE u.user_id = 1
-- GROUP BY u.user_id;

-- ============================================================================
-- EXPERIMENTO 4: Join distribuido entre múltiples ranges
-- ============================================================================

-- EXPLAIN ANALYZE SELECT 
--     u.username,
--     COUNT(DISTINCT p.post_id) as num_posts,
--     COUNT(DISTINCT pl.like_id) as num_likes,
--     COUNT(DISTINCT f.follower_id) as num_followers
-- FROM users u
-- LEFT JOIN posts p ON u.user_id = p.user_id
-- LEFT JOIN post_likes pl ON p.post_id = pl.post_id
-- LEFT JOIN followers f ON u.user_id = f.following_id
-- WHERE u.user_id BETWEEN 1 AND 100
-- GROUP BY u.user_id;

-- ============================================================================
-- EXPERIMENTO 5: Aggregación distribuida
-- ============================================================================

-- EXPLAIN ANALYZE SELECT 
--     DATE_TRUNC('day', created_at) as creation_date,
--     COUNT(*) as num_posts,
--     AVG(like_count)::FLOAT as avg_likes
-- FROM posts
-- WHERE created_at >= now() - INTERVAL '30 days'
-- GROUP BY DATE_TRUNC('day', created_at)
-- ORDER BY creation_date DESC;

-- ============================================================================
-- EXPERIMENTO 6: Transacción distribuida en CockroachDB (ACID garantizado)
-- ============================================================================

-- CockroachDB maneja automáticamente transacciones distribuidas
BEGIN TRANSACTION;
    -- INSERT en tabla users
    INSERT INTO users (user_id, username, email, full_name)
    VALUES (99998, 'crdb_user', 'crdb@example.com', 'CockroachDB User');
    
    -- INSERT en tabla followers (puede estar en diferentes ranges)
    INSERT INTO followers (follower_id, following_id)
    VALUES (99998, 1);
    
    -- UPDATE en tabla users (contador)
    UPDATE users SET following_count = following_count + 1 WHERE user_id = 1;
    
COMMIT;

-- ============================================================================
-- EXPERIMENTO 7: Monitoreo de transacciones en vuelo
-- ============================================================================

-- Ver transacciones activas en CockroachDB
SELECT 
    node_id,
    txn_id,
    application_name,
    num_statements,
    timestamp
FROM crdb_internal.node_txn_stats;

-- ============================================================================
-- EXPERIMENTO 8: Estadísticas del cluster
-- ============================================================================

-- Ver información de nodos
SELECT * FROM crdb_internal.cluster_info;

-- Ver configuración de replicación
SELECT * FROM crdb_internal.ranges;

-- ============================================================================
-- EXPERIMENTO 9: Zona de configuración para geo-distribución
-- ============================================================================

-- Ver zonas configuradas
SELECT * FROM crdb_internal.zones;

-- Configurar zona para tabla específica (comentado - activar según necesidad)
-- ALTER TABLE users CONFIGURE ZONE USING num_replicas = 3;
-- ALTER TABLE posts CONFIGURE ZONE USING num_replicas = 3;

-- ============================================================================
-- EXPERIMENTO 10: Procedure para simular carga
-- ============================================================================

-- CockroachDB usa BEGIN TRANSACTION para procedimientos
CREATE PROCEDURE sp_write_load_test_crdb(
    p_iterations INT64
)
LANGUAGE SQL AS $$
    INSERT INTO users (user_id, username, email, full_name)
    SELECT 
        99999 + row_number() OVER () as user_id,
        'loadtest_' || row_number() OVER () as username,
        'loadtest_' || row_number() OVER () || '@example.com' as email,
        'Load Test User ' || row_number() OVER () as full_name
    FROM generate_series(1, p_iterations);
$$;

-- ============================================================================
-- EXPERIMENTO 11: Simular fallo de escritura con Quorum
-- ============================================================================

-- En CockroachDB, configurar para requerir diferentes quórums
-- ALTER TABLE users CONFIGURE ZONE USING num_replicas = 5;
-- Esto requería 5 replicas para un quórum (3 de 5)

