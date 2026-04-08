-- BONUS: Patron SAGA en PostgreSQL para operacion larga

CREATE TABLE IF NOT EXISTS saga_instances (
    saga_id UUID PRIMARY KEY,
    saga_type VARCHAR(100) NOT NULL,
    saga_status VARCHAR(50) NOT NULL,
    step_name VARCHAR(100) NOT NULL,
    payload JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE PROCEDURE sp_saga_publish_post_with_notifications(
    p_user_id BIGINT,
    p_content TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_saga_id UUID := gen_random_uuid();
    v_post_id BIGINT;
BEGIN
    INSERT INTO saga_instances (saga_id, saga_type, saga_status, step_name, payload)
    VALUES (v_saga_id, 'PUBLISH_POST', 'STARTED', 'CREATE_POST', jsonb_build_object('user_id', p_user_id));

    INSERT INTO posts (user_id, content)
    VALUES (p_user_id, p_content)
    RETURNING post_id INTO v_post_id;

    UPDATE saga_instances
    SET step_name = 'UPDATE_COUNTERS', updated_at = CURRENT_TIMESTAMP
    WHERE saga_id = v_saga_id;

    UPDATE users
    SET post_count = post_count + 1
    WHERE user_id = p_user_id;

    UPDATE saga_instances
    SET step_name = 'SEND_NOTIFICATION', updated_at = CURRENT_TIMESTAMP
    WHERE saga_id = v_saga_id;

    -- Simulacion de un paso externo que puede fallar
    IF random() < 0.2 THEN
        RAISE EXCEPTION 'Notification service error';
    END IF;

    UPDATE saga_instances
    SET saga_status = 'COMPLETED', step_name = 'DONE', updated_at = CURRENT_TIMESTAMP
    WHERE saga_id = v_saga_id;

EXCEPTION WHEN OTHERS THEN
    -- Compensacion: deshacer cambios locales
    IF v_post_id IS NOT NULL THEN
        DELETE FROM posts WHERE post_id = v_post_id;
        UPDATE users SET post_count = GREATEST(post_count - 1, 0) WHERE user_id = p_user_id;
    END IF;

    UPDATE saga_instances
    SET saga_status = 'COMPENSATED', step_name = 'ROLLBACK_DONE', updated_at = CURRENT_TIMESTAMP
    WHERE saga_id = v_saga_id;

    RAISE NOTICE 'SAGA compensada: %', SQLERRM;
END;
$$;
