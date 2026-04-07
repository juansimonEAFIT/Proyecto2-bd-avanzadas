-- Archivo guía para simular una transacción distribuida con 2PC
-- Caso de prueba: el usuario 10 sigue al usuario 12

-- Regla de enrutamiento usada en el proyecto:
-- user_id % 3 = 0 -> shard_1
-- user_id % 3 = 1 -> shard_2
-- user_id % 3 = 2 -> shard_3

-- Con esa regla:
-- usuario 10 -> shard_2
-- usuario 12 -> shard_1

-- Esta operación distribuida afecta dos nodos:
-- 1. En shard_2 se inserta la relación en follows y se incrementa following_count del usuario 10
-- 2. En shard_1 se incrementa followers_count del usuario 12

-- Importante:
-- Este archivo no está pensado para ejecutarse completo de una sola vez.
-- Se debe ejecutar por bloques, conectándose manualmente a cada shard.
-- Más adelante también será necesario habilitar prepared transactions en PostgreSQL.

-- Paso 1
-- Ejecutar en shard_2
BEGIN;

INSERT INTO follows (
    follower_id,
    followed_id,
    created_at
)
VALUES (
    10,
    12,
    CURRENT_TIMESTAMP
);

UPDATE users
SET following_count = following_count + 1
WHERE user_id = 10;

PREPARE TRANSACTION 'tx_follow_10_12_shard2';

-- Paso 2
-- Ejecutar en shard_1
BEGIN;

UPDATE users
SET followers_count = followers_count + 1
WHERE user_id = 12;

PREPARE TRANSACTION 'tx_follow_10_12_shard1';

-- Paso 3
-- Verificar en cada nodo que la transacción quedó preparada
SELECT
    gid,
    prepared,
    owner,
    database
FROM pg_prepared_xacts;

-- Paso 4A
-- Si ambos nodos prepararon correctamente, confirmar la transacción
-- Ejecutar estas sentencias manualmente en sus respectivos nodos

-- En shard_2
-- COMMIT PREPARED 'tx_follow_10_12_shard2';

-- En shard_1
-- COMMIT PREPARED 'tx_follow_10_12_shard1';

-- Paso 4B
-- Si alguno de los nodos falla antes del commit final, cancelar la transacción
-- Ejecutar estas sentencias manualmente en sus respectivos nodos

-- En shard_2
-- ROLLBACK PREPARED 'tx_follow_10_12_shard2';

-- En shard_1
-- ROLLBACK PREPARED 'tx_follow_10_12_shard1';

-- Paso 5
-- Consultas de validación para revisar el resultado final
-- Ejecutar después del COMMIT PREPARED o del ROLLBACK PREPARED

-- Verificar relación follow en shard_2
SELECT
    follower_id,
    followed_id,
    created_at
FROM follows
WHERE follower_id = 10
  AND followed_id = 12;

-- Verificar contador following del usuario 10 en shard_2
SELECT
    user_id,
    username,
    following_count
FROM users
WHERE user_id = 10;

-- Verificar contador followers del usuario 12 en shard_1
SELECT
    user_id,
    username,
    followers_count
FROM users
WHERE user_id = 12;

-- Paso 6
-- Consulta opcional para limpiar el caso de prueba y poder repetirlo después
-- Estas sentencias no deben ejecutarse inmediatamente.
-- Déjalas solo como apoyo para repetir el experimento más adelante.

-- En shard_2
-- DELETE FROM follows
-- WHERE follower_id = 10
--   AND followed_id = 12;

-- UPDATE users
-- SET following_count = following_count - 1
-- WHERE user_id = 10
--   AND following_count > 0;

-- En shard_1
-- UPDATE users
-- SET followers_count = followers_count - 1
-- WHERE user_id = 12
--   AND followers_count > 0;