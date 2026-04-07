-- Datos de prueba para CampusConnect

-- Limpieza opcional si se desea volver a ejecutar el seed
TRUNCATE TABLE interaction_log RESTART IDENTITY;
TRUNCATE TABLE follows;
TRUNCATE TABLE likes;
TRUNCATE TABLE comments;
TRUNCATE TABLE posts;
TRUNCATE TABLE users;
TRUNCATE TABLE experiment_results RESTART IDENTITY;

-- 1. USUARIOS
-- 300 usuarios distribuidos por facultades y semestres

INSERT INTO users (
    user_id,
    username,
    full_name,
    faculty,
    semester,
    followers_count,
    following_count,
    created_at
)
SELECT
    gs AS user_id,
    'user_' || gs AS username,
    'Student ' || gs AS full_name,
    CASE (gs % 5)
        WHEN 0 THEN 'Engineering'
        WHEN 1 THEN 'Business'
        WHEN 2 THEN 'Law'
        WHEN 3 THEN 'Design'
        ELSE 'Health Sciences'
    END AS faculty,
    ((gs - 1) % 10) + 1 AS semester,
    0,
    0,
    CURRENT_TIMESTAMP - ((gs % 120) || ' days')::INTERVAL
FROM generate_series(1, 300) AS gs;

-- 2. PUBLICACIONES
-- Cada usuario crea 3 publicaciones
-- Total: 900 publicaciones

INSERT INTO posts (
    post_id,
    user_id,
    content,
    visibility,
    likes_count,
    comments_count,
    created_at
)
SELECT
    ((u.user_id - 1) * 3) + p.n AS post_id,
    u.user_id,
    'Post #' || ((u.user_id - 1) * 3 + p.n) ||
    ' created by user_' || u.user_id ||
    ' about university life, study routines and social activities.' AS content,
    CASE (p.n % 3)
        WHEN 0 THEN 'public'
        WHEN 1 THEN 'friends'
        ELSE 'private'
    END AS visibility,
    0,
    0,
    u.created_at + (p.n || ' hours')::INTERVAL
FROM users u
CROSS JOIN generate_series(1, 3) AS p(n);

-- 3. COMENTARIOS
-- Cada publicación recibe 2 comentarios
-- Total: 1800 comentarios

INSERT INTO comments (
    comment_id,
    post_id,
    user_id,
    content,
    created_at
)
SELECT
    ((p.post_id - 1) * 2) + c.n AS comment_id,
    p.post_id,
    (((p.post_id + c.n) % 300) + 1) AS user_id,
    'Comment #' || (((p.post_id - 1) * 2) + c.n) ||
    ' on post #' || p.post_id ||
    ' generated for testing distributed queries.' AS content,
    p.created_at + (c.n || ' hours')::INTERVAL
FROM posts p
CROSS JOIN generate_series(1, 2) AS c(n);

-- 4. ME GUSTA
-- Cada publicación recibe 3 me gusta
-- Objetivo total: 2700 me gusta
-- Único por (post_id, user_id)

INSERT INTO likes (
    like_id,
    post_id,
    user_id,
    created_at
)
SELECT
    row_number() OVER (ORDER BY post_id, user_id) AS like_id,
    post_id,
    user_id,
    created_at
FROM (
    SELECT DISTINCT
        p.post_id,
        (((p.post_id * 2) % 300) + 1) AS user_id,
        p.created_at + INTERVAL '10 minutes' AS created_at
    FROM posts p

    UNION

    SELECT DISTINCT
        p.post_id,
        (((p.post_id * 3) % 300) + 1) AS user_id,
        p.created_at + INTERVAL '20 minutes' AS created_at
    FROM posts p

    UNION

    SELECT DISTINCT
        p.post_id,
        (((p.post_id * 5) % 300) + 1) AS user_id,
        p.created_at + INTERVAL '30 minutes' AS created_at
    FROM posts p
) AS like_source;

-- 5. SEGUIDORES
-- Cada usuario sigue a otros 2 usuarios
-- Total: 600 relaciones de seguimiento

INSERT INTO follows (
    follower_id,
    followed_id,
    created_at
)
SELECT
    u.user_id AS follower_id,
    (((u.user_id + 7 - 1) % 300) + 1) AS followed_id,
    CURRENT_TIMESTAMP - ((u.user_id % 60) || ' days')::INTERVAL
FROM users u
WHERE u.user_id <> (((u.user_id + 7 - 1) % 300) + 1)

UNION

SELECT
    u.user_id AS follower_id,
    (((u.user_id + 19 - 1) % 300) + 1) AS followed_id,
    CURRENT_TIMESTAMP - ((u.user_id % 45) || ' days')::INTERVAL
FROM users u
WHERE u.user_id <> (((u.user_id + 19 - 1) % 300) + 1);

-- 6. ACTUALIZAR CONTADORES
-- seguidores_count, siguiendo_count, likes_count, comentarios_count

UPDATE users u
SET following_count = sub.total_following
FROM (
    SELECT follower_id, COUNT(*) AS total_following
    FROM follows
    GROUP BY follower_id
) AS sub
WHERE u.user_id = sub.follower_id;

UPDATE users u
SET followers_count = sub.total_followers
FROM (
    SELECT followed_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followed_id
) AS sub
WHERE u.user_id = sub.followed_id;

UPDATE posts p
SET comments_count = sub.total_comments
FROM (
    SELECT post_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY post_id
) AS sub
WHERE p.post_id = sub.post_id;

UPDATE posts p
SET likes_count = sub.total_likes
FROM (
    SELECT post_id, COUNT(*) AS total_likes
    FROM likes
    GROUP BY post_id
) AS sub
WHERE p.post_id = sub.post_id;

-- 7. LOG DE INTERACCIONES
-- Tabla de eventos de alto volumen para análisis y experimentos de sharding

INSERT INTO interaction_log (
    event_id,
    user_id,
    post_id,
    event_type,
    source_shard,
    created_at
)
SELECT
    row_number() OVER (ORDER BY created_at, user_id) AS event_id,
    user_id,
    post_id,
    event_type,
    CASE
        WHEN user_id % 3 = 0 THEN 'shard_1'
        WHEN user_id % 3 = 1 THEN 'shard_2'
        ELSE 'shard_3'
    END AS source_shard,
    created_at
FROM (
    SELECT
        p.user_id,
        p.post_id,
        'post'::VARCHAR(20) AS event_type,
        p.created_at
    FROM posts p

    UNION ALL

    SELECT
        c.user_id,
        c.post_id,
        'comment'::VARCHAR(20) AS event_type,
        c.created_at
    FROM comments c

    UNION ALL

    SELECT
        l.user_id,
        l.post_id,
        'like'::VARCHAR(20) AS event_type,
        l.created_at
    FROM likes l

    UNION ALL

    SELECT
        f.follower_id AS user_id,
        NULL::BIGINT AS post_id,
        'follow'::VARCHAR(20) AS event_type,
        f.created_at
    FROM follows f
) AS events;

-- 8. VALIDACIÓN RÁPIDA

SELECT 'users' AS table_name, COUNT(*) AS total_rows FROM users
UNION ALL
SELECT 'posts', COUNT(*) FROM posts
UNION ALL
SELECT 'comments', COUNT(*) FROM comments
UNION ALL
SELECT 'likes', COUNT(*) FROM likes
UNION ALL
SELECT 'follows', COUNT(*) FROM follows
UNION ALL
SELECT 'interaction_log', COUNT(*) FROM interaction_log;