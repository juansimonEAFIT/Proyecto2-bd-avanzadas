DROP TABLE IF EXISTS experiment_results;
DROP TABLE IF EXISTS interaction_log;
DROP TABLE IF EXISTS follows;
DROP TABLE IF EXISTS likes;
DROP TABLE IF EXISTS comments;
DROP TABLE IF EXISTS posts;
DROP TABLE IF EXISTS users;

CREATE TABLE users (
    user_id BIGINT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    faculty VARCHAR(100) NOT NULL,
    semester INT NOT NULL CHECK (semester >= 1 AND semester <= 12),
    followers_count INT NOT NULL DEFAULT 0 CHECK (followers_count >= 0),
    following_count INT NOT NULL DEFAULT 0 CHECK (following_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE posts (
    post_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    visibility VARCHAR(20) NOT NULL DEFAULT 'public'
        CHECK (visibility IN ('public', 'friends', 'private')),
    likes_count INT NOT NULL DEFAULT 0 CHECK (likes_count >= 0),
    comments_count INT NOT NULL DEFAULT 0 CHECK (comments_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE comments (
    comment_id BIGINT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE likes (
    like_id BIGINT PRIMARY KEY,
    post_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_post_like UNIQUE (post_id, user_id)
);

CREATE TABLE follows (
    follower_id BIGINT NOT NULL,
    followed_id BIGINT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (follower_id, followed_id),
    CONSTRAINT no_self_follow CHECK (follower_id <> followed_id)
);

CREATE TABLE interaction_log (
    event_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    post_id BIGINT,
    event_type VARCHAR(20) NOT NULL
        CHECK (event_type IN ('post', 'comment', 'like', 'follow', 'login')),
    source_shard VARCHAR(20) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE experiment_results (
    result_id BIGSERIAL PRIMARY KEY,
    experiment_name VARCHAR(100) NOT NULL,
    test_type VARCHAR(50) NOT NULL,
    node_name VARCHAR(50) NOT NULL,
    operation_type VARCHAR(50) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    latency_ms NUMERIC(10,2) NOT NULL CHECK (latency_ms >= 0),
    rows_affected INT NOT NULL DEFAULT 0 CHECK (rows_affected >= 0),
    success BOOLEAN NOT NULL,
    consistency_mode VARCHAR(50),
    notes TEXT
);

CREATE INDEX idx_users_faculty
    ON users (faculty);

CREATE INDEX idx_posts_user_id
    ON posts (user_id);

CREATE INDEX idx_posts_created_at
    ON posts (created_at);

CREATE INDEX idx_comments_post_id
    ON comments (post_id);

CREATE INDEX idx_comments_user_id
    ON comments (user_id);

CREATE INDEX idx_likes_post_id
    ON likes (post_id);

CREATE INDEX idx_likes_user_id
    ON likes (user_id);

CREATE INDEX idx_follows_followed_id
    ON follows (followed_id);

CREATE INDEX idx_interaction_log_user_id
    ON interaction_log (user_id);

CREATE INDEX idx_interaction_log_created_at
    ON interaction_log (created_at);

CREATE INDEX idx_interaction_log_event_type
    ON interaction_log (event_type);