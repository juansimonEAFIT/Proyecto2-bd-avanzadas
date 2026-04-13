# Experimentos - Estado Actual

## Objetivo

Este documento registra lo que hoy ya fue validado, lo que puede ejecutarse y lo que sigue pendiente para cerrar el proyecto.

## 1. Validacion base de PostgreSQL

Comandos minimos:

```bash
docker ps
docker exec postgres-primary psql -U admin -d social_network -c "SELECT application_name, state, sync_state FROM pg_stat_replication;"
docker exec postgres-primary psql -U admin -d social_network -c "SELECT tableoid::regclass AS partition_name, count(*) FROM users GROUP BY 1 ORDER BY 1;"
```

Que debe verse:

- `postgres-primary`, `postgres-replica-1`, `postgres-replica-2` y `pgadmin4` activos
- replicas en `streaming`
- datos repartidos entre `users_p1`, `users_p2` y `users_p3`

## 2. Entregables validados

Estado:

- cluster PostgreSQL funcional con datos de prueba
- particionamiento horizontal documentado
- replicacion configurada y verificada
- escenario bonus de replicacion asincronica documentado

Definition of Done validada:

- `docker ps` muestra los contenedores corriendo
- la conexion al primary funciona
- los datos se distribuyen en 3 particiones
- la replicacion esta activa

Evidencia observada en la revision actual:

- replicas activas en `pg_stat_replication`
- funciones de generacion cargadas en la base
- datos presentes en `users`, `posts`, `comments`, `followers` y `post_likes`
- distribucion visible en las particiones de `users`

## 3. Evidencia manual adicional

Generacion y particionamiento:

- `fn_generate_comments(900)` dejo `900` registros en `comments`
- distribucion de `comments`: `comments_p1 = 300`, `comments_p2 = 293`, `comments_p3 = 307`
- `fn_generate_post_likes(1200)` dejo `1196` registros efectivos en `post_likes`
- distribucion de `post_likes`: `post_likes_p1 = 419`, `post_likes_p2 = 377`, `post_likes_p3 = 400`
- `fn_generate_followers(800)` dejo `797` relaciones efectivas en `followers`
- distribucion de `followers`: `followers_p1 = 266`, `followers_p2 = 256`, `followers_p3 = 275`

Nota:

- `post_likes` y `followers` pueden quedar por debajo del numero solicitado porque las funciones evitan duplicados con `ON CONFLICT DO NOTHING`

Validacion manual de 2PC:

- se identifico un par de usuarios en shards distintos: `follower_id = 1` y `following_id = 6`
- la primera corrida de `sp_distributed_follow_2pc(1, 6)` fallo con `cannot commit while a subtransaction is active`
- despues se recargo `scripts/postgres/02-distributed-transactions.sql` en el primary
- al repetir el procedimiento, la operacion termino con estado exitoso
- se creo la relacion `followers (1, 6)` en la particion `followers_p3`
- `distributed_transactions` registro la operacion con estado `COMMITTED`, `source_shard = 1` y `target_shard = 0`

## 4. Bonus de replicacion asincronica validado

Archivos:

- `scripts/postgres/05-bonus-async-replication.sql`
- `experiments/bonus_async_replication_postgres.py`

Ejecucion:

```bash
python experiments/bonus_async_replication_postgres.py
```

Que hace:

- carga la vista `v_replication_overview`
- fuerza una corrida sincronica real con `synchronous_standby_names`
- ejecuta benchmark con `synchronous_commit = on`
- vuelve a modo async
- ejecuta benchmark con `synchronous_commit = off`
- valida que las filas aparezcan en ambas replicas

Ultima corrida validada:

- fecha: `2026-04-09`
- prefijo: `bonus_async_e8e1000d`
- tiempo sync: `9.373 ms`
- tiempo async: `8.342 ms`
- mejora async observada: `11.0%`
- replicas en sync durante la corrida sincronica
- replicas en async al finalizar la corrida asincronica

Interpretacion:

- el experimento demuestra cambio real de comportamiento del cluster
- los tiempos pueden variar por carga del host
- la evidencia persistida queda en `async_replication_benchmarks`
- este bonus ya fue implementado, ejecutado y documentado

## 5. Bonus adicionales

### CQRS

```bash
docker compose -f infra/docker-compose.bonus-cqrs.yml up -d
python experiments/bonus_cqrs_demo.py
```

Sirve para demostrar:

- separacion entre modelo de comando y modelo de lectura
- uso de RabbitMQ como apoyo para desacoplamiento

### SAGA

```bash
psql -h localhost -U admin -d social_network -f scripts/postgres/06-bonus-saga.sql
python experiments/bonus_saga_postgres.py
```

Sirve para demostrar:

- compensaciones por pasos
- alternativa conceptual a 2PC para operaciones largas

## 6. Lo que sigue pendiente

Para cerrar el proyecto todavia faltan experimentos obligatorios que hoy no estan implementados en `experiments/`:

- latencia intra-shard
- lectura inter-shard
- 2PC documentado como experimento completo
- failover y recuperacion
- comparacion PostgreSQL vs CockroachDB
- consolidacion de resultados y reporte final
