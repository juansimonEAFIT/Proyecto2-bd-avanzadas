-- Archivo de apoyo para analizar planes de ejecución
-- Estas consultas están pensadas para ejecutarse más adelante
-- con EXPLAIN y EXPLAIN ANALYZE en el entorno ya desplegado

-- Consulta 1
-- Analizar el acceso a publicaciones por usuario
EXPLAIN
SELECT
    p.post_id,
    p.user_id,
    p.created_at,
    p.likes_count
FROM posts p
WHERE p.user_id = 25
ORDER BY p.created_at DESC;

-- Consulta 2
-- Analizar el conteo de comentarios por publicación
EXPLAIN
SELECT
    p.post_id,
    COUNT(c.comment_id) AS total_comments
FROM posts p
LEFT JOIN comments c ON p.post_id = c.post_id
GROUP BY p.post_id
ORDER BY total_comments DESC;

-- Consulta 3
-- Analizar publicaciones por facultad
EXPLAIN
SELECT
    u.faculty,
    COUNT(p.post_id) AS total_posts
FROM users u
JOIN posts p ON u.user_id = p.user_id
GROUP BY u.faculty
ORDER BY total_posts DESC;

-- Consulta 4
-- Analizar interacciones por tipo de evento
EXPLAIN
SELECT
    event_type,
    COUNT(*) AS total_events
FROM interaction_log
GROUP BY event_type
ORDER BY total_events DESC;

-- Consulta 5
-- Analizar actividad de un usuario dentro del log
EXPLAIN
SELECT
    event_id,
    user_id,
    post_id,
    event_type,
    created_at
FROM interaction_log
WHERE user_id = 40
ORDER BY created_at DESC;

-- Consulta 6
-- Analizar join entre comentarios, publicaciones y usuarios
-- Esta es una buena candidata para compararla luego
-- frente a una ejecución distribuida
EXPLAIN
SELECT
    c.comment_id,
    c.post_id,
    c.user_id AS comment_author_id,
    u.username,
    p.user_id AS post_author_id,
    c.created_at
FROM comments c
JOIN users u ON c.user_id = u.user_id
JOIN posts p ON c.post_id = p.post_id
ORDER BY c.comment_id ASC
LIMIT 100;

-- Consulta 7
-- Analizar top de publicaciones con más likes
EXPLAIN
SELECT
    p.post_id,
    p.user_id,
    p.likes_count,
    p.comments_count
FROM posts p
ORDER BY p.likes_count DESC, p.post_id ASC
LIMIT 10;

-- Consulta 8
-- Versión con EXPLAIN ANALYZE para medir ejecución real
-- Esta consulta conviene correrla después de cargar datos
-- y cuando ya tengan listo el ambiente
EXPLAIN ANALYZE
SELECT
    c.comment_id,
    c.post_id,
    p.user_id AS post_author_id,
    c.user_id AS comment_author_id,
    u.username,
    c.created_at
FROM comments c
JOIN posts p ON c.post_id = p.post_id
JOIN users u ON c.user_id = u.user_id
ORDER BY c.comment_id ASC
LIMIT 100;

-- Consulta 9
-- Versión con EXPLAIN ANALYZE para el log de interacciones
EXPLAIN ANALYZE
SELECT
    DATE(created_at) AS interaction_date,
    event_type,
    COUNT(*) AS total_interactions
FROM interaction_log
GROUP BY DATE(created_at), event_type
ORDER BY interaction_date ASC, event_type ASC;