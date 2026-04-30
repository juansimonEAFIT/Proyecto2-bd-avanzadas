# TODO.md - Plan de Trabajo Dividido (4 Integrantes)

**Proyecto 2: Arquitecturas Distribuidas - Red Social**

---

## Distribución General de Responsabilidades

| Integrante | Especialidad | Enfoque Principal |
|-----------|-------------|-------------------|
| **1** | PostgreSQL Setup & Replicación | Infra, particionamiento, init |
| **2** | CockroachDB Setup | Infra, tablas, auto-sharding |
| **3** | Experimentos PostgreSQL | Tests, performance, 2PC |
| **4** | Experimentos CockroachDB & Análisis | Tests, comparación, resultados |

---

## INTEGRANTE 1: PostgreSQL - Infraestructura y Particionamiento

**Objetivo:** Configurar PostgreSQL distribuido con 3 nodos y particionamiento manual.

- [ ] Revisar Proyecto2.md y README.md del proyecto
- [ ] Crear `infra/docker-compose.postgres.yml` con 3 nodos y pgAdmin
- [ ] Levantar contenedores y verificar conectividad
- [ ] Crear usuario replicator y configurar permisos WAL
- [ ] Crear `scripts/postgres/01-init-primary.sql` con tablas USERS, POSTS, COMMENTS, POST_LIKES, FOLLOWERS y distributed_transactions
- [ ] Crear `scripts/postgres/02-distributed-transactions.sql` con procedimientos para 2PC y operaciones multi-shard
- [ ] Verificar que la replicación esté funcionando con `SELECT * FROM pg_stat_replication;`
- [ ] Crear `scripts/postgres/03-data-generation.sql` con funciones para usuarios, posts, comentarios y followers
- [ ] Ejecutar funciones y verificar distribución de datos por partición
- [ ] Crear documentación técnica de PostgreSQL en `docs/ARQUITECTURA.md`
- [ ] Documentar el proceso de deployment paso a paso
- [ ] BONUS: Diseñar y probar un escenario de replicación asíncrona en PostgreSQL
- [ ] BONUS: Evaluar uso de un broker (RabbitMQ/Kafka) para desacoplar escritura y replicación
- [ ] BONUS: Documentar trade-offs entre replicación sincrónica y asíncrona

### Entregable del integrante 1

- Cluster PostgreSQL funcional con datos de prueba
- Particionamiento horizontal documentado
- Replicación configurada y verificada
- Escenario bonus de replicación asíncrona documentado

### Definition of Done

- `docker ps` muestra los contenedores corriendo
- La conexión al primary funciona
- Los datos se distribuyen en 3 particiones
- La replicación está activa

---

## INTEGRANTE 2: CockroachDB - Infraestructura y Auto-Sharding

**Objetivo:** Configurar CockroachDB distribuido con 3 nodos y carga de datos automática.

- [x] Revisar Proyecto2.md y README.md del proyecto
- [x] Estudiar la arquitectura de CockroachDB: Raft, ranges y leaseholders
- [x] Crear `infra/docker-compose.cockroachdb.yml` con 3 nodos e inicialización del cluster
- [x] Levantar el cluster y verificar que todos los nodos estén activos
- [x] Acceder a la interfaz web de CockroachDB
- [x] Crear `scripts/cockroachdb/01-init-cockroachdb.sql` con tablas USERS, POSTS, COMMENTS, POST_LIKES, FOLLOWERS y distributed_transactions
- [x] Incluir índices secundarios y configuración de zonas opcional
- [x] Ejecutar el script de inicialización y verificar tablas creadas
- [x] Crear `scripts/cockroachdb/02-data-generation.sql` para poblar usuarios, posts, comentarios, followers y likes
- [x] Ejecutar la generación de datos y verificar la distribución en ranges
- [x] Crear documentación técnica de CockroachDB en `docs/ARQUITECTURA.md`
- [x] Documentar el auto-sharding y el protocolo Raft
- [x] BONUS: Configurar y documentar escenario de geodistribución con latencia simulada
- [x] BONUS: Ejecutar prueba de quórum con nodos insuficientes y registrar comportamiento del cluster
- [x] BONUS: Documentar impacto de geodistribución y quórum en disponibilidad y consistencia

### Entregable del integrante 2

- Cluster CockroachDB funcional con datos de prueba
- Auto-sharding documentado
- Replicación y consenso explicados
- Escenarios bonus de geodistribución y quórum documentados

### Definition of Done

- `docker ps` muestra los contenedores corriendo
- La UI web es accesible
- Los datos están distribuidos en ranges
- El cluster está operativo

---

## INTEGRANTE 3: Experimentos PostgreSQL

**Objetivo:** Implementar y ejecutar experimentos de latencia, replicación y transacciones distribuidas en PostgreSQL.

- [ ] Revisar los scripts de PostgreSQL creados por el integrante 1
- [ ] Instalar dependencias Python necesarias para las pruebas
- [ ] Crear un archivo `.env` local con las configuraciones de PostgreSQL
- [ ] Crear `experiments/exp1_latency_intra_shard.py` para medir operaciones sobre un solo shard
- [ ] Ejecutar el experimento y documentar resultados
- [ ] Comparar latencias entre primary y réplicas
- [ ] Crear `experiments/exp3_replication_sync.py` para comparar `synchronous_commit=ON` y `OFF`
- [ ] Analizar el impacto de la sincronización en performance
- [ ] Documentar el experimento en `docs/EXPERIMENTOS.md`
- [ ] Crear `experiments/exp4_distributed_transactions.py` para simular 2PC manual
- [ ] Documentar locks, fallos y recuperación después de PREPARE
- [ ] Crear `experiments/exp5_failover_recovery.py` para simular caída del primary
- [ ] Documentar el procedimiento de recuperación manual
- [ ] Crear `experiments/analyze_postgres_results.py` para consolidar resultados
- [ ] Documentar hallazgos en `docs/RESULTADOS.md`
- [ ] BONUS: Diseñar una SAGA para operación larga en PostgreSQL como alternativa a 2PC
- [ ] BONUS: Implementar compensaciones y registrar evidencia de rollback por pasos
- [ ] BONUS: Comparar SAGA vs 2PC en complejidad y consistencia

### Entregable del integrante 3

- Suite de experimentos PostgreSQL con resultados
- Análisis de replicación y 2PC
- Documentación de failover y recuperación
- Escenario bonus SAGA en PostgreSQL con compensaciones

### Definition of Done

- Los scripts de experimentos ejecutan sin errores
- Los resultados están guardados
- Los gráficos están generados
- El reporte técnico está listo

---

## INTEGRANTE 4: Experimentos CockroachDB y Análisis Comparativo

**Objetivo:** Implementar experimentos equivalentes en CockroachDB y construir el análisis comparativo final.

- [ ] Revisar los scripts de CockroachDB creados por el integrante 2
- [ ] Instalar el driver necesario para conectar desde Python
- [ ] Crear un archivo `.env` local con la configuración de CockroachDB
- [ ] Crear `experiments/exp1_latency_crdb.py` para medir operaciones dentro de un range
- [ ] Ejecutar el experimento y documentar resultados
- [ ] Comparar los resultados con PostgreSQL
- [ ] Crear `experiments/exp2_transactions_crdb.py` para probar transacciones ACID distribuidas nativas
- [ ] Simular fallos durante transacciones y verificar rollback automático
- [ ] Crear `experiments/exp3_ranges_distribution.py` para observar la distribución automática
- [ ] Comparar el particionamiento automático con el manual de PostgreSQL
- [ ] Crear `experiments/exp6_comparison.py` con la matriz comparativa PostgreSQL vs CockroachDB
- [ ] Generar gráficos comparativos y exportar resultados
- [ ] Crear `docs/CAP_PACELC_ANALYSIS.md` con el análisis teórico y práctico
- [ ] Crear `docs/RESUMEN_EJECUTIVO.md` con hallazgos y recomendaciones
- [ ] Actualizar `README.md` principal si hace falta
- [ ] Preparar la presentación final del proyecto
- [ ] BONUS: Diseñar y documentar un flujo CQRS con dos microservicios (comandos y consultas)
- [ ] BONUS: Integrar resultados de CQRS con comparación PostgreSQL vs NewSQL
- [ ] BONUS: Extender el análisis comparativo final incluyendo CQRS, geodistribución, quórum, SAGA y replicación asíncrona

### Entregable del integrante 4

- Análisis comparativo completo
- Documentación CAP/PACELC
- Presentación final lista
- Integración final de todos los bonus en el informe comparativo

### Definition of Done

- Los experimentos de CockroachDB están ejecutados
- La matriz comparativa está completa
- La documentación ejecutiva está escrita
- La presentación está lista

---

## Coordinación del Equipo

- Revisar avances entre integrantes de forma regular
- Validar que cada script funcione antes de integrarlo
- Mantener documentación actualizada a medida que se avanza
- Guardar resultados de experimentos en una carpeta común
- Revisar consistencia entre README, docs y scripts

---

## Checklist Final

- [ ] Todos los archivos `.md` están bien formateados
- [ ] Todos los scripts Python ejecutan sin errores
- [ ] Los archivos `docker-compose` funcionan correctamente
- [ ] Los datos de prueba están cargados en ambas bases
- [ ] Los resultados de experimentos están guardados
- [ ] Los gráficos están generados
- [ ] El README tiene instrucciones completas
- [ ] La presentación está lista
- [ ] El repositorio está limpio
- [ ] Todos los integrantes pueden ejecutar el proyecto desde cero


