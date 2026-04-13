# Proyecto 2: Arquitecturas Distribuidas - Red Social

**Bases de Datos Avanzadas - SI3009 (2026-1)**
**Ingeniería de Sistemas - Universidad EAFIT**

---
Alejandro
Sebastian
Simon
Daniel

## Índice

- [Descripción General](#descripción-general)
- [Contexto del Problema](#contexto-del-problema)
- [Arquitectura](#arquitectura)
- [Requerimientos](#requerimientos)
- [Estructura del Proyecto](#estructura-del-proyecto)
- [Instalación y Configuración](#instalación-y-configuración)
- [Ejecución de Experimentos](#ejecución-de-experimentos)
- [Resultados y Análisis](#resultados-y-análisis)
- [Equipo](#equipo)

---

## Descripción General

Este proyecto implementa una arquitectura de base de datos distribuida para una **red social**, comparando:

1. **PostgreSQL (Base de datos clásica relacional)**
   - Particionamiento horizontal manual (Sharding por Hash y Rango)
   - Replicación Líder-Seguidor
   - Transacciones distribuidas con 2PC (Two-Phase Commit)
   - 3 nodos independientes, 2 réplicas

2. **CockroachDB (Base de datos NewSQL distribuida)**
   - Auto-sharding automático
   - Replicación con protocolo Raft
   - Transacciones ACID distribuidas nativas
   - 3 nodos con consenso automático

### Dominio: Red Social

**Entidades principales:**
- **Usuarios** (1M+ registros)
- **Posts** (100M+ registros)
- **Comentarios** (50M+ registros)
- **Likes** (500M+ relaciones)
- **Followers** (100M+ relaciones)

---

## Contexto del Problema

### Desafíos de Sistemas Distribuidos

En un sistema centralizado, mantener **ACID** es relativamente simple. Sin embargo, al distribuir datos:

- Los joins entre particiones generan latencia
- Las transacciones multi-nodo requieren coordinación compleja
- La consistencia vs disponibilidad genera trade-offs (teorema CAP)
- Los fallos de red crean particiones lógicas
- La replicación introduce complejidad de sincronización

### Preguntas Clave

Este proyecto responde:

1. ¿Cómo particionar datos transparentemente en PostgreSQL?
2. ¿Cuál es el costo de performance de las transacciones distribuidas?
3. ¿Cómo maneja CockroachDB la distribución de forma nativa?
4. ¿Cuáles son los trade-offs CAP y PACELC en la práctica?

---

## Arquitectura

### Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────┐
│                    APLICACIÓN (Python)                      │
│                (Conexiones, Experimentos)                    │
└──────────────────┬──────────────────────────────────────────┘
                   │
        ┌──────────┴──────────┐
        │                     │
   ┌────▼──────┐         ┌────▼──────┐
   │  PostgreSQL       │  CockroachDB │
   │  (3 nodos)       │   (3 nodos)   │
   └────┬──────┘       └────┬──────┘
        │                    │
   ┌────▼─────────────────────▼──────────┐
   │  Docker Compose + Red Virtual       │
   │  (Simulación de Latencia/Fallos)    │
   └─────────────────────────────────────┘
```

### Sharding Strategy para PostgreSQL

**Tabla USERS:**
- Particiona por HASH(user_id) en 3 particiones (P1, P2, P3)
- `Shard = user_id % 3`

**Tabla POSTS:**
- Particiona por RANGO(created_at) por mes
- Particiona por HASH(user_id) dentro de cada rango (opcional)

**Tabla FOLLOWERS:**
- Particiona por HASH(follower_id)

---

## Requerimientos

### Técnicos

- **Docker & Docker Compose** (para contenedores)
- **PostgreSQL 15+** (motor clásico)
- **CockroachDB 23.2+** (motor NewSQL)
- **Python 3.9+** (scripts de prueba)
- **psycopg2** (driver PostgreSQL)
- **cockroachdb-python** (opcional, para testing)

### Hardware Recomendado

- **Máquina local:** 4 CPU cores, 8GB RAM mínimo
- **Máquina usada por el equipo en AWS:** t3.large

### Librerías Python

```bash
pip install psycopg2-binary
pip install psycopg2
pip install python-dotenv
```

---

## Estructura del Proyecto

```
.
├── infra/
│   ├── docker-compose.postgres.yml      # Config PostgreSQL (Primary + 2 Replicas)
│   ├── docker-compose.cockroachdb.yml   # Config CockroachDB (3 nodos)
│   ├── docker-compose.latency.yml       # Config con simulación de latencia
│   └── docker-compose.bonus-cqrs.yml    # Infra para bonus CQRS (write/read + broker)
│
├── scripts/
│   ├── postgres/
│   │   ├── 01-init-primary.sql           # Inicialización tablas primarias
│   │   ├── 02-distributed-transactions.sql # 2PC y procedimientos
│   │   ├── 03-data-generation.sql        # Generación de datos sintéticos
│   │   ├── 04-experiments.sql            # Queries de experimentos
│   │   ├── 05-bonus-async-replication.sql # Bonus replicación asincrónica
│   │   └── 06-bonus-saga.sql             # Bonus SAGA con compensaciones
│   │
│   ├── cockroachdb/
│   │   ├── 01-init-cockroachdb.sql       # Inicialización CockroachDB
│   │   ├── 02-data-generation.sql        # Carga de datos
│   │   ├── 03-experiments.sql            # Queries CockroachDB
│   │   └── 04-bonus-quorum-geodistribution.sql # Bonus quorum + geodistribución
│   │
│   └── common/
│       ├── 01-bonus-cqrs-command.sql     # Modelo de escritura CQRS
│       ├── 02-bonus-cqrs-query.sql       # Modelo de lectura CQRS
│       └── monitoring.sql                # Queries de monitoreo para ambos
│
├── data/
│   ├── data_generator.py                 # Generador de datos sintéticos en Python
│   ├── db_helpers.py                     # Utilidades de conexión y testing
│   ├── users.json                        # Datos generados (ejemplo)
│   ├── posts.json
│   └── followers.json
│
├── experiments/
│   ├── bonus_cqrs_demo.py                # Bonus CQRS end-to-end
│   ├── bonus_async_replication_postgres.py # Benchmark sync vs async en PostgreSQL
│   ├── bonus_saga_postgres.py            # Bonus SAGA en PostgreSQL
│   └── bonus_quorum_geodistribution.ps1  # Bonus quorum/geodistribución
│
├── docs/
│   ├── ARQUITECTURA.md                   # Documentación de arquitectura
│   ├── EXPERIMENTOS.md                   # Detalle de experimentos
│   └── BONUS.md                          # Guía de ejecución de bonus
│
├── Proyecto2.md                          # Requerimientos originales
├── README.md                             # Este archivo
└── TODO.md                               # Plan de trabajo interno
```

---

## Instalación y Configuración

### 1. Clonar el repositorio

```bash
git clone <URL_REPOSITORIO>
cd git_projects
```

### 2. Instalar dependencias

```bash
# Instalar Python dependencies
pip install -r requirements.txt

# Verificar Docker y Docker Compose
docker --version
docker-compose --version
```

### 3. Iniciar PostgreSQL (3 nodos)

```bash
# Levantar contenedores PostgreSQL
docker-compose -f infra/docker-compose.postgres.yml up -d

# Verificar que los contenedores estén corriendo
docker ps

# Ver logs del primary
docker logs postgres-primary

# Acceder al primary
psql -h localhost -U admin -d social_network
```

### 4. Inicializar base de datos PostgreSQL

```bash
# Desde dentro de psql o usando psql directamente:
psql -h localhost -U admin -d social_network -f scripts/postgres/01-init-primary.sql

# Generar datos de prueba
psql -h localhost -U admin -d social_network -f scripts/postgres/03-data-generation.sql

# Ejecutar: SELECT fn_generate_users(10000);
psql -h localhost -U admin -d social_network -c "SELECT fn_generate_users(10000);"
```

### 5. Iniciar CockroachDB (3 nodos)

```bash
# Levantar contenedores CockroachDB
docker-compose -f infra/docker-compose.cockroachdb.yml up -d

# Esperar a que el cluster esté listo

# Verificar estado del cluster
docker exec -it cockroach-node1 ./cockroach node status --insecure --host=localhost:26257

# Acceder a la interfaz web (UI)
# http://localhost:8080 (node1), http://localhost:8081 (node2), etc.
```

### 6. Inicializar base de datos CockroachDB

```bash
# Ejecutar scripts de inicialización
docker exec -it cockroach-node1 ./cockroach sql --insecure --host=localhost:26257 < scripts/cockroachdb/01-init-cockroachdb.sql

# Generar datos
docker exec -it cockroach-node1 ./cockroach sql --insecure --host=localhost:26257 < scripts/cockroachdb/02-data-generation.sql
```

### 7. Ejecutar Bonus Track

```bash
# CQRS (comando/consulta con dos bases)
docker compose -f infra/docker-compose.bonus-cqrs.yml up -d
python experiments/bonus_cqrs_demo.py

# SAGA en PostgreSQL
psql -h localhost -U admin -d social_network -f scripts/postgres/06-bonus-saga.sql
python experiments/bonus_saga_postgres.py

# Replicación asincrónica PostgreSQL
psql -h localhost -U admin -d social_network -f scripts/postgres/05-bonus-async-replication.sql
python experiments/bonus_async_replication_postgres.py

# Quórum y geodistribución CockroachDB (PowerShell)
./experiments/bonus_quorum_geodistribution.ps1
```

Detalles completos en `docs/BONUS.md`.

---

## Ejecución de Experimentos

### CockroachDB - Experimento 1: Latencia Base

```bash
cd experiments
python exp1_latency_crdb.py

# Resultado observado (2026-04-12):
# - Write mean: 10.31 ms
# - Read mean: 4.18 ms
```

### CockroachDB - Experimento 2: Transacciones Distribuidas ACID

```bash
python exp2_transactions_crdb.py

# Resultado esperado:
# - Caso exitoso con COMMIT
# - Caso con error simulado y ROLLBACK automático
```

### CockroachDB - Experimento 3: Distribución de Rangos

```bash
python exp3_ranges_distribution.py

# Resultado esperado:
# - Conteo de ranges por tabla
# - Evidencia de auto-sharding administrado por el motor
```

### PostgreSQL - Experimento 3: Replicación Sync vs Async

```bash
python exp3_replication_sync.py

# Resultado esperado:
# - Latencia mayor con synchronous_commit=ON
# - Trade-off entre consistencia y performance
```

### PostgreSQL - Experimento 4: Transacciones Distribuidas (2PC)

```bash
python exp4_distributed_transactions.py
```

### PostgreSQL - Experimento 5: Failover y Recuperación

```bash
python exp5_failover_recovery.py

# Proceso:
# 1. Simular caída del nodo primario
# 2. Promover una réplica a primaria
# 3. Medir tiempo de recuperación
# 4. Verificar no hay split-brain
```

### Experimento 6: Comparación PostgreSQL vs CockroachDB

```bash
python exp6_comparison.py

# Exporta:
# - docs/images/latency_comparison.png
# - docs/images/throughput_scalability.png
# - docs/results/exp6_comparison.json
```

---

## Resultados y Análisis

### Métricas Principales

| Métrica | PostgreSQL | CockroachDB | Observación |
|---------|-----------|------------|-------------|
| Latencia Write (ms) | 5-15 | 15-25 | CockroachDB: overhead por coordinación Raft |
| Latencia Read (ms) | 2-8 | 10-20 | PostgreSQL: más rápido si no hay joins inter-shard |
| Latencia Join Inter-shard (ms) | 100-500+ | 50-200 | CockroachDB: mejor optimizer distribuido |
| Escalabilidad Horizontal | Manual | Automática | CockroachDB: redimensionamiento sin intervención |
| Transacciones 2PC (ms) | 50-200+ | Nativo (30-100) | CockroachDB: transacciones distribuidas nativas |
| Failover (segundos) | Manual (~60-300) | Automático (10-30) | CockroachDB: más rápido y automático |

### Gráficos de Resultados

![Comparación de Latencia](docs/images/latency_comparison.png)
*Comparativa de latencia en escritura, lectura y joins distribuidos.*

![Escalabilidad Throughput](docs/images/throughput_scalability.png)
*Escalabilidad de Transacciones por Segundo (TPS).*

### Artefactos de Resultados

- `docs/results/exp6_comparison.json`
- `docs/EXPERIMENTOS.md` (registro de ejecuciones y observaciones)
- `docs/PRESENTACION_FINAL.md` (guion final de presentacion)

---

## Notas Importantes

### PostgreSQL

- **No es distribuido nativamente:** requiere lógica manual en aplicación
- **2PC es blocking:** el coordinador debe mantener locks
- **Más rápido** para operaciones simples sin cross-shard
- **Familiar** para equipos de SQL tradicional

### CockroachDB

- **Distribuido nativo:** transparente para aplicación
- **ACID distribuido:** garantiza consistencia fuerte
- **Escalable automático:** sharding transparente
- **Latencia base más alta:** por coordinación Raft
- **Menos maduro** en algunos aspectos vs PostgreSQL

### Trade-offs CAP

- **PostgreSQL:** Elige C (Consistency) sobre A (Availability) - requiere coordinación 2PC
- **CockroachDB:** Intenta balancear, pero en partición de red elige C

### PACELC

- **PostgreSQL:** En Partition: A+L / Normal: C+L 
- **CockroachDB:** En Partition: C+L / Normal: C+L (consistency siempre)

---

## Equipo

Trabajo desarrollado de forma colaborativa por el grupo del curso.

---

## Recursos Adicionales

- **PostgreSQL Partitioning:** https://www.postgresql.org/docs/current/ddl-partitioning.html
- **PostgreSQL 2PC:** https://www.postgresql.org/docs/current/sql-prepare-transaction.html
- **CockroachDB Docs:** https://www.cockroachlabs.com/docs/
- **CockroachDB Architecture:** https://www.cockroachlabs.com/docs/stable/architecture/overview.html
- **CAP Theorem:** https://en.wikipedia.org/wiki/CAP_theorem
- **PACELC Theorem:** https://en.wikipedia.org/wiki/PACELC_theorem

---

**Fecha de Entrega:** [Completar con fecha del curso]

**Versión:** 1.0 - Inicialización del proyecto

