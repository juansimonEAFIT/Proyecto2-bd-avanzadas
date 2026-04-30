-- ============================================================================
-- GENERACIÓN DE DATOS PARA COCKROACHDB - BIG DATA (20M REGISTROS)
-- ============================================================================
-- Escala: 100K usuarios, 5M posts, 3M comentarios, 2M followers, 10M likes

-- ============================================================================
-- INSERTAR 100,000 USUARIOS
-- ============================================================================
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
FROM generate_series(1, 100000);

-- ============================================================================
-- INSERTAR 5,000,000 POSTS (50x escala original)
-- ============================================================================
INSERT INTO posts (post_id, user_id, content, location, created_at)
SELECT 
    row_number() OVER () as post_id,
    (floor(random() * 100000)::int64 + 1) as user_id,
    'Post content #' || row_number() OVER () || ' with some hashtags #social #network #distributed #bigdata' as content,
    CASE 
        WHEN random() > 0.6 THEN 'Bogotá, Colombia' 
        WHEN random() > 0.3 THEN 'Medellín, Colombia'
        ELSE 'Cali, Colombia' 
    END as location,
    now() - (random() * INTERVAL '390 days')::interval as created_at
FRO============================================================================
-- INSERTAR 3,000,000 COMENTARIOS (100x escala original)
-- ============================================================================
INSERT INTO comments (comment_id, post_id, user_id, content, created_at)
SELECT 
    row_number() OVER () as comment_id,
    (floor(random() * 5000000)::int64 + 1) as post_id,
    (floor(random() * 100000)::int64 + 1) as user_id,
    'Great post! #awesome #love' as content,
    now() - (random() * INTERVAL '120 days')::interval as created_at
FROM generate_series(1, 300 #love' as content,
    now() - (random() * INTERVAL '30 days')::interval as created_at
FROM generate_series(1, 30000);

-- ============================================================================
-- INSERTAR 2,000,000 FOLLOWERS (100x escala original, con deduplicación)
-- ============================================================================
WITH candidate_follows AS (
    SELECT
        (floor(random() * 100000)::int64 + 1) AS follower_id,
        (floor(random() * 100000)::int64 + 1) AS following_id,
        now() - (random() * INTERVAL '210 days')::interval AS created_at
    FROM generate_series(1, 6000000)
),
ranked_follows AS (
    SELECT
        follower_id,
        following_id,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY follower_id, following_id
            ORDER BY created_at DESC
        ) AS rn
    FROM candidate_follows
    WHERE follower_id != following_id
)
INSERT INTO followers (follower_id, following_id, created_at)
SELECT follower_id, following_id, created_at
FROM ranked_follows
WHERE rn = 1
LIMIT 2000000;

-- ============================================================================
-- INSERTAR 10,000,000 POST_LIKES (100x escala original, con deduplicación)
-- ============================================================================
WITH candidate_likes AS (
    SELECT
        (floor(random() * 5000000)::int64 + 1) AS post_id,
        (floor(random() * 100000)::int64 + 1) AS user_id,
        now() - (random() * INTERVAL '120 days')::interval AS created_at
    FROM generate_series(1, 22000000)
),
ranked_likes AS (
    SELECT
        post_id,
        user_id,
        created_at,
        ROW_NUMBER() OVER (
            PARTITION BY post_id, user_id
            ORDER BY created_at DESC
        ) AS rn
    FROM candidate_likes
)
INSERT INTO post_likes (like_id, post_id, user_id, created_at)
SELECT
    ROW_NUMBER() OVER () AS like_id,
    post_id,
    user_id,
    created_at
FROM ranked_likes
WHERE rn = 1
LIMIT 10000000;

