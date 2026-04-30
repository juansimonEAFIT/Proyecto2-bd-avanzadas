-- BONUS: Replicacion asincronica y medicion de latencia en PostgreSQL

-- 1) Ver modo actual
SHOW synchronous_commit;

-- 2) Cambiar a asincronico para la sesion actual
SET synchronous_commit = 'off';

-- 3) Carga de escritura para comparar tiempos
CREATE OR REPLACE PROCEDURE sp_async_write_benchmark(p_iterations INT DEFAULT 1000)
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT;
    v_start TIMESTAMP;
    v_elapsed_ms NUMERIC;
BEGIN
    v_start := clock_timestamp();

    FOR v_i IN 1..p_iterations LOOP
        INSERT INTO users (username, email, full_name)
        VALUES (
            'async_user_' || v_i || '_' || substring(gen_random_uuid()::TEXT, 1, 6),
            'async_' || v_i || '@example.com',
            'Async User ' || v_i
        );
    END LOOP;

    v_elapsed_ms := EXTRACT(EPOCH FROM (clock_timestamp() - v_start)) * 1000;
    RAISE NOTICE 'ASYNC: % iteraciones en % ms', p_iterations, v_elapsed_ms;
END;
$$;

-- 4) Volver a sincrono para la sesion
-- SET synchronous_commit = 'on';
