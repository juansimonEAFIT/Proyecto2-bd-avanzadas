# Resultados - Experimentos PostgreSQL (Integrante 3)

Este documento consolida el estado de los experimentos del integrante 3. Los scripts generan su salida en `docs/results/` y el consolidado final se guarda en `docs/results/postgres_summary.json`.

## 1. Experimentos implementados

- `experiments/exp1_latency_intra_shard.py`
- `experiments/exp3_replication_sync.py`
- `experiments/exp4_distributed_transactions.py`
- `experiments/exp5_failover_recovery.py`
- `experiments/analyze_postgres_results.py`

## 2. Objetivo de cada experimento

### 2.1 Latencia intra-shard

Medir lecturas y escrituras sobre una misma particion de `users` para obtener una linea base de rendimiento local.

### 2.2 Replicacion sync vs async

Comparar `synchronous_commit = on` y `off` usando el benchmark definido en `scripts/postgres/05-bonus-async-replication.sql`.

### 2.3 Transacciones distribuidas

Ejecutar el procedimiento `sp_distributed_follow_2pc(...)` y guardar evidencia de `distributed_transactions`, locks y transacciones preparadas.

### 2.4 Failover y recuperacion

Registrar el estado de replicacion y documentar el procedimiento de promocion manual de una replica.

### 2.5 Consolidacion final

Reunir todos los JSON generados por los scripts previos y exportar un resumen con una grafica comparativa.

## 3. Evidencia esperada tras ejecutar los scripts

Los scripts dejan archivos en:

- `docs/results/exp1_latency_intra_shard.json`
- `docs/results/exp3_replication_sync.json`
- `docs/results/exp4_distributed_transactions.json`
- `docs/results/exp5_failover_recovery.json`
- `docs/results/postgres_summary.json`

Y los graficos en:

- `docs/images/postgres_summary_latency.png`

## 4. Estado del entregable

- Los scripts estan creados.
- La consolidacion final esta preparada para consumir resultados reales.
- Falta ejecutar los experimentos en un cluster PostgreSQL operativo para poblar los JSON con datos reales.

## 5. Conclusiones tecnicas esperadas

1. Las operaciones intra-shard deben ser mas rapidas que las operaciones distribuidas.
2. `synchronous_commit = off` debe mostrar menor latencia que `on`.
3. Las transacciones distribuidas requieren control cuidadoso de locks y rollback.
4. Un failover en PostgreSQL sigue siendo mas manual que en un motor NewSQL nativo.
