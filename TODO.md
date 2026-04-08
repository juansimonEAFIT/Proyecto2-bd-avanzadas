# TODO.md - Plan de Trabajo Dividido (4 Integrantes)

**Proyecto 2: Arquitecturas Distribuidas - Red Social**
**Estimación:** 3-4 semanas | **Entregas:** Semanas 4, 6, 8

---

## Distribución General de Responsabilidades

| Integrante | Especialidad | Tareas Principales |
|-----------|-------------|-------------------|
| **1** | PostgreSQL Setup & Replicación | Infra, Particionamiento, Init |
| **2** | CockroachDB Setup | Infra, Tablas, Auto-sharding |
| **3** | Experimentos PostgreSQL | Tests, Performance, 2PC |
| **4** | Experimentos CockroachDB & Análisis | Tests, Comparación, Resultados |

---

## INTEGRANTE 1: PostgreSQL - Infraestructura y Particionamiento

**Objetivo:** Configurar PostgreSQL distribuido con 3 nodos (Primary + 2 Replicas) y particionamiento.

### Fase 1: Setup (Semana 1 - 3 días)

- [ ] **T1.1** Revisar Proyecto2.md y README.md del proyecto (30 min)
- [ ] **T1.2** Instalar Docker y Docker Compose en máquina local (1 hora)
- [ ] **T1.3** Crear `infra/docker-compose.postgres.yml` con 3 nodos:
  - [ ] Node Primary (puerto 5432)
  - [ ] Node Replica 1 (puerto 5433)
  - [ ] Node Replica 2 (puerto 5434)
  - [ ] pgAdmin (puerto 5050) para management
- [ ] **T1.4** Levantar contenedores y verificar conectividad (45 min)
- [ ] **T1.5** Crear usuario replicator y configurar permisos WAL (30 min)

### Fase 2: Inicialización de Base de Datos (Semana 1-2)

- [ ] **T1.6** Crear `scripts/postgres/01-init-primary.sql`:
  - [ ] Tabla USERS (particionada por HASH en 3 particiones)
  - [ ] Tabla POSTS (particionada por RANGO + HASH)
  - [ ] Tabla COMMENTS (particionada por HASH)
  - [ ] Tabla POST_LIKES (particionada por HASH)
  - [ ] Tabla FOLLOWERS (particionada por HASH)
  - [ ] Tabla distribuida_transactions (para auditoría de 2PC)
  - [ ] Índices apropiados en cada tabla/partición
- [ ] **T1.7** Crear procedimientos almacenados en `scripts/postgres/02-distributed-transactions.sql`:
  - [ ] `sp_distributed_follow_2pc()` - Prueba de 2PC
  - [ ] `sp_add_like_distributed()` - Simula operación multi-shard
- [ ] **T1.8** Verificar replicación está funcionando:
  - [ ] `SELECT * FROM pg_stat_replication;` (en primary)
  - [ ] Confirmar replicas están synced

### Fase 3: Generación de Datos Sintéticos (Semana 2)

- [ ] **T1.9** Crear `scripts/postgres/03-data-generation.sql`:
  - [ ] `fn_generate_users(10000)` - Generar usuarios particionados
  - [ ] `fn_generate_posts(50000)` - Posts distribuidos
  - [ ] `fn_generate_comments(30000)` - Comentarios distribuidos
  - [ ] `fn_generate_followers(20000)` - Relaciones followers
  - [ ] Documentar distribución esperada en cada shard
- [ ] **T1.10** Ejecutar funciones y verificar data:
  - [ ] SELECT COUNT(*) FROM users; (debe reflejar 10k)
  - [ ] SELECT COUNT(*) FROM users_P1, users_P2, users_P3; (verificar distribución)

### Fase 4: Documentación Técnica (Semana 2)

- [ ] **T1.11** Crear `docs/ARQUITECTURA.md` - Sección PostgreSQL:
  - [ ] Diagrama de particionamiento
  - [ ] Explicación de hash function (user_id % 3)
  - [ ] Detalles de replicación (synchronous vs asynchronous)
  - [ ] Plan de failover manual
- [ ] **T1.12** Crear documento de deployment steps (paso a paso)

### Sprint Review y Owner

- **Deliverable:** Cluster PostgreSQL funcional con datos de prueba
- **Owner:** Responsable de mantener infra postgres en caso de issues
- **Definition of Done:**
  - [ ] `docker ps` muestra 4 contenedores corriendo
  - [ ] Connect a primary exitosamente
  - [ ] 10,000 usuarios distribuidos en 3 particiones
  - [ ] Replicación activa (lag < 1 segundo)

---

## INTEGRANTE 2: CockroachDB - Infraestructura y Auto-Sharding

**Objetivo:** Configurar CockroachDB distribuido con 3 nodos y carga de datos automática.

### Fase 1: Setup (Semana 1 - 3 días)

- [ ] **T2.1** Revisar Proyecto2.md y README.md del proyecto (30 min)
- [ ] **T2.2** Estudiar CockroachDB architecture (Raft, ranges) - 1 hora
- [ ] **T2.3** Crear `infra/docker-compose.cockroachdb.yml` con 3 nodos:
  - [ ] Node 1 (puerto 26257, UI puerto 8080)
  - [ ] Node 2 (puerto 26258, UI puerto 8081)
  - [ ] Node 3 (puerto 26259, UI puerto 8082)
  - [ ] Init container que ejecuta `cockroach init` una sola vez
- [ ] **T2.4** Levantar cluster y verificar que todos los nodos estén UP (1 hora)
- [ ] **T2.5** Acceder a interfaz web de CockroachDB (http://localhost:8080)

### Fase 2: Inicialización de Base de Datos (Semana 1-2)

- [ ] **T2.6** Crear `scripts/cockroachdb/01-init-cockroachdb.sql`:
  - [ ] Tabla USERS (CockroachDB auto-shards por primary key)
  - [ ] Tabla POSTS (auto-sharded)
  - [ ] Tabla COMMENTS (auto-sharded)
  - [ ] Tabla POST_LIKES (auto-sharded)
  - [ ] Tabla FOLLOWERS (auto-sharded)
  - [ ] Tabla distributed_transactions
  - [ ] Índices secundarios
  - [ ] Zone configurations (opcional: geo-replicación)
- [ ] **T2.7** Ejecutar init script:
  - [ ] `docker exec cockroach-node1 ./cockroach sql --insecure < scripts/cockroachdb/01-init-cockroachdb.sql`
  - [ ] Verificar tablas creadas: `SHOW TABLES;`

### Fase 3: Generación de Datos (Semana 2)

- [ ] **T2.8** Crear `scripts/cockroachdb/02-data-generation.sql`:
  - [ ] INSERT de 10,000 usuarios usando generate_series
  - [ ] INSERT de 50,000 posts
  - [ ] INSERT de 30,000 comentarios
  - [ ] INSERT de 20,000 followers
  - [ ] INSERT de 100,000 likes
  - [ ] Incluir timestamps para rango particionado (simulado)
- [ ] **T2.9** Ejecutar generación de datos:
  - [ ] Carga inicial (puede tardar 5-10 min)
  - [ ] Verificar distribución con `SELECT * FROM crdb_internal.ranges;`

### Fase 4: Monitoreo y Documentación (Semana 2)

- [ ] **T2.10** Configurar monitoreo básico:
  - [ ] Ver estado de ranges (distribución de datos)
  - [ ] Ver configuración de zonas
  - [ ] Entender el protocolo Raft en CockroachDB
- [ ] **T2.11** Crear `docs/ARQUITECTURA.md` - Sección CockroachDB:
  - [ ] Explicación de auto-sharding (ranges, leaseholders)
  - [ ] Protocolo Raft y consenso
  - [ ] Garantías ACID distribuidas
  - [ ] Comparación con PostgreSQL

### Sprint Review y Owner

- **Deliverable:** Cluster CockroachDB funcional con datos de prueba
- **Owner:** Responsable de mantener infra cockroachdb
- **Definition of Done:**
  - [ ] `docker ps` muestra 4 contenedores corriendo
  - [ ] UI Web accesible
  - [ ] 10,000 usuarios distribuidos en ranges
  - [ ] Cluster status: READY (3/3 nodes)

---

## INTEGRANTE 3: Experimentos PostgreSQL

**Objetivo:** Implementar y ejecutar experimentos de latencia, replicación y transacciones distribuidas en PostgreSQL.

### Fase 1: Setup Inicial (Semana 2)

- [ ] **T3.1** Revisar scripts de PostgreSQL creados por Integrante 1 (1 hora)
- [ ] **T3.2** Instalar librerías Python (`data/db_helpers.py` ya está creado):
  ```bash
  pip install psycopg2-binary python-dotenv
  ```
- [ ] **T3.3** Crear archive `.env` local con configuraciones:
  ```
  PG_PRIMARY_HOST=localhost
  PG_PRIMARY_PORT=5432
  PG_REPLICA1_HOST=localhost
  PG_REPLICA1_PORT=5433
  PG_REPLICA2_HOST=localhost
  PG_REPLICA2_PORT=5434
  ```

### Fase 2: Experimento 1 - Latencia Intra-Shard (Semana 2)

- [ ] **T3.4** Crear `experiments/exp1_latency_intra_shard.py`:
  - [ ] Medir INSERT latency en USERS (mismo shard)
  - [ ] Medir SELECT latency: `SELECT * FROM users WHERE user_id = 1;`
  - [ ] Ejecutar 100 iteraciones cada uno
  - [ ] Graficar: min, max, mean, p95, p99
  - [ ] Guardar resultados en `results/exp1_results.json`
- [ ] **T3.5** Ejecutar experimento y documentar resultados
- [ ] **T3.6** Comparar latencias: PRIMARY vs REPLICA1 vs REPLICA2

### Fase 3: Experimento 2 - Replicación Sincrónica (Semana 3)

- [ ] **T3.7** Crear `experiments/exp3_replication_sync.py`:
  - [ ] Medir latencia INSERT con `synchronous_commit=ON` (default)
  - [ ] Medir latencia INSERT con `synchronous_commit=OFF` (async)
  - [ ] Diferencia esperada: 10-50x más lenta con sync
  - [ ] Graficar comparación side-by-side
- [ ] **T3.8** Analizar trade-off: consistency vs performance
- [ ] **T3.9** Documentar en `docs/EXPERIMENTOS.md`

### Fase 4: Experimento 3 - Transacciones Distribuidas 2PC (Semana 3)

- [ ] **T3.10** Crear `experiments/exp4_distributed_transactions.py`:
  - [ ] Simular transferencia entre users en diferentes shards (user_id 1 y user_id 2)
  - [ ] Implementar 2PC manualmente cubriendo:
    - [ ] BEGIN
    - [ ] UPDATE user_id=1 (Shard 1)
    - [ ] UPDATE user_id=2 (Shard 2)
    - [ ] PREPARE TRANSACTION
    - [ ] Medir latencia de preparación
    - [ ] COMMIT PREPARED
  - [ ] Simular failure: rollback después de PREPARE
  - [ ] Medir tiempo total: 50-200ms esperado
- [ ] **T3.11** Documentar problemas encontrados:
  - [ ] Locks durante prepare?
  - [ ] ¿Qué sucede si nodo 1 falla después de PREPARE pero antes de COMMIT?

### Fase 5: Experimento 4 - Failover (Semana 3)

- [ ] **T3.12** Crear `experiments/exp5_failover_recovery.py`:
  - [ ] Simular caída del Primary:
    ```bash
    docker stop postgres-primary
    ```
  - [ ] Intentar conectar al primary (debe fallar)
  - [ ] Opcionalmente: promover réplica manualmente (advanced)
  - [ ] Medir tiempo de detección de fallo
  - [ ] Documentar pasos para recuperación manual
- [ ] **T3.13** Crear documento: `docs/FAILOVER_MANUAL.md`

### Fase 6: Análisis de Performance (Semana 3-4)

- [ ] **T3.14** Crear `experiments/analyze_postgres_results.py`:
  - [ ] Consolidar todos los resultados de exp1-5
  - [ ] Generar gráficos comparativos
  - [ ] Exportar tablas de resultados en CSV/JSON
- [ ] **T3.15** Documentar findings en `docs/RESULTADOS.md` (sección PostgreSQL)

### Sprint Review y Owner

- **Deliverable:** Suite de experimentos PostgreSQL con resultados
- **Owner:** Subject matter expert en latencia/performance de PostgreSQL
- **Definition of Done:**
  - [ ] 5 scripts de experimentos ejecutados exitosamente
  - [ ] Archivos de resultados guardados con timestamps
  - [ ] Gráficos generados (PNG/PDF)
  - [ ] Report técnico de hallazgos principales

---

## INTEGRANTE 4: Experimentos CockroachDB & Análisis Comparativo

**Objetivo:** Implementar experimentos equivalentes en CockroachDB y análisis comparativo final.

### Fase 1: Preparación (Semana 2)

- [ ] **T4.1** Revisar scripts de CockroachDB creados por Integrante 2 (1 hora)
- [ ] **T4.2** Instalar driver CockroachDB para Python (si aplica):
  ```bash
  pip install psycopg2-binary  # CockroachDB usa wire-compatible con PostgreSQL
  ```
- [ ] **T4.3** Crear `.env` con config CockroachDB:
  ```
  CRDB_HOST=localhost
  CRDB_PORT=26257
  ```

### Fase 2: Experimento 1 - Latencia Intra-Range (Semana 2-3)

- [ ] **T4.4** Crear `experiments/exp1_latency_crdb.py`:
  - [ ] Medir INSERT latency en USERS (mismo range)
  - [ ] Medir SELECT latency: `SELECT * FROM users WHERE user_id = 1;`
  - [ ] 100 iteraciones
  - [ ] Comparar directamente con resultados de Integrante 3
  - [ ] Esperado: ~20-50% más lento que PostgreSQL simple (por Raft)
- [ ] **T4.5** Documentar overhead de coordinación Raft

### Fase 3: Experimento 2 - Transacciones Distribuidas (Semana 3)

- [ ] **T4.6** Crear `experiments/exp2_transactions_crdb.py`:
  - [ ] Ejecutar transacción ACID distribuida nativa:
    ```sql
    BEGIN;
      UPDATE users SET following_count = following_count + 1 WHERE user_id = 1;
      UPDATE users SET follower_count = follower_count + 1 WHERE user_id = 2;
    COMMIT;
    ```
  - [ ] CockroachDB garantiza atomicidad automáticamente
  - [ ] Medir latencia: 30-100ms esperado (más rápido que 2PC manual)
- [ ] **T4.7** Simular fallo durante transacción
  - [ ] Verificar rollback automático

### Fase 4: Experimento 3 - Escalabilidad y Ranges (Semana 3)

- [ ] **T4.8** Crear `experiments/exp3_ranges_distribution.py`:
  - [ ] Consultar `crdb_internal.ranges`
  - [ ] Medir cómo CockroachDB distribuye automáticamente
  - [ ] Insertar más data y ver cómo se crean nuevos ranges
  - [ ] Comparar con particionamiento manual de PostgreSQL
- [ ] **T4.9** Generar gráfico de distribución de ranges

### Fase 5: Análisis Comparativo (Semana 4)

- [ ] **T4.10** Crear `experiments/exp6_comparison.py`:
  - [ ] Matriz comparativa PostgreSQL vs CockroachDB:
    ```
    Métrica | PostgreSQL | CockroachDB | Ganador
    --------|------------|------------|--------
    Write Latency (ms) |  [T3 results] | [T4 results] |
    Read Latency (ms) |  [T3 results] | [T4 results] |
    Join Inter-range (ms) |  [T3 results] | [T4 results] |
    2PC Latency (ms) |  [T3 results] | [T4 results] |
    Failover Time (s) |  [T3 results] | Auto |
    Setup Complexity |  Medium | Low |
    Sharding Effort |  Manual | Auto |
    ```
  - [ ] Generar gráficos comparativos
  - [ ] Exportar a CSV/JSON

### Fase 6: Análisis de CAP/PACELC (Semana 4)

- [ ] **T4.11** Crear documento `docs/CAP_PACELC_ANALYSIS.md`:
  - [ ] Explicar teorema CAP y PACELC
  - [ ] Posicionar PostgreSQL en triángulo CAP
  - [ ] Posicionar CockroachDB en triángulo CAP
  - [ ] Demostrar con ejemplos del proyecto
  - [ ] Simulación de partición de red (bonus)

### Fase 7: Documentación Final Ejecutiva (Semana 4)

- [ ] **T4.12** Crear resumen `docs/RESUMEN_EJECUTIVO.md`:
  - [ ] Hallazgos principales (1-2 páginas)
  - [ ] Recomendaciones de uso (cuándo usar cada uno)
  - [ ] Lecciones aprendidas
  - [ ] Impacto de costos en AWS/GCP
- [ ] **T4.13** Actualizar `README.md` principal si es necesario

### Fase 8: Presentación (Semana 4)

- [ ] **T4.14** Preparar slides de presentación (max 20 mins):
  - [ ] Contexto: ¿Por qué distribución?
  - [ ] Architecture overview (diagrama)
  - [ ] 3 experimentos clave + resultados
  - [ ] Conclusiones (CAP, trade-offs)
  - [ ] Preguntas frecuentes
- [ ] **T4.15** Ensayar presentación en grupo

### Sprint Review y Owner

- **Deliverable:** Análisis comparativo completo + Presentación
- **Owner:** Product owner de resultados finales
- **Definition of Done:**
  - [ ] Todos experiments CockroachDB ejecutados
  - [ ] Matriz comparativa completa
  - [ ] Documentación ejecutiva escrita
  - [ ] Presentación preparada y ensayada

---

## Timeline General

### Semana 1 (Setup & Infra)
- **T1.1 - T1.5:** Integrante 1 (PostgreSQL infra)
- **T2.1 - T2.5:** Integrante 2 (CockroachDB infra)

### Semana 2 (Data & Experimentos Iniciales)
- **T1.6 - T1.10:** Integrante 1 (Data generation)
- **T2.6 - T2.9:** Integrante 2 (Data generation)
- **T3.4 - T3.6:** Integrante 3 (Exp 1 - Latencia intra-shard)
- **T4.1 - T4.5:** Integrante 4 (Exp 1 CockroachDB)

### Semana 3 (Advanced Experiments)
- **T1.11 - T1.12:** Integrante 1 (Documentation)
- **T2.10 - T2.11:** Integrante 2 (Documentation)
- **T3.7 - T3.13:** Integrante 3 (Exp 2-4)
- **T4.6 - T4.9:** Integrante 4 (Exp 2-3)

### Semana 4 (Analysis & Presentation)
- **T3.14 - T3.15:** Integrante 3 (Results analysis)
- **T4.10 - T4.15:** Integrante 4 (Comparison + Presentation)

---

## Reglas de Colaboración

1. **Daily Sync:** 15 mins al inicio de cada sesión de trabajo
2. **Code Review:** Cada PR debe revisarlo otro integrante
3. **Testing:** Todo script debe correr sin errores antes de commit
4. **Documentation:** Inline comments en código + documentation en `docs/`
5. **Branching:** 
   - Main: `main` (solo merged después de review)
   - Work: `feature/integrante-X-task-Y` (ej: `feature/integrante1-partitioning`)

---

## Checklist Final (Antes de Entregar)

- [ ] Todos los `.md` archivos están bien formateados
- [ ] Todos los scripts Python ejecutan sin errores
- [ ] Docker-compose files funcionan correctamente
- [ ] Data de prueba está cargada en ambas BDs
- [ ] Resultados de experimentos están guardados
- [ ] Gráficos están generados (PNG/PDF)
- [ ] README tiene instrucciones completas
- [ ] Presentación está lista (15 mins max)
- [ ] Git repository está limpio (sin archivos temporales)
- [ ] Todos los integrantes pueden ejecutar el proyecto desde cero

---

**Exito con el proyecto**

