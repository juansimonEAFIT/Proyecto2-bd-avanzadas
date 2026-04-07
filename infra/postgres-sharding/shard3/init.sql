-- Inicialización del shard 3

CREATE EXTENSION IF NOT EXISTS dblink;
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

CREATE TABLE IF NOT EXISTS shard_metadata (
    shard_name VARCHAR(20) PRIMARY KEY,
    shard_description TEXT NOT NULL,
    routing_rule TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO shard_metadata (
    shard_name,
    shard_description,
    routing_rule
)
VALUES (
    'shard_3',
    'Nodo 3 del entorno de sharding para CampusConnect',
    'user_id % 3 = 2'
)
ON CONFLICT (shard_name) DO NOTHING;