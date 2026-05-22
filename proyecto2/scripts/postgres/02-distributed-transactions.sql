-- ============================================================================
-- TRANSACCIONES DISTRIBUIDAS - 2PC (Two-Phase Commit)
-- ============================================================================
-- Scripts para demostrar transacciones distribuidas entre shards
-- Simula: transferencia de fondos, seguidor en diferentes particiones, etc.

-- ============================================================================
-- ESCENARIO 1: Transferencia de créditos entre usuarios en diferentes shards
-- ============================================================================
-- Esta es una operación que afecta dos nodos diferentes

-- Paso 1: Conectarse al nodo primario y preparar la transacción
-- BEGIN;

-- -- Fase 1: PREPARE TRANSACTION
-- -- En el nodo 1 (User A: user_id = 1, hash mod 3 = 1 -> Shard 1)
-- UPDATE users SET follower_count = follower_count + 1 
-- WHERE user_id = 1;

-- PREPARE TRANSACTION 'tx_follow_201';

-- Paso 2: Conectarse al segundo nodo y preparar
-- (Simular en postgres-replica-1 o postgres-replica-2 conectándose como si fuera otro nodo)
-- En el nodo 2 (User B: user_id = 2, hash mod 3 = 2 -> Shard 2)
-- UPDATE users SET following_count = following_count + 1 
-- WHERE user_id = 2;
-- 
-- PREPARE TRANSACTION 'tx_follow_202';

-- Paso 3: Commit Prepared (desde el coordinador)
-- COMMIT PREPARED 'tx_follow_201';
-- COMMIT PREPARED 'tx_follow_202';

-- Si algo falla, ROLLBACK PREPARED:
-- ROLLBACK PREPARED 'tx_follow_201';

-- ============================================================================
-- ESCENARIO 2: Crear un seguidor en diferentes particiones
-- ============================================================================
-- Un usuario (shard 1) sigue a otro usuario (shard 2)

-- Simulate distributed transaction for adding a follow relationship
-- PREPARE TRANSACTION 'tx_new_follow_1';
-- -- En nodo 2:
-- PREPARE TRANSACTION 'tx_new_follow_2';
-- COMMIT PREPARED 'tx_new_follow_1';
-- COMMIT PREPARED 'tx_new_follow_2';

-- ============================================================================
-- ESCENARIO 3: Insertar Post + Like + Comentario (transacción multi-shard)
-- ============================================================================

-- Vista de transacciones en preparación
CREATE OR REPLACE VIEW v_prepared_transactions AS
SELECT * FROM pg_prepared_xacts;

-- Monitor para transacciones largas
CREATE OR REPLACE VIEW v_transaction_locks AS
SELECT
    a.pid,
    a.xact_start,
    EXTRACT(EPOCH FROM (NOW() - a.xact_start)) AS tx_age_seconds,
    l.locktype,
    l.database,
    l.relation,
    a.usename,
    a.query,
    a.query_start
FROM pg_catalog.pg_stat_activity a
JOIN pg_catalog.pg_locks l ON a.pid = l.pid
WHERE a.xact_start IS NOT NULL
ORDER BY a.xact_start DESC;

-- ============================================================================
-- PROCEDURE: Simular 2PC para seguidor en diferentes nodos
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_distributed_follow_2pc(
    p_follower_id BIGINT,
    p_following_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tx_id UUID;
    v_follower_shard INT;
    v_following_shard INT;
BEGIN
    v_tx_id := gen_random_uuid();
    v_follower_shard := p_follower_id % 3;
    v_following_shard := p_following_id % 3;

    INSERT INTO distributed_transactions (
        tx_id,
        status,
        source_shard,
        target_shard,
        operation_type,
        operation_data
    )
    VALUES (
        v_tx_id,
        'PREPARED',
        v_follower_shard,
        v_following_shard,
        'ADD_FOLLOW',
        jsonb_build_object(
            'follower_id', p_follower_id,
            'following_id', p_following_id
        )
    );

    BEGIN
        INSERT INTO followers (follower_id, following_id)
        VALUES (p_follower_id, p_following_id);

        UPDATE distributed_transactions
        SET status = 'COMMITTED',
            completed_at = CURRENT_TIMESTAMP
        WHERE tx_id = v_tx_id;

        RAISE NOTICE 'Follow relationship created successfully for TX: %', v_tx_id;

    EXCEPTION WHEN OTHERS THEN
        UPDATE distributed_transactions
        SET status = 'ABORTED',
            completed_at = CURRENT_TIMESTAMP
        WHERE tx_id = v_tx_id;

        RAISE EXCEPTION 'Distributed transaction failed: %', SQLERRM;
    END;
END;
$$;

-- ============================================================================
-- PROCEDURE: Simular transacción de actualizador de contadores (like count)
-- ============================================================================

CREATE OR REPLACE PROCEDURE sp_add_like_distributed(
    p_post_id BIGINT,
    p_user_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Fase 1: Inserta like
    INSERT INTO post_likes (post_id, user_id) 
    VALUES (p_post_id, p_user_id)
    ON CONFLICT (post_id, user_id) DO NOTHING;
    
    -- Fase 2: Actualiza contador (puede estar en otro shard)
    UPDATE posts 
    SET like_count = like_count + 1
    WHERE post_id = p_post_id;
    
    COMMIT;

EXCEPTION WHEN OTHERS THEN
    ROLLBACK;
    RAISE EXCEPTION 'Like operation failed: %', SQLERRM;
END;
$$;

