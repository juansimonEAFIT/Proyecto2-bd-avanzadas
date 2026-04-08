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

## 2. Replicacion Asincronica PostgreSQL

Archivo:
- `scripts/postgres/05-bonus-async-replication.sql`

Pasos:
1. Ejecutar script en PostgreSQL primary.
2. Correr `CALL sp_async_write_benchmark(1000);` con `synchronous_commit = off`.
3. Repetir con `synchronous_commit = on` y comparar latencia.

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
