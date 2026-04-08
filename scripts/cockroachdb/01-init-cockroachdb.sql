-- ============================================================================
-- SOCIAL NETWORK DATABASE - COCKROACHDB SETUP
-- ============================================================================
-- CockroachDB maneja automáticamente: sharding, replicación, transacciones distribuidas
-- Este script crea la estructura de la tabla para redes sociales

-- ============================================================================
-- TABLA: USERS (Auto-sharded by primary key)
-- ============================================================================
CREATE TABLE IF NOT EXISTS users (
    user_id INT64 PRIMARY KEY,
    username VARCHAR NOT NULL,
    email VARCHAR NOT NULL,
    full_name VARCHAR,
    bio TEXT,
    profile_picture_url VARCHAR,
    follower_count INT64 DEFAULT 0,
    following_count INT64 DEFAULT 0,
    post_count INT64 DEFAULT 0,
    is_verified BOOL DEFAULT FALSE,
    is_private BOOL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    last_login TIMESTAMPTZ,
    UNIQUE INDEX idx_users_username (username),
    UNIQUE INDEX idx_users_email (email)
);

-- ============================================================================
-- TABLA: POSTS (Auto-sharded, primaria por post_id)
-- ============================================================================
CREATE TABLE IF NOT EXISTS posts (
    post_id INT64 PRIMARY KEY,
    user_id INT64 NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_urls STRING[],
    location VARCHAR,
    like_count INT64 DEFAULT 0,
    comment_count INT64 DEFAULT 0,
    share_count INT64 DEFAULT 0,
    is_deleted BOOL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    INDEX idx_posts_user_id (user_id),
    INDEX idx_posts_created_at (created_at DESC)
);

-- ============================================================================
-- TABLA: COMMENTS
-- ============================================================================
CREATE TABLE IF NOT EXISTS comments (
    comment_id INT64 PRIMARY KEY,
    post_id INT64 NOT NULL,
    user_id INT64 NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    like_count INT64 DEFAULT 0,
    is_deleted BOOL DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT now(),
    updated_at TIMESTAMPTZ DEFAULT now(),
    INDEX idx_comments_post_id (post_id),
    INDEX idx_comments_user_id (user_id)
);

-- ============================================================================
-- TABLA: POST_LIKES
-- ============================================================================
CREATE TABLE IF NOT EXISTS post_likes (
    like_id INT64 PRIMARY KEY,
    post_id INT64 NOT NULL,
    user_id INT64 NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    UNIQUE INDEX idx_post_likes_unique (post_id, user_id),
    INDEX idx_post_likes_post_id (post_id),
    INDEX idx_post_likes_user_id (user_id)
);

-- ============================================================================
-- TABLA: FOLLOWERS
-- ============================================================================
CREATE TABLE IF NOT EXISTS followers (
    follower_id INT64 NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    following_id INT64 NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT now(),
    PRIMARY KEY (follower_id, following_id),
    INDEX idx_followers_following_id (following_id)
);

-- ============================================================================
-- TABLA: DISTRIBUTED_TRANSACTIONS (para auditar transacciones)
-- ============================================================================
CREATE TABLE IF NOT EXISTS distributed_transactions (
    tx_id UUID PRIMARY KEY,
    status VARCHAR NOT NULL CHECK (status IN ('PREPARED', 'COMMITTED', 'ABORTED')),
    source_shard INT64 NOT NULL,
    target_shard INT64 NOT NULL,
    operation_type VARCHAR NOT NULL,
    operation_data JSONB,
    created_at TIMESTAMPTZ DEFAULT now(),
    completed_at TIMESTAMPTZ,
    INDEX idx_dtx_status (status),
    INDEX idx_dtx_created_at (created_at DESC)
);

-- ============================================================================
-- ZONE CONFIGURATION (para simular geo-distribución)
-- ============================================================================
-- CockroachDB permite configurar zonas para diferentes regiones

-- ALTER TABLE users CONFIGURE ZONE USING num_replicas = 3, constraints = '[+region=us-west]';
-- ALTER TABLE posts CONFIGURE ZONE USING num_replicas = 3, constraints = '[+region=us-west]';
-- ALTER TABLE followers CONFIGURE ZONE USING num_replicas = 3, constraints = '[+region=us-west]';

-- ============================================================================
-- INFORMACIÓN DE SHARDS EN COCKROACHDB
-- ============================================================================
-- CockroachDB distribuye automáticamente los datos en rangos (ranges)
-- Ver información de distribución:

-- SELECT 
--     table_name,
--     range_count,
--     ROUND(size_bytes / 1024.0 / 1024.0, 2) AS size_mb
-- FROM crdb_internal.table_spans
-- WHERE table_name IN ('users', 'posts', 'comments', 'followers');

-- Ver configuración de zonas
-- SELECT * FROM crdb_internal.zones;

