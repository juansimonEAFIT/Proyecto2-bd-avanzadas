-- ============================================================================
-- GENERACIÓN DE DATOS (ESCALA EXPERIMENTOS)
-- ============================================================================

INSERT INTO users (user_id, username, email, full_name, bio, follower_count, following_count, post_count)
SELECT 
    row_number() OVER () as user_id,
    'user_' || row_number() OVER () || '_' || gen_random_uuid() as username,
    'user_' || row_number() OVER () || '_' || gen_random_uuid() || '@example.com' as email,
    'User ' || row_number() OVER () as full_name,
    'Bio for user ' || row_number() OVER () as bio,
    floor(random() * 1000)::bigint as follower_count,
    floor(random() * 500)::bigint as following_count,
    floor(random() * 100)::bigint as post_count
FROM generate_series(1, 10000);

INSERT INTO posts (post_id, user_id, content, location, created_at)
SELECT 
    row_number() OVER () as post_id,
    (floor(random() * 10000)::bigint + 1) as user_id,
    'Post content #' || row_number() OVER () || ' with some hashtags #social' as content,
    CASE 
        WHEN random() > 0.6 THEN 'Bogotá, Colombia' 
        WHEN random() > 0.3 THEN 'Medellín, Colombia'
        ELSE 'Cali, Colombia' 
    END as location,
    now() - (random() * INTERVAL '390 days')::interval as created_at
FROM generate_series(1, 50000);

INSERT INTO comments (comment_id, post_id, user_id, content, created_at)
SELECT 
    row_number() OVER () as comment_id,
    (floor(random() * 50000)::bigint + 1) as post_id,
    (floor(random() * 10000)::bigint + 1) as user_id,
    'Great post! #awesome #love' as content,
    now() - (random() * INTERVAL '120 days')::interval as created_at
FROM generate_series(1, 100000);

-- Followers con deduplicación
WITH candidate_follows AS (
    SELECT
        (floor(random() * 10000)::bigint + 1) AS follower_id,
        (floor(random() * 10000)::bigint + 1) AS following_id,
        now() - (random() * INTERVAL '210 days')::interval AS created_at
    FROM generate_series(1, 150000)
),
ranked_follows AS (
    SELECT follower_id, following_id, created_at,
           ROW_NUMBER() OVER (PARTITION BY follower_id, following_id ORDER BY created_at DESC) AS rn
    FROM candidate_follows
    WHERE follower_id != following_id
)
INSERT INTO followers (follower_id, following_id, created_at)
SELECT follower_id, following_id, created_at FROM ranked_follows WHERE rn = 1
LIMIT 100000;

-- Likes con deduplicación
WITH candidate_likes AS (
    SELECT
        (floor(random() * 50000)::bigint + 1) AS post_id,
        (floor(random() * 10000)::bigint + 1) AS user_id,
        now() - (random() * INTERVAL '120 days')::interval AS created_at
    FROM generate_series(1, 300000)
),
ranked_likes AS (
    SELECT post_id, user_id, created_at,
           ROW_NUMBER() OVER (PARTITION BY post_id, user_id ORDER BY created_at DESC) AS rn
    FROM candidate_likes
)
INSERT INTO post_likes (like_id, post_id, user_id, created_at)
SELECT ROW_NUMBER() OVER () as like_id, post_id, user_id, created_at
FROM ranked_likes WHERE rn = 1
LIMIT 200000;
