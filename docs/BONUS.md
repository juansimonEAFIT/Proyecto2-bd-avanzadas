# BONUS Track - Implementacion Ejecutable

Este documento describe como ejecutar los bonus solicitados: CQRS, geodistribucion, quorum, SAGA y replicacion asincronica.

## 1. CQRS

Archivos:
- `infra/docker-compose.bonus-cqrs.yml`
- `scripts/common/01-bonus-cqrs-command.sql`
- `scripts/common/02-bonus-cqrs-query.sql`
- `experiments/bonus_cqrs_demo.py`

Pasos:
1. Levantar infraestructura CQRS:
   `docker compose -f infra/docker-compose.bonus-cqrs.yml up -d`
2. Ejecutar demo:
   `python experiments/bonus_cqrs_demo.py`
3. Validar que el evento se proyecte del modelo de comando al de lectura.

Nota:
- Este bonus muestra desacoplamiento entre escritura y lectura.
- RabbitMQ se usa como soporte del flujo por eventos.

## 2. Replicacion Asincronica PostgreSQL

Archivos:
- `scripts/postgres/05-bonus-async-replication.sql`
- `experiments/bonus_async_replication_postgres.py`

Pasos:
1. Ejecutar script en PostgreSQL primary.
2. Correr benchmark con `synchronous_commit = off`.
3. Repetir con `synchronous_commit = on` y comparar latencia.

Ejecucion recomendada:
1. Cargar objetos SQL:
   `psql -h localhost -U admin -d social_network -f scripts/postgres/05-bonus-async-replication.sql`
2. Ejecutar benchmark automatizado:
   `python experiments/bonus_async_replication_postgres.py`

Evidencia validada:
- el script fuerza una corrida sync real y luego una async
- las replicas cambian de `sync_state = sync/potential` a `sync_state = async`
- las filas quedan visibles en primary y replicas

Ultima corrida registrada:
- fecha: `2026-04-09`
- sync: `9.373 ms`
- async: `8.342 ms`
- mejora async observada: `11.0%`

## 3. SAGA sobre PostgreSQL

Archivos:
- `scripts/postgres/06-bonus-saga.sql`
- `experiments/bonus_saga_postgres.py`

Pasos:
1. Ejecutar el SQL para crear tabla y procedimiento SAGA.
2. Ejecutar demo:
   `python experiments/bonus_saga_postgres.py`
3. Revisar estado de compensaciones en `saga_instances`.

## 4. Geodistribucion y Quorum en CockroachDB

Archivos:
- `scripts/cockroachdb/04-bonus-quorum-geodistribution.sql`
- `experiments/bonus_quorum_geodistribution.ps1`

Pasos:
1. Ejecutar script SQL de apoyo en CockroachDB.
2. Ejecutar PowerShell:
   `./experiments/bonus_quorum_geodistribution.ps1`
3. Validar comportamiento al reducir nodos por debajo de quorum.

## 5. Evidencia minima recomendada

- Capturas de estado de nodos antes y despues de pruebas.
- Tiempos de latencia sync vs async.
- Registro de SAGA completada y compensada.
- Resultado de CQRS mostrando proyeccion del evento.
- Conclusiones de disponibilidad vs consistencia en quorum.
