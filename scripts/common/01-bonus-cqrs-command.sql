CREATE TABLE IF NOT EXISTS posts_command (
    post_id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS event_outbox (
    event_id BIGSERIAL PRIMARY KEY,
    event_type VARCHAR(100) NOT NULL,
    aggregate_id BIGINT NOT NULL,
    payload JSONB NOT NULL,
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE sp_cqrs_create_post(
    p_user_id BIGINT,
    p_content TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_post_id BIGINT;
BEGIN
    INSERT INTO posts_command (user_id, content)
    VALUES (p_user_id, p_content)
    RETURNING post_id INTO v_post_id;

    INSERT INTO event_outbox (event_type, aggregate_id, payload)
    VALUES (
        'POST_CREATED',
        v_post_id,
        jsonb_build_object(
            'post_id', v_post_id,
            'user_id', p_user_id,
            'content', p_content,
            'created_at', CURRENT_TIMESTAMP
        )
    );
END;
$$;
