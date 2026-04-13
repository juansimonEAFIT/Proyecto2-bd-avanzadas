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
- `infra/docker-compose.latency.yml`

Objetivo:
- Simular un cluster geodistribuido (3 regiones) y medir el impacto de latencia de red sobre escrituras.
- Verificar comportamiento bajo quorum insuficiente (consistencia sobre disponibilidad).

Pre-requisitos:
1. Docker Desktop encendido.
2. PowerShell en la raiz del proyecto.
3. Acceso para descargar imagen `gaiaadm/pumba` (primera ejecucion).

Topologia usada:
1. node1: `region=us-east1`
2. node2: `region=us-central1`
3. node3: `region=eu-west1`

Pasos de ejecucion:
1. Ejecutar escenario completo (cluster + SQL + latencia + quorum):
   `./experiments/bonus_quorum_geodistribution.ps1`
2. Opcional: ajustar intensidad de red y numero de escrituras:
   `./experiments/bonus_quorum_geodistribution.ps1 -DelayMs 250 -DurationSeconds 120 -Writes 20`

Que hace el script automaticamente:
1. Levanta `infra/docker-compose.latency.yml`.
2. Inicializa el cluster.
3. Ejecuta `scripts/cockroachdb/04-bonus-quorum-geodistribution.sql`.
4. Inyecta latencia sobre node2 y node3 con Pumba (netem delay).
5. Mide tiempos de insercion y reporta min/avg/max.
6. Detiene dos nodos y valida el resultado esperado de quorum insuficiente.
7. Restaura los nodos.

Validaciones recomendadas:
1. Confirmar localities:
   `docker exec -i cockroach-node1-latency ./cockroach sql --insecure --host=cockroach-node1-latency:26257 -e "SET allow_unsafe_internals = true; SELECT node_id, locality, is_live FROM crdb_internal.gossip_nodes ORDER BY node_id;"`
2. Revisar datos insertados:
   `docker exec -i cockroach-node1-latency ./cockroach sql --insecure --host=cockroach-node1-latency:26257 -e "SELECT count(*), min(created_at), max(created_at) FROM bonus_geo.geo_ping;"`
3. Capturar evidencia de consola con:
   - resumen de latencia (min/avg/max)
   - error o timeout con quorum insuficiente

Conclusiones esperadas:
1. Al aumentar latencia entre regiones, sube la latencia de commit por consenso Raft.
2. Con menos de mayoria de replicas activas, escrituras deben bloquearse o fallar para preservar consistencia.

### 4.1 Resultados observados (ejecucion real)

Fecha de ejecucion: 2026-04-12

Configuracion usada:
1. `DelayMs = 180`
2. `DurationSeconds = 90`
3. `Writes = 12`

Resultado de latencia de escrituras:
1. Promedio: 432.18 ms
2. Minimo: 396.46 ms
3. Maximo: 515.21 ms

Resultado de quorum insuficiente:
1. Se detuvieron `cockroach-node2-latency` y `cockroach-node3-latency`.
2. La escritura contra `bonus_geo.geo_ping` fue rechazada.
3. Error principal observado: `replica unavailable` / `lost quorum` (`SQLSTATE 40003`).

Interpretacion:
1. La latencia entre regiones impacta directamente el tiempo de commit por coordinacion de replicas.
2. Con menos de mayoria de replicas disponibles, CockroachDB prioriza consistencia y rechaza escrituras.
3. El comportamiento observado es consistente con el trade-off CAP esperado para este escenario.

## 5. Evidencia minima recomendada

- Capturas de estado de nodos antes y despues de pruebas.
- Tiempos de latencia sync vs async.
- Registro de SAGA completada y compensada.
- Resultado de CQRS mostrando proyeccion del evento.
- Conclusiones de disponibilidad vs consistencia en quorum.
