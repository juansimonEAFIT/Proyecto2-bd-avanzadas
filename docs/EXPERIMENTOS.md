# Experimentos PostgreSQL - Integrante 3

## Objetivo

Este documento deja el manual operativo de los experimentos PostgreSQL del integrante 3, usando el cluster AWS disponible en `54.84.181.98`.

Contexto observado en la ejecucion final:

- el `primary` responde por `54.84.181.98:5432`
- `postgres-replica-1` responde por `54.84.181.98:5433`
- `postgres-replica-2` responde por `54.84.181.98:5434`
- las replicas aparecen activas en `pg_stat_replication`
- el Security Group fue ajustado para permitir acceso externo a `5433` y `5434`

## 1. Precondiciones

- Tener `.env` configurado con `PG_PRIMARY_*`, `PG_REPLICA1_*`, `PG_REPLICA2_*`
- Instalar dependencias:

```bash
python -m pip install -r requirements.txt
```

- Validar que el primary responda:

```bash
python experiments/exp1_latency_intra_shard.py
```

## 2. Experimento 1: Latencia Intra-Shard

Archivo:

- `experiments/exp1_latency_intra_shard.py`

Objetivo:

- medir escritura sobre `users` en el primary
- medir lectura por PK en el primary
- intentar comparar lectura contra replicas si son alcanzables
- evidenciar particion con `tableoid::regclass`

Comando:

```bash
python experiments/exp1_latency_intra_shard.py
```

Salida esperada:

- JSON en `docs/results/exp1_latency_intra_shard.json`
- muestra de particiones `users_p1`, `users_p2`, `users_p3`
- metricas de escritura y lectura del primary
- estado de conectividad de replicas

Resultado observado en la corrida final:

- `write_primary.mean = 235.0066 ms`
- `read_primary.mean = 234.7786 ms`
- `read_replica1.mean = 247.2385 ms`
- `read_replica2.mean = 234.4259 ms`

Interpretacion tecnica:

- el experimento deja linea base real sobre el primary y las dos replicas
- `replica-1` mostro un outlier importante en `p99`, lo que sugiere mayor variabilidad puntual
- `replica-2` se comporto muy cercano al primary
- la distribucion por particiones se verifico desde el primary

## 3. Experimento 2: EXPLAIN / EXPLAIN ANALYZE

Archivo:

- `experiments/exp2_explain_analyze_postgres.py`

Referencia base:

- `scripts/postgres/04-experiments.sql`

Objetivo:

- cubrir la exigencia del proyecto sobre `EXPLAIN / EXPLAIN ANALYZE`
- inspeccionar planes de insercion, consulta localizada, join multi-tabla y agregacion
- dejar evidencia persistida del plan y de los tiempos de ejecucion

Comando:

```bash
python experiments/exp2_explain_analyze_postgres.py
```

Salida esperada:

- JSON en `docs/results/postgres_explain_analyze.json`
- grafico en `docs/images/postgres_explain_analyze.png`

Resultado observado:

- `insert_partitioned_users`: `0.253 ms`
- `intra_shard_lookup`: `0.141 ms`
- `inter_shard_join`: `0.688 ms`
- `distributed_aggregation_posts`: `0.080 ms`

Interpretacion tecnica:

- el `INSERT` sobre tabla particionada cayo en un `ModifyTable`
- la consulta intra-shard quedo como `Aggregate` + `Nested Loop`
- el join multi-tabla mostro un plan mas complejo con `Limit`, `Aggregate`, `Merge Join` y `Merge Append`
- la agregacion sobre `posts` se resolvio con `Aggregate`, `Sort` y `Append`

## 4. Experimento 3: Replicacion Sync vs Async

Archivo:

- `experiments/exp3_replication_sync.py`

Dependencia SQL:

- `scripts/postgres/05-bonus-async-replication.sql`

Objetivo:

- comparar `synchronous_commit = on` vs `off`
- registrar `sync_state`
- cuantificar mejora de latencia

Comando:

```bash
python experiments/exp3_replication_sync.py
```

Salida esperada:

- JSON en `docs/results/exp3_replication_sync.json`
- evidencia de `sync_state = sync/potential/async`
- resumen por insercion

Resultado observado en esta corrida:

- `sync_per_insert_ms = 0.0659`
- `async_per_insert_ms = 0.0286`
- mejora async observada: `56.6%`
- `postgres-replica-1` aparecio en `sync`
- `postgres-replica-2` aparecio en `potential` durante la corrida sync
- ambas replicas aparecieron `async` en la corrida async

Interpretacion tecnica:

- el costo de confirmacion sincronica fue medible y claro
- aun sin acceso directo a `5433/5434`, el primary si mostro el estado interno de replicacion

## 5. Experimento 4: Transacciones Distribuidas / 2PC Manual

Archivo:

- `experiments/exp4_distributed_transactions.py`

Dependencia SQL:

- `scripts/postgres/02-distributed-transactions.sql`

Objetivo:

- ejecutar una operacion entre shards logicos distintos
- registrar evidencia en `distributed_transactions`
- capturar locks visibles
- documentar una aproximacion de rollback controlado

Comando:

```bash
python experiments/exp4_distributed_transactions.py
```

Salida esperada:

- JSON en `docs/results/exp4_distributed_transactions.json`
- transaccion `COMMITTED`
- locks observables
- nota sobre prepared transactions

Resultado observado en esta corrida:

- usuarios elegidos: `user_id 1` y `user_id 2`
- shards: `1 -> 2`
- `elapsed_ms = 239.2275`
- estado final en `distributed_transactions = COMMITTED`
- `prepared_transactions = []`
- rollback controlado validado: la relacion no cambio tras `ROLLBACK`

Interpretacion tecnica:

- en este proyecto el 2PC esta modelado sobre shards logicos/particiones
- no se dejo una `PREPARE TRANSACTION` abierta por seguridad operativa en entorno compartido
- el costo y la coordinacion manual siguen siendo notorios frente a un motor distribuido nativo

## 6. Experimento 5: Failover y Recuperacion

Archivo:

- `experiments/exp5_failover_recovery.py`

Objetivo:

- documentar el procedimiento manual de failover
- dejar evidencia del estado previo del cluster
- no alterar el entorno por defecto

Comando:

```bash
python experiments/exp5_failover_recovery.py
```

Salida esperada:

- JSON en `docs/results/exp5_failover_recovery.json`
- modo `dry-run`
- estado del primary
- procedimiento manual de promocion

Resultado observado en la corrida final:

- `primary`: `pg_is_in_recovery = false`
- `replica1`: `pg_is_in_recovery = true`
- `replica2`: `pg_is_in_recovery = true`
- replicas visibles desde `pg_stat_replication`: 2
- lectura simple validada en primary y replicas
- procedimiento manual documentado con `ssh`, `docker stop`, `pg_promote()`

Interpretacion tecnica:

- el failover sigue siendo operativo y manual
- la observabilidad del cluster depende mas del primary que del acceso directo a replicas desde fuera

## 7. Consolidacion Final

Archivo:

- `experiments/analyze_postgres_results.py`

Comando:

```bash
python experiments/analyze_postgres_results.py
```

Artefactos generados:

- `docs/results/postgres_summary.json`
- `docs/images/postgres_summary_latency.png`
- `docs/images/postgres_replication_sync_vs_async.png`
- `docs/images/postgres_intra_shard_nodes.png`
- `docs/images/postgres_explain_analyze.png`

## 8. Troubleshooting

Replica no responde:

- verificar si los puertos `5433` y `5434` estan publicados en Docker
- verificar reglas inbound del Security Group para `5433` y `5434`
- si aun no abre, usar pgAdmin dentro del host Docker o un tunel SSH
- mientras tanto, tomar evidencia de replicas desde `pg_stat_replication`

No existen vistas o procedures:

- recargar:

```bash
psql -h 54.84.181.98 -U admin -d social_network -f scripts/postgres/02-distributed-transactions.sql
psql -h 54.84.181.98 -U admin -d social_network -f scripts/postgres/05-bonus-async-replication.sql
```

Error con prepared transactions:

- confirmar que `max_prepared_transactions` este habilitado en el primary
- evitar dejar `PREPARE TRANSACTION` abierta en entorno compartido si no hay ventana controlada de prueba
