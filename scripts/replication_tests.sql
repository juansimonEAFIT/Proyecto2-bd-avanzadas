-- Archivo guía para pruebas de replicación en PostgreSQL
-- Este archivo no está pensado para ejecutarse completo de una sola vez
-- Se debe usar por bloques, conectándose al nodo correspondiente

-- Prueba 1
-- Verificar si el nodo actual es primario o réplica
-- En el primario debe devolver false
-- En una réplica debe devolver true
SELECT pg_is_in_recovery() AS is_replica;

-- Prueba 2
-- Verificar si el nodo permite escritura
-- En el primario debería mostrar off
-- En la réplica normalmente debería mostrar on
SHOW transaction_read_only;

-- Prueba 3
-- Revisar configuración de confirmación de escritura
-- Esta prueba sirve para documentar si la replicación está configurada
-- con mayor prioridad en consistencia o en latencia
SHOW synchronous_commit;

-- Prueba 4
-- Insertar una publicación de prueba en el nodo primario
-- Esta consulta debe ejecutarse solo en el primario
INSERT INTO posts (
    post_id,
    user_id,
    content,
    visibility,
    likes_count,
    comments_count,
    created_at
)
VALUES (
    999001,
    1,
    'Post de prueba para validar replicación entre primario y réplicas',
    'public',
    0,
    0,
    CURRENT_TIMESTAMP
);

-- Prueba 5
-- Validar inmediatamente en el primario que el registro existe
SELECT
    post_id,
    user_id,
    content,
    created_at
FROM posts
WHERE post_id = 999001;

-- Prueba 6
-- Validar en la réplica 1 si ya llegó la publicación
-- Ejecutar esta consulta conectados a replica1
SELECT
    post_id,
    user_id,
    content,
    created_at
FROM posts
WHERE post_id = 999001;

-- Prueba 7
-- Validar en la réplica 2 si ya llegó la publicación
-- Ejecutar esta consulta conectados a replica2
SELECT
    post_id,
    user_id,
    content,
    created_at
FROM posts
WHERE post_id = 999001;

-- Prueba 8
-- Registrar una medición manual del experimento en la tabla de resultados
-- Ajustar los tiempos reales cuando el experimento se ejecute
INSERT INTO experiment_results (
    experiment_name,
    test_type,
    node_name,
    operation_type,
    start_time,
    end_time,
    latency_ms,
    rows_affected,
    success,
    consistency_mode,
    notes
)
VALUES (
    'replication_post_insert_primary',
    'replication',
    'primary',
    'write',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    0.00,
    1,
    true,
    'pending_definition',
    'Registro inicial de prueba para documentar inserción en el nodo primario'
);

-- Prueba 9
-- Medir lectura en el primario sobre la publicación insertada
EXPLAIN ANALYZE
SELECT
    post_id,
    user_id,
    content,
    created_at
FROM posts
WHERE post_id = 999001;

-- Prueba 10
-- Medir lectura de publicaciones recientes
-- Esta prueba puede compararse entre primario y réplicas
EXPLAIN ANALYZE
SELECT
    post_id,
    user_id,
    created_at,
    likes_count
FROM posts
ORDER BY created_at DESC
LIMIT 20;

-- Prueba 11
-- Validar el estado del nodo actual desde la perspectiva de recuperación
-- Útil para documentar si el nodo sigue siendo réplica o ya fue promovido
SELECT
    pg_is_in_recovery() AS is_replica,
    CURRENT_TIMESTAMP AS validation_time;

-- Prueba 12
-- Validación de solo lectura en réplicas
-- Esta consulta debe ejecutarse en una réplica
-- Si la réplica está bien configurada, un INSERT debería fallar
-- Dejar comentada hasta el momento de la prueba
-- INSERT INTO posts (
--     post_id,
--     user_id,
--     content,
--     visibility,
--     likes_count,
--     comments_count,
--     created_at
-- )
-- VALUES (
--     999002,
--     1,
--     'Intento de escritura en réplica',
--     'public',
--     0,
--     0,
--     CURRENT_TIMESTAMP
-- );

-- Prueba 13
-- Consulta para revisar si la información reciente ya está disponible
-- en el nodo actual
SELECT
    COUNT(*) AS replicated_rows
FROM posts
WHERE post_id IN (999001);

-- Prueba 14
-- Validación posterior a failover
-- Esta prueba se ejecuta después de promover manualmente una réplica
-- Si la promoción fue exitosa, pg_is_in_recovery debe devolver false
SELECT
    pg_is_in_recovery() AS is_replica_after_promotion,
    CURRENT_TIMESTAMP AS promotion_check_time;

-- Prueba 15
-- Escritura de validación después del failover
-- Ejecutar solo en el nodo promovido a primario
INSERT INTO posts (
    post_id,
    user_id,
    content,
    visibility,
    likes_count,
    comments_count,
    created_at
)
VALUES (
    999003,
    2,
    'Post de prueba después del failover',
    'public',
    0,
    0,
    CURRENT_TIMESTAMP
);

-- Prueba 16
-- Confirmar que la nueva escritura existe en el nodo promovido
SELECT
    post_id,
    user_id,
    content,
    created_at
FROM posts
WHERE post_id = 999003;

-- Prueba 17
-- Registrar medición posterior a failover
INSERT INTO experiment_results (
    experiment_name,
    test_type,
    node_name,
    operation_type,
    start_time,
    end_time,
    latency_ms,
    rows_affected,
    success,
    consistency_mode,
    notes
)
VALUES (
    'replication_failover_validation',
    'replication',
    'promoted_node',
    'write_after_failover',
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP,
    0.00,
    1,
    true,
    'pending_definition',
    'Registro de validación después de promoción manual de réplica'
);

-- Prueba 18
-- Limpieza opcional del escenario de prueba
-- Ejecutar solo cuando ya no necesiten los registros insertados
-- y dependiendo del nodo que haya quedado como primario
-- DELETE FROM posts WHERE post_id IN (999001, 999003);