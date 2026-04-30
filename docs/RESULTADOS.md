# Resultados - Experimentos PostgreSQL (Integrante 3)

Este documento consolida los resultados reales obtenidos contra el cluster PostgreSQL en AWS. Los artefactos base quedaron en `docs/results/` y el resumen consolidado en `docs/results/postgres_summary.json`.

## 1. Experimentos ejecutados

- `experiments/exp1_latency_intra_shard.py`
- `experiments/exp2_explain_analyze_postgres.py`
- `experiments/exp3_replication_sync.py`
- `experiments/exp4_distributed_transactions.py`
- `experiments/exp5_failover_recovery.py`
- `experiments/analyze_postgres_results.py`

## 2. Hallazgos principales

### 2.1 Latencia base intra-shard

Resultados observados:

- escritura media en primary: `235.0066 ms`
- lectura media por PK en primary: `234.7786 ms`
- lectura media por PK en replica 1: `247.2385 ms`
- lectura media por PK en replica 2: `234.4259 ms`

Lectura tecnica:

- se pudo validar distribucion por particiones (`users_p1`, `users_p2`, `users_p3`)
- se validaron lecturas reales sobre primary y replicas
- `replica-1` tuvo una variabilidad mayor que `replica-2`

### 2.2 Impacto de `synchronous_commit`

Resultados observados:

- `sync_per_insert_ms = 0.0659`
- `async_per_insert_ms = 0.0286`
- mejora relativa del modo async: `56.6%`

Lectura tecnica:

- el costo de esperar confirmacion sincronica de replicas fue medible
- `pg_stat_replication` mostro cambio real de `sync_state`
- el experimento confirma el trade-off consistencia/performance

### 2.3 EXPLAIN / EXPLAIN ANALYZE

Resultados observados:

- insercion en `users` particionada: `0.253 ms`
- consulta intra-shard localizada: `0.141 ms`
- join multi-tabla / inter-shard logico: `0.688 ms`
- agregacion sobre `posts`: `0.080 ms`

Lectura tecnica:

- se ejecutaron planes reales con `EXPLAIN (ANALYZE, VERBOSE, BUFFERS, FORMAT JSON)`
- los planes quedaron persistidos en `docs/results/postgres_explain_analyze.json`
- el caso de join mostro la forma mas clara de complejidad creciente del plan, con operadores `Merge Join` y `Merge Append`

### 2.4 Coordinacion manual de transacciones distribuidas

Resultados observados:

- transaccion entre shards `1 -> 2`
- tiempo total: `239.2275 ms`
- estado final en `distributed_transactions`: `COMMITTED`
- prepared transactions visibles al cierre: `0`
- rollback controlado validado sin cambio persistente

Lectura tecnica:

- la coordinacion manual agrega overhead y complejidad operativa
- el proyecto modela 2PC sobre shards logicos, no sobre un cluster PostgreSQL distribuido nativo
- se observaron locks durante la ejecucion y se dejo evidencia en el JSON del experimento

### 2.5 Failover y recuperacion

Resultados observados:

- `primary` operativo y fuera de recovery
- dos replicas visibles en `pg_stat_replication`
- `replica1` y `replica2` accesibles externamente tras ajustar el Security Group
- procedimiento de failover documentado en modo `dry-run`

Lectura tecnica:

- el failover en PostgreSQL sigue siendo manual
- la validacion se dejo preparada sin ejecutar una promocion real en el entorno compartido
- el acceso externo a replicas quedo validado tras abrir `5433` y `5434`

## 3. Artefactos generados

JSON:

- `docs/results/exp1_latency_intra_shard.json`
- `docs/results/postgres_explain_analyze.json`
- `docs/results/exp3_replication_sync.json`
- `docs/results/exp4_distributed_transactions.json`
- `docs/results/exp5_failover_recovery.json`
- `docs/results/postgres_summary.json`

Graficos:

- `docs/images/postgres_summary_latency.png`
- `docs/images/postgres_replication_sync_vs_async.png`
- `docs/images/postgres_intra_shard_nodes.png`
- `docs/images/postgres_explain_analyze.png`

## 4. Conclusiones

1. El cluster PostgreSQL si permite demostrar replicacion activa, particionamiento y coordinacion manual de operaciones entre shards logicos.
2. `synchronous_commit = off` redujo fuertemente la latencia de escritura frente a `on`.
3. La parte mas debil operativamente sigue siendo failover y acceso/observabilidad de replicas desde fuera del host.
3. El acceso externo a replicas quedo resuelto al abrir `5433` y `5434` en AWS, permitiendo comparacion real de lecturas.
4. Frente a una arquitectura distribuida nativa, PostgreSQL exige mas trabajo manual para transacciones multi-shard y recuperacion.
