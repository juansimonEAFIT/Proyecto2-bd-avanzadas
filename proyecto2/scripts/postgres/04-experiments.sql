-- ============================================================================
-- QUERIES PARA EXPERIMENTOS Y ANÁLISIS
-- ============================================================================
-- Queries para ejecutar en los experimentos y medir latencia

-- ============================================================================
-- EXPERIMENTO 1: Latencia de escritura con synchronous_commit ON
-- ============================================================================

-- Medir latencia de INSERT simple en tabla particionada
-- EXPLAIN ANALYZE INSERT INTO users (username, email, full_name) 
-- VALUES ('test_user', 'test@example.com', 'Test User');

-- ============================================================================
-- EXPERIMENTO 2: Query dentro de una partición (INTRA-SHARD)
-- ============================================================================
-- Esta query debe tocar solo una partición

-- EXPLAIN ANALYZE SELECT u.*, COUNT(p.post_id) as post_count
-- FROM users u
-- LEFT JOIN posts p ON u.user_id = p.user_id
-- WHERE u.username = 'user_1_12345ab'
-- GROUP BY u.user_id;

-- ============================================================================
-- EXPERIMENTO 3: Query entre particiones (INTER-SHARD) - JOIN DISTRIBUIDO
-- ============================================================================
-- Esta query toca múltiples particiones y requiere materialización

-- EXPLAIN ANALYZE SELECT 
--     u.username,
--     COUNT(DISTINCT p.post_id) as num_posts,
--     COUNT(DISTINCT pl.like_id) as num_likes,
--     COUNT(DISTINCT f.follower_id) as num_followers
-- FROM users u
-- LEFT JOIN posts p ON u.user_id = p.user_id
-- LEFT JOIN post_likes pl ON p.post_id = pl.post_id
-- LEFT JOIN followers f ON u.user_id = f.following_id
-- GROUP BY u.user_id
-- LIMIT 100;

-- ============================================================================
-- EXPERIMENTO 4: Agregación distribuida con GROUP BY
-- ============================================================================

-- EXPLAIN ANALYZE SELECT 
--     EXTRACT(DATE FROM created_at) as creation_date,
--     COUNT(*) as num_posts,
--     AVG(like_count) as avg_likes
-- FROM posts
-- WHERE created_at >= CURRENT_TIMESTAMP - INTERVAL '30 days'
-- GROUP BY EXTRACT(DATE FROM created_at)
-- ORDER BY creation_date DESC;

-- ============================================================================
-- EXPERIMENTO 5: Transacción distribuida - 2PC (monitoreo)
-- ============================================================================

-- Ver transacciones preparadas
SELECT * FROM pg_prepared_xacts;

-- Ver locks activos
SELECT 
    a.usename,
    a.application_name,
    a.query,
    a.query_start,
    l.locktype,
    l.mode
FROM pg_stat_activity a
JOIN pg_locks l ON a.pid = l.pid
WHERE a.state = 'active'
ORDER BY a.query_start;

-- ============================================================================
-- EXPERIMENTO 6: Estadísticas de particiones
-- ============================================================================

-- Ver tamaño de cada partición
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE tablename LIKE 'users_p%' OR tablename LIKE 'posts_p%' OR tablename LIKE 'comments_p%'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ============================================================================
-- EXPERIMENTO 7: Monitoreo de replicación
-- ============================================================================

-- Ver estado de la replicación en el PRIMARY
SELECT 
    pid,
    usename,
    application_name,
    client_addr,
    state,
    write_lag,
    flush_lag,
    replay_lag
FROM pg_stat_replication;

-- ============================================================================
-- EXPERIMENTO 8: Procedimiento para simular carga de escritura
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_write_load_test(
    p_iterations INT DEFAULT 1000
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT := 0;
    v_start TIMESTAMP;
    v_duration INTERVAL;
BEGIN
    v_start := CURRENT_TIMESTAMP;
    
    FOR v_i IN 1..p_iterations LOOP
        INSERT INTO users (username, email, full_name)
        VALUES (
            'loadtest_' || v_i || '_' || SUBSTRING(gen_random_uuid()::TEXT, 1, 8),
            'loadtest_' || v_i || '@example.com',
            'Load Test User ' || v_i
        );
    END LOOP;
    
    v_duration := CURRENT_TIMESTAMP - v_start;
    RAISE NOTICE 'Write load test completed: % iterations in %', p_iterations, v_duration;
END;
$$;

-- ============================================================================
-- EXPERIMENTO 9: Procedimiento para simular carga de lectura
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_read_load_test(
    p_iterations INT DEFAULT 1000
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT := 0;
    v_start TIMESTAMP;
    v_duration INTERVAL;
    v_dummy RECORD;
BEGIN
    v_start := CURRENT_TIMESTAMP;
    
    FOR v_i IN 1..p_iterations LOOP
        SELECT * INTO v_dummy FROM users ORDER BY RANDOM() LIMIT 1;
    END LOOP;
    
    v_duration := CURRENT_TIMESTAMP - v_start;
    RAISE NOTICE 'Read load test completed: % iterations in %', p_iterations, v_duration;
END;
$$;

