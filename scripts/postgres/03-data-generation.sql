-- ============================================================================
-- SCRIPT PARA CARGAR DATOS SINTÉTICOS Y PRUEBAS
-- ============================================================================
-- Este script genera datos de prueba para los experimentos

-- ============================================================================
-- FUNCIÓN: Generar datos sintéticos de usuarios
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_generate_users(p_count INT DEFAULT 10000)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT := 0;
    v_start TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    FOR v_i IN 1..p_count LOOP
        INSERT INTO users (username, email, full_name, bio, follower_count, following_count, post_count)
        VALUES (
            'user_' || v_i || '_' || SUBSTRING(gen_random_uuid()::TEXT, 1, 8),
            'user_' || v_i || '_' || SUBSTRING(gen_random_uuid()::TEXT, 1, 8) || '@example.com',
            'User ' || v_i,
            'Bio for user ' || v_i,
            (RANDOM() * 100000)::INT,
            (RANDOM() * 50000)::INT,
            (RANDOM() * 10000)::INT
        );
        
        IF MOD(v_i, 1000) = 0 THEN
            RAISE NOTICE 'Generated % users...', v_i;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Total time: % ms', EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start)) * 1000;
END;
$$;

-- ============================================================================
-- FUNCIÓN: Generar datos sintéticos de posts
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_generate_posts(p_count INT DEFAULT 50000)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT := 0;
    v_random_user_id BIGINT;
    v_start TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    FOR v_i IN 1..p_count LOOP
        -- Selecciona un usuario aleatorio
        SELECT user_id INTO v_random_user_id FROM users ORDER BY RANDOM() LIMIT 1;
        
        IF v_random_user_id IS NOT NULL THEN
            INSERT INTO posts (user_id, content, location, created_at)
            VALUES (
                v_random_user_id,
                'Post content #' || v_i || ' with some hashtags #social #network #distributed',
                CASE WHEN RANDOM() > 0.5 THEN 'Bogotá, Colombia' 
                     WHEN RANDOM() > 0.5 THEN 'Medellín, Colombia'
                     ELSE 'Cali, Colombia' END,
                CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '90 days')
            );
        END IF;
        
        IF MOD(v_i, 5000) = 0 THEN
            RAISE NOTICE 'Generated % posts...', v_i;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Total time: % ms', EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start)) * 1000;
END;
$$;

-- ============================================================================
-- FUNCIÓN: Generar datos sintéticos de comentarios
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_generate_comments(p_count INT DEFAULT 30000)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT := 0;
    v_random_post_id BIGINT;
    v_random_user_id BIGINT;
    v_start TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    FOR v_i IN 1..p_count LOOP
        SELECT post_id INTO v_random_post_id FROM posts ORDER BY RANDOM() LIMIT 1;
        SELECT user_id INTO v_random_user_id FROM users ORDER BY RANDOM() LIMIT 1;
        
        IF v_random_post_id IS NOT NULL AND v_random_user_id IS NOT NULL THEN
            INSERT INTO comments (post_id, user_id, content, created_at)
            VALUES (
                v_random_post_id,
                v_random_user_id,
                'Great post! #awesome #love',
                CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '30 days')
            );
        END IF;
        
        IF MOD(v_i, 5000) = 0 THEN
            RAISE NOTICE 'Generated % comments...', v_i;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Total time: % ms', EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start)) * 1000;
END;
$$;

-- ============================================================================
-- FUNCIÓN: Generar datos sintéticos de followers
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_generate_followers(p_count INT DEFAULT 20000)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT := 0;
    v_follower_id BIGINT;
    v_following_id BIGINT;
    v_start TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    FOR v_i IN 1..p_count LOOP
        SELECT user_id INTO v_follower_id FROM users ORDER BY RANDOM() LIMIT 1;
        SELECT user_id INTO v_following_id FROM users ORDER BY RANDOM() LIMIT 1;
        
        -- Evita que alguien se siga a sí mismo
        IF v_follower_id != v_following_id THEN
            INSERT INTO followers (follower_id, following_id, created_at)
            VALUES (v_follower_id, v_following_id, CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '60 days'))
            ON CONFLICT (follower_id, following_id) DO NOTHING;
        END IF;
        
        IF MOD(v_i, 5000) = 0 THEN
            RAISE NOTICE 'Generated % follower relationships...', v_i;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Total time: % ms', EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start)) * 1000;
END;
$$;

-- ============================================================================
-- FUNCIÓN: Generar datos sintéticos de likes
-- ============================================================================
CREATE OR REPLACE FUNCTION fn_generate_post_likes(p_count INT DEFAULT 100000)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT := 0;
    v_post_id BIGINT;
    v_user_id BIGINT;
    v_start TIMESTAMP := CURRENT_TIMESTAMP;
BEGIN
    FOR v_i IN 1..p_count LOOP
        SELECT post_id INTO v_post_id FROM posts ORDER BY RANDOM() LIMIT 1;
        SELECT user_id INTO v_user_id FROM users ORDER BY RANDOM() LIMIT 1;
        
        IF v_post_id IS NOT NULL AND v_user_id IS NOT NULL THEN
            INSERT INTO post_likes (post_id, user_id, created_at)
            VALUES (v_post_id, v_user_id, CURRENT_TIMESTAMP - (RANDOM() * INTERVAL '30 days'))
            ON CONFLICT (post_id, user_id) DO NOTHING;
        END IF;
        
        IF MOD(v_i, 10000) = 0 THEN
            RAISE NOTICE 'Generated % post likes...', v_i;
        END IF;
    END LOOP;
    
    RAISE NOTICE 'Total time: % ms', EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - v_start)) * 1000;
END;
$$;

-- ============================================================================
-- LLAMADAS PARA GENERAR DATOS (ejecutar según sea necesario)
-- ============================================================================

-- SELECT fn_generate_users(10000);
-- SELECT fn_generate_posts(50000);
-- SELECT fn_generate_comments(30000);
-- SELECT fn_generate_followers(20000);
-- SELECT fn_generate_post_likes(100000);

