-- ============================================================================
-- SOCIAL NETWORK DATABASE - INITIAL SETUP (PostgreSQL PRIMARY)
-- ============================================================================
-- Este script inicializa la base de datos principal con tablas base
-- para la red social de redes sociales

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- TABLESPACES (opcional, para distribución física)
-- ============================================================================
-- CREATE TABLESPACE ts_shard1 LOCATION '/var/lib/postgresql/shard1';
-- CREATE TABLESPACE ts_shard2 LOCATION '/var/lib/postgresql/shard2';
-- CREATE TABLESPACE ts_shard3 LOCATION '/var/lib/postgresql/shard3';

-- ============================================================================
-- TABLE: USERS
-- ============================================================================
-- Contiene 1M+ de usuarios, particionada por hash en 3 nodos
CREATE TABLE users (
    user_id BIGSERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    full_name VARCHAR(255),
    bio TEXT,
    profile_picture_url VARCHAR(512),
    follower_count INT DEFAULT 0,
    following_count INT DEFAULT 0,
    post_count INT DEFAULT 0,
    is_verified BOOLEAN DEFAULT FALSE,
    is_private BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP
) PARTITION BY HASH (user_id);

-- Particiones para distribución horizontal
CREATE TABLE users_P1 PARTITION OF users FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE users_P2 PARTITION OF users FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE users_P3 PARTITION OF users FOR VALUES WITH (MODULUS 3, REMAINDER 2);

-- ============================================================================
-- TABLE: POSTS
-- ============================================================================
-- Contiene 100M+ de posts, particionada por rango de fecha y hash
CREATE TABLE posts (
    post_id BIGSERIAL,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    media_urls VARCHAR(512)[],
    location VARCHAR(255),
    like_count INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    share_count INT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (post_id, created_at)
) PARTITION BY RANGE (created_at);

-- Particiones por rango de fecha (diaria, pero aquí en bloques de 30 días para demo)
CREATE TABLE posts_P202601 PARTITION OF posts FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE posts_P202602 PARTITION OF posts FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE posts_P202603 PARTITION OF posts FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE posts_P202604 PARTITION OF posts FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');

-- ============================================================================
-- TABLE: COMMENTS
-- ============================================================================
-- Comentarios en posts, particionada en hash
CREATE TABLE comments (
    comment_id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    like_count INT DEFAULT 0,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) PARTITION BY HASH (comment_id);

CREATE TABLE comments_P1 PARTITION OF comments FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE comments_P2 PARTITION OF comments FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE comments_P3 PARTITION OF comments FOR VALUES WITH (MODULUS 3, REMAINDER 2);

-- ============================================================================
-- TABLE: LIKES
-- ============================================================================
-- Relación de likes en posts y comentarios
CREATE TABLE post_likes (
    like_id BIGSERIAL PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(post_id, user_id)
) PARTITION BY HASH (user_id);

CREATE TABLE post_likes_P1 PARTITION OF post_likes FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE post_likes_P2 PARTITION OF post_likes FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE post_likes_P3 PARTITION OF post_likes FOR VALUES WITH (MODULUS 3, REMAINDER 2);

-- ============================================================================
-- TABLE: FOLLOWERS
-- ============================================================================
-- Relación seguidor-seguido, particionada en hash
CREATE TABLE followers (
    follower_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    following_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, following_id)
) PARTITION BY HASH (follower_id);

CREATE TABLE followers_P1 PARTITION OF followers FOR VALUES WITH (MODULUS 3, REMAINDER 0);
CREATE TABLE followers_P2 PARTITION OF followers FOR VALUES WITH (MODULUS 3, REMAINDER 1);
CREATE TABLE followers_P3 PARTITION OF followers FOR VALUES WITH (MODULUS 3, REMAINDER 2);

-- ============================================================================
-- TABLE: TRANSACCION_LOG (para transacciones distribuidas)
-- ============================================================================
-- Registro de transacciones distribuidas para auditoría
CREATE TABLE distributed_transactions (
    tx_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    status VARCHAR(50) NOT NULL CHECK (status IN ('PREPARED', 'COMMITTED', 'ABORTED')),
    source_shard INT NOT NULL,
    target_shard INT NOT NULL,
    operation_type VARCHAR(50) NOT NULL,
    operation_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP
);

-- ============================================================================
-- INDICES
-- ============================================================================
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_created_at ON users(created_at);
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);
CREATE INDEX idx_followers_following_id ON followers(following_id);

-- ============================================================================
-- GRANT PERMISSIONS FOR REPLICATION
-- ============================================================================
CREATE USER replicator WITH REPLICATION ENCRYPTED PASSWORD 'replicator123';
GRANT CONNECT ON DATABASE social_network TO replicator;
GRANT USAGE ON SCHEMA public TO replicator;

-- Allow logical replication for 2PC
ALTER ROLE admin WITH SUPERUSER;

