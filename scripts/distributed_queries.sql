-- Consulta 1:
-- Cantidad de publicaciones por facultad
SELECT
    u.faculty,
    COUNT(p.post_id) AS total_posts
FROM users u
JOIN posts p ON u.user_id = p.user_id
GROUP BY u.faculty
ORDER BY total_posts DESC;

-- Consulta 2:
-- Top 10 usuarios con más seguidores
SELECT
    user_id,
    username,
    full_name,
    faculty,
    followers_count
FROM users
ORDER BY followers_count DESC, user_id ASC
LIMIT 10;

-- Consulta 3:
-- Top 10 publicaciones con más likes
SELECT
    p.post_id,
    p.user_id,
    u.username,
    p.likes_count,
    p.comments_count,
    p.created_at
FROM posts p
JOIN users u ON p.user_id = u.user_id
ORDER BY p.likes_count DESC, p.post_id ASC
LIMIT 10;

-- Consulta 4:
-- Número de interacciones por día y por tipo de evento
SELECT
    DATE(created_at) AS interaction_date,
    event_type,
    COUNT(*) AS total_interactions
FROM interaction_log
GROUP BY DATE(created_at), event_type
ORDER BY interaction_date ASC, event_type ASC;

-- Consulta 5:
-- Cantidad de comentarios por publicación
SELECT
    p.post_id,
    p.user_id,
    COUNT(c.comment_id) AS total_comments
FROM posts p
LEFT JOIN comments c ON p.post_id = c.post_id
GROUP BY p.post_id, p.user_id
ORDER BY total_comments DESC, p.post_id ASC;

-- Consulta 6:
-- Join de análisis entre comentarios, publicación y autor del comentario
-- Esta consulta es útil porque luego puede servir como base
-- para demostrar joins entre datos ubicados en diferentes shards
SELECT
    c.comment_id,
    c.post_id,
    p.user_id AS post_author_id,
    c.user_id AS comment_author_id,
    uc.username AS comment_author_username,
    p.content AS post_content,
    c.content AS comment_content,
    c.created_at AS comment_created_at
FROM comments c
JOIN posts p ON c.post_id = p.post_id
JOIN users uc ON c.user_id = uc.user_id
ORDER BY c.comment_id ASC
LIMIT 50;

-- Consulta 7:
-- Top 10 usuarios con más actividad total en el log de interacciones
SELECT
    u.user_id,
    u.username,
    COUNT(il.event_id) AS total_activity
FROM users u
JOIN interaction_log il ON u.user_id = il.user_id
GROUP BY u.user_id, u.username
ORDER BY total_activity DESC, u.user_id ASC
LIMIT 10;