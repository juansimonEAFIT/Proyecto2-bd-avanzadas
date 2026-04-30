-- ============================================================================
-- BONUS: Replicacion asincronica y comparacion sync vs async en PostgreSQL
-- ============================================================================
-- Este script deja el escenario listo para:
-- 1. medir latencia de escritura con synchronous_commit = on/off
-- 2. inspeccionar el estado de las replicas
-- 3. verificar propagacion de inserts hacia replicas

CREATE OR REPLACE VIEW v_replication_overview AS
SELECT
    application_name,
    client_addr,
    state,
    sync_state,
    COALESCE(write_lag, INTERVAL '0 seconds') AS write_lag,
    COALESCE(flush_lag, INTERVAL '0 seconds') AS flush_lag,
    COALESCE(replay_lag, INTERVAL '0 seconds') AS replay_lag
FROM pg_stat_replication
ORDER BY application_name;

CREATE TABLE IF NOT EXISTS async_replication_benchmarks (
    benchmark_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    commit_mode TEXT NOT NULL CHECK (commit_mode IN ('on', 'off', 'local', 'remote_write', 'remote_apply')),
    iterations INT NOT NULL CHECK (iterations > 0),
    inserted_rows INT NOT NULL,
    elapsed_ms NUMERIC(12, 3) NOT NULL,
    rows_visible_primary BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION fn_benchmark_commit_mode(
    p_commit_mode TEXT,
    p_iterations INT DEFAULT 500,
    p_prefix TEXT DEFAULT NULL
)
RETURNS TABLE (
    commit_mode TEXT,
    iterations INT,
    inserted_rows INT,
    elapsed_ms NUMERIC,
    rows_visible_primary BIGINT,
    benchmark_prefix TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_i INT;
    v_start TIMESTAMP;
    v_elapsed_ms NUMERIC(12, 3);
    v_inserted_rows INT := 0;
    v_rows_visible BIGINT;
    v_prefix TEXT;
BEGIN
    IF p_commit_mode NOT IN ('on', 'off', 'local', 'remote_write', 'remote_apply') THEN
        RAISE EXCEPTION 'Modo synchronous_commit no soportado: %', p_commit_mode;
    END IF;

    v_prefix := COALESCE(
        p_prefix,
        'async_bench_' || replace(clock_timestamp()::TEXT, ' ', '_')
    );

    EXECUTE format('SET synchronous_commit = %L', p_commit_mode);
    v_start := clock_timestamp();

    FOR v_i IN 1..p_iterations LOOP
        INSERT INTO users (username, email, full_name, bio)
        VALUES (
            format('%s_%s_%s', v_prefix, p_commit_mode, v_i),
            format('%s_%s_%s@example.com', v_prefix, p_commit_mode, v_i),
            format('Benchmark %s %s', upper(p_commit_mode), v_i),
            'Benchmark para comparar replicacion sincronica vs asincronica'
        );
        v_inserted_rows := v_inserted_rows + 1;
    END LOOP;

    v_elapsed_ms := EXTRACT(EPOCH FROM (clock_timestamp() - v_start)) * 1000;

    SELECT COUNT(*)
    INTO v_rows_visible
    FROM users
    WHERE username LIKE v_prefix || '_' || p_commit_mode || '_%';

    INSERT INTO async_replication_benchmarks (
        commit_mode,
        iterations,
        inserted_rows,
        elapsed_ms,
        rows_visible_primary
    )
    VALUES (
        p_commit_mode,
        p_iterations,
        v_inserted_rows,
        v_elapsed_ms,
        v_rows_visible
    );

    RETURN QUERY
    SELECT
        p_commit_mode,
        p_iterations,
        v_inserted_rows,
        v_elapsed_ms,
        v_rows_visible,
        v_prefix;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_async_write_benchmark(p_iterations INT DEFAULT 1000)
LANGUAGE plpgsql
AS $$
DECLARE
    v_result RECORD;
BEGIN
    SELECT *
    INTO v_result
    FROM fn_benchmark_commit_mode('off', p_iterations, 'async_proc');

    RAISE NOTICE 'ASYNC: % iteraciones en % ms (prefijo=%)',
        v_result.inserted_rows,
        v_result.elapsed_ms,
        v_result.benchmark_prefix;
END;
$$;

-- Estado actual de las replicas.
-- SELECT * FROM v_replication_overview;

-- Benchmark sincrono.
-- SELECT * FROM fn_benchmark_commit_mode('on', 300, 'manual_sync');

-- Benchmark asincrono.
-- SELECT * FROM fn_benchmark_commit_mode('off', 300, 'manual_async');

-- Ultimos benchmarks guardados.
-- SELECT * FROM async_replication_benchmarks ORDER BY created_at DESC LIMIT 10;
