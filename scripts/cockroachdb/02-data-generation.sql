-- ============================================================================
-- GENERACIÓN DE DATOS PARA COCKROACHDB
-- ============================================================================

-- ============================================================================
-- FUNCIÓN: Generar datos sintéticos de usuarios
-- ============================================================================
-- CockroachDB usa SERIAL para generar IDs automáticamente

INSERT INTO users (user_id, username, email, full_name, bio, follower_count, following_count, post_count)
SELECT 
    row_number() OVER () as user_id,
    'user_' || row_number() OVER () || '_' || substr(gen_random_uuid()::text, 1, 8) as username,
    'user_' || row_number() OVER () || '_' || substr(gen_random_uuid()::text, 1, 8) || '@example.com' as email,
    'User ' || row_number() OVER () as full_name,
    'Bio for user ' || row_number() OVER () as bio,
    floor(random() * 100000)::int64 as follower_count,
    floor(random() * 50000)::int64 as following_count,
    floor(random() * 10000)::int64 as post_count
FROM generate_series(1, 10000);

-- Insertar posts
INSERT INTO posts (post_id, user_id, content, location, created_at)
SELECT 
    row_number() OVER () as post_id,
    floor(random() * 10000)::int64 as user_id,
    'Post content #' || row_number() OVER () || ' with some hashtags #social #network #distributed' as content,
    CASE 
        WHEN random() > 0.6 THEN 'Bogotá, Colombia' 
        WHEN random() > 0.3 THEN 'Medellín, Colombia'
        ELSE 'Cali, Colombia' 
    END as location,
    now() - (random() * INTERVAL '90 days')::interval as created_at
FROM generate_series(1, 50000);

-- Insertar comentarios
INSERT INTO comments (comment_id, post_id, user_id, content, created_at)
SELECT 
    row_number() OVER () as comment_id,
    (floor(random() * 50000)::int64 + 1) as post_id,
    (floor(random() * 10000)::int64 + 1) as user_id,
    'Great post! #awesome #love' as content,
    now() - (random() * INTERVAL '30 days')::interval as created_at
FROM generate_series(1, 30000);

-- Insertar followers
INSERT INTO followers (follower_id, following_id, created_at)
SELECT 
    (floor(random() * 10000)::int64 + 1) as follower_id,
    (floor(random() * 10000)::int64 + 1) as following_id,
    now() - (random() * INTERVAL '60 days')::interval as created_at
FROM generate_series(1, 20000)
WHERE (floor(random() * 10000)::int64 + 1) != (floor(random() * 10000)::int64 + 1);

-- Insertar post_likes
INSERT INTO post_likes (like_id, post_id, user_id, created_at)
SELECT 
    row_number() OVER () as like_id,
    (floor(random() * 50000)::int64 + 1) as post_id,
    (floor(random() * 10000)::int64 + 1) as user_id,
    now() - (random() * INTERVAL '30 days')::interval as created_at
FROM generate_series(1, 100000);

