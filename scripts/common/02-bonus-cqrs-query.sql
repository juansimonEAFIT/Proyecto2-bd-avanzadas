CREATE TABLE IF NOT EXISTS posts_read_model (
    post_id BIGINT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL,
    indexed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_posts_read_user_id ON posts_read_model(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_read_created_at ON posts_read_model(created_at DESC);
