# Documentación de Arquitectura - Red Social Distribuida

## 1. Visión General

Este documento describe la arquitectura de una red social distribuida implementada con dos motores de base de datos diferentes, permitiendo comparar enfoques centralizados vs distribuidos nativos.

```
┌─────────────────────────────────────────────────────────────┐
│                      APLICACIÓN CLIENTE                      │
│               (Python + psycopg2 + Experimentos)             │
└─────────────────────┬──────────────────────────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
   [PostgreSQL]              [CockroachDB]
   (3 máquinas)              (3 máquinas)
        │                           │
        ├─ Primary                  ├─ Node 1
        ├─ Replica 1                ├─ Node 2
        └─ Replica 2                └─ Node 3
```

---

## 2. PostgreSQL - Enfoque Clásico

### 2.1 Modelo de Sharding

**Estrategia:** Hashing en tabla `users`, rango en tabla `posts`

```
users:
  Shard = user_id % 3
  
  Shard 1 (Nodo Primary):   user_id ∈ {0, 3, 6, 9, ...}
  Shard 2 (Nodo Replica 1): user_id ∈ {1, 4, 7, 10, ...}
  Shard 3 (Nodo Replica 2): user_id ∈ {2, 5, 8, 11, ...}

posts:
  Shard por fecha (rango):
  
  Shard 1: 2026-01-01 a 2026-01-31
  Shard 2: 2026-02-01 a 2026-02-28
  Shard 3: 2026-03-01 a 2026-03-31
```

### 2.2 Estructura de Particiones

```sql
CREATE TABLE users (...)
  PARTITION BY HASH (user_id);
  
  CREATE TABLE users_P1 PARTITION OF users FOR VALUES WITH (MODULUS 3, REMAINDER 0);
  CREATE TABLE users_P2 PARTITION OF users FOR VALUES WITH (MODULUS 3, REMAINDER 1);
  CREATE TABLE users_P3 PARTITION OF users FOR VALUES WITH (MODULUS 3, REMAINDER 2);
```

### 2.3 Replicación Líder-Seguidor

```
               Primary (Nodo 1)
                    │
                    │ WAL (Write-Ahead Log)
                    │
         ┌──────────┴──────────┐
         │                     │
      Replica 1           Replica 2
      (standby)            (standby)
      
    - Writes: Solo en Primary
    - Reads: Puede ser multi-nodo si se replica async
    - Sync mode: synchronous_commit=ON (espera confirmación)
    - Async mode: synchronous_commit=OFF (no espera)
```

### 2.4 Topología de Red

```yaml
Primary (Primary):
  Host: postgres-primary
  Port: 5432
  Role: Read/Write
  Replicación: Envía WAL a replicas
  
Replica 1:
  Host: postgres-replica-1
  Port: 5433
  Role: Read-Only
  Replicación: Recibe WAL, aplica cambios
  
Replica 2:
  Host: postgres-replica-2
  Port: 5434
  Role: Read-Only
  Replicación: Recibe WAL, aplica cambios
```

### 2.5 Transacciones Distribuidas (2PC)

**Problema:** ¿Cómo garantizar atomicidad cuando una transacción afecta múltiples shards?

**Solución:** Two-Phase Commit (2PC)

```
Fase 1 - PREPARE:
  ┌─────────────────────────────────────┐
  │ BEGIN                               │
  │   UPDATE shard_1 ...                │
  │   PREPARE TRANSACTION 'tx_123'      │
  └─────────────────────────────────────┘
           │
           ▼ (si éxito)
  ┌─────────────────────────────────────┐
  │ BEGIN                               │
  │   UPDATE shard_2 ...                │
  │   PREPARE TRANSACTION 'tx_124'      │
  └─────────────────────────────────────┘
           │
           ▼ (si todos PREPARED)

Fase 2 - COMMIT:
  ┌──────────────────────────────────────┐
  │ COMMIT PREPARED 'tx_123'             │
  │ COMMIT PREPARED 'tx_124'             │
  └──────────────────────────────────────┘
```

**Problemas:**
- Recursos bloqueados entre PREPARE y COMMIT
- Split-brain si coordinador falla entre fases
- Latencia: 50-200ms típico

---

## 3. CockroachDB - Distribución Nativa

### 3.1 Auto-Sharding Automático

CockroachDB distribuye automáticamente datos en **ranges** (similares a shards pero gestionados automáticamente).

```
Tabla: users (auto-sharded)

Range 1: user_id ∈ [0, 100,000)        → Node 1
Range 2: user_id ∈ [100,000, 200,000) → Node 2
Range 3: user_id ∈ [200,000, 300,000) → Node 3

El sistema reajusta ranges automáticamente si un nodo crece demasiado.
```

### 3.2 Protocolo Raft para Consenso

```
Líder (Leaseholder):
  ├─ Recibe writes
  ├─ Aplica cambios localmente
  ├─ Envía log entries a seguidores
  │
Seguidores (Followers):
  ├─ Reciben log entries del líder
  ├─ Almacenan en log
  ├─ Envían ACK al líder
  │
Consenso:
  ├─ Cuando N/2+1 nodos (quórum) confirmó = COMMITTED
  ├─ Cambio es durable y visible
```

### 3.3 Replicación Automática

```yaml
Default: 3 réplicas (en 3 nodos distintos)

Para cada range:
  - 1 Leaseholder (líder): recibe writes
  - 2 Followers: reciben replicación
  
La replicación es:
  - Automática
  - Síncrona (garantiza durabilidad antes de ACK)
  - Transparente para la aplicación
```

### 3.4 Transacciones Distribuidas Nativas

```sql
BEGIN TRANSACTION;
  UPDATE users SET followers = followers + 1 WHERE user_id = 1;  -- Puede estar en range 1
  UPDATE users SET following = following + 1 WHERE user_id = 2;  -- Puede estar en range 2
COMMIT;
```

**Cómo funciona:**
1. CockroachDB detecta que afecta múltiples ranges
2. Ejecuta protocolo ACID distribuido internamente (sin API 2PC)
3. Garantiza atomicidad automáticamente
4. Más rápido que 2PC manual (30-100ms vs 50-200ms)
5. Manejo automático de fallos

---

## 4. Modelo de Datos Compartido

### 4.1 Tablas y Relaciones

```
┌─────────────────────────────────────┐
│           USERS (Tabla Central)     │
│  user_id | username | email | ...   │
├─────────────────────────────────────┤
│ (Shard: user_id % 3)                │
└────────┬────────────────────────────┘
         │
    ┌────┴────┐
    │          │
    ▼          ▼
┌────────┐  ┌──────────┐
│ POSTS  │  │FOLLOWERS │
│        │  │          │
│user_id │  │follower_ │
│per     │  │id        │
│        │  │          │
└────┬───┘  └──────────┘
     │
     └─────┬──────┐
           │      │
           ▼      ▼
        ┌──────┐ ┌────────┐
        │COMMS │ │LIKES   │
        │      │ │        │
        └──────┘ └────────┘
```

### 4.2 Distribución

| Tabla | Estrategia | Razón |
|-------|-----------|-------|
| USERS | HASH(user_id) | Acceso por PK, distribución uniforme |
| POSTS | RANGE(created_at), luego HASH | Time-series + distribución |
| COMMENTS | HASH(post_id) | Localidad: comentarios con post |
| LIKES | HASH(post_id) | Localidad: likes con post |
| FOLLOWERS | HASH(follower_id) | Acceso por usuario follower |

---

## 5. Comparación Arquitectónica

### 5.1 Características

| Aspecto | PostgreSQL | CockroachDB |
|--------|-----------|------------|
| **Sharding** | Manual (aplicación) | Automático (sistema) |
| **Replicación** | Master-Slave | Multi-Master (Raft) |
| **Consistencia** | Fuerte (local), eventual (cross-shard) | ACID distribuida |
| **Escalabilidad** | Horizontal (manual) | Horizontal (automática) |
| **Failover** | Manual/Scripts | Automático (<30s) |
| **Latencia Base** | Baja (5-10ms) | Media (15-25ms) |
| **Operacional** | Complejo | Simplificado |

### 5.2 Operaciones Típicas

**Lectura simple (mismo shard):**
```
PostgreSQL: 5-10ms
CockroachDB: 15-20ms
```

**Lectura con JOIN (múltiples shards):**
```
PostgreSQL: 100-500ms (materialización en aplicación)
CockroachDB: 50-200ms (distribuida transparente)
```

**Transacción distribuida (Múltiples shards):**
```
PostgreSQL: 50-200ms (2PC manual, blocking)
CockroachDB: 30-100ms (nativo, no-blocking)
```

---

## 6. Evidencia Práctica: CockroachDB en Producción

### 6.1 Estado del Clúster

```bash
$ docker exec cockroach-node1 cockroach node status --insecure --host=cockroach-node1:26357

id  address            sql_address        build   started_at              updated_at              is_available  is_live
1   cockroach-node1    cockroach-node1    v26.1.2 2026-04-08 17:58:30    2026-04-08 17:58:39     true          true
2   cockroach-node3    cockroach-node3    v26.1.2 2026-04-08 17:58:31    2026-04-08 17:58:37     true          true
3   cockroach-node2    cockroach-node2    v26.1.2 2026-04-08 17:58:31    2026-04-08 17:58:37     true          true
```

**Observación:** 3 nodos activos (is_live = true), listo para producción.

### 6.2 Verificación de Tablas y Datos Cargados

```bash
$ docker exec cockroach-node1 cockroach sql --insecure --host=cockroach-node1:26357 -e "SHOW TABLES FROM defaultdb;"

schema_name  table_name                 type    owner  estimated_row_count  locality
public       comments                   table   root   30000                NULL
public       distributed_transactions   table   root   0                    NULL
public       followers                  table   root   20000                NULL
public       post_likes                 table   root   100000               NULL
public       posts                      table   root   50000                NULL
public       users                      table   root   10000                NULL
```

**Dataset cargado:**
- users: 10,000 registros
- posts: 50,000 registros
- comments: 30,000 registros
- followers: 20,000 registros
- post_likes: 100,000 registros
- **Total: 210,000 registros**

### 6.3 Distribución en Ranges

```bash
$ docker exec cockroach-node1 cockroach sql --insecure --host=cockroach-node1:26357 -e "SHOW RANGES FROM TABLE posts WITH DETAILS;"

start_key              end_key          range_id  range_size_mb  lease_holder  replicas  voting_replicas
<before:/Table/110>    <after:/Max>     83        66.48          1            {1,2,3}  {1,3,2}
```

**Análisis de distribución:**
- **Range ID:** 83 (única tabla, aún sin fragmentación automática)
- **Tamaño:** 66.48 MB (tabla posts es la más grande)
- **Lease Holder:** Nodo 1 (líder del range)
- **Replicas:** {1,2,3} (replicada en todos los nodos)
- **Voting Replicas:** {1,3,2} (orden de votación en Raft)

**Por qué un solo range:**
- El dataset total (~290 MB con overhead) aún está bajo el threshold de auto-split de CockroachDB (~64 GB).
- En producción con millones de registros, verías múltiples ranges con auto-splitting.

### 6.4 Replicación Raft Verificada

Cada range tiene replicación en 3 nodos automatizada:
- Nodo 1: Líder actual (lease_holder)
- Nodo 2,3: Seguidores (replicas voting)

Garantías:
- ✅ Quórum: 2/3 nodos necesarios para commit
- ✅ Durabilidad: Datos replicados en 3 máquinas antes de ACK
- ✅ Consistencia: ACID fuerte garantizada

---

## 7. Flujo de una Operación

### 7.1 PostgreSQL: INSERT con replicación sincrónica

```
1. Aplicación: INSERT INTO users (...) VALUES (...)
2. PostgreSQL Primary:
   - Escribe en WAL (Write-Ahead Log)
   - Espera confirmación de replicas (synchronous_commit=ON)
3. PostgreSQL Replica 1, 2:
   - Reciben WAL
   - Aplican cambios
   - Envían ACK
4. PostgreSQL Primary:
   - Recibe ACKs
   - Completa transacción
5. Aplicación:
   - Recibe confirmación (~10-20ms)
```

### 7.2 CockroachDB: INSERT en range distribuido

```
1. Aplicación: INSERT INTO users (...) VALUES (...)
2. CockroachDB (nodo actual):
   - Determina qué range afecta
   - Enruta a Leaseholder del range
3. Leaseholder:
   - Escribe en log local
   - Envía a Followers
4. Followers:
   - Reciben log entry
   - Replican localmente
   - Envían ACK
5. Leaseholder:
   - Cuando quórum (2/3) confirmó: COMMITTED
   - Completa transacción
6. Aplicación:
   - Recibe confirmación (~15-30ms)
```

---

## 7. Gestión de Fallos

### 7.1 PostgreSQL - Failover Manual

```
Estado Normal:
  Primary (P) → Replica 1 (S1) → Replica 2 (S2)
  
Falla el Primary:
  X (P) → Replica 1 (S1) → Replica 2 (S2)
  
Pasos de Recuperación Manual:
  1. Detectar fallo (alerts, heartbeat)
  2. Elegir nueva primary (usualmente Replica 1)
  3. Ejecutar: SELECT pg_promote(); en Replica 1
  4. Reconfigurar aplicación apunte a Replica 1
  5. Verificar Replica 2 sigue a nueva primary
  6. Recuperar Primary original offline
  
Tiempo: 5-10 mins manual, ~1-2 mins con automatización (Patroni)
```

### 7.2 CockroachDB - Failover Automático

```
Estado Normal:
  Node1 (Leader) ↔ Node2 ↔ Node3
  
Falla Node1:
  X (Leader) ↔ Node2 ↔ Node3
  
Reacción Automática:
  1. Otros nodos detectan que Node1 no responde
  2. Inician elección (Raft consensus)
  3. Node2 (o Node3) gana elección
  4. Nuevo líder comienza a aceptar writes
  5. Sistema sigue functionando
  
Tiempo: <30 segundos
Aplicación: No necesita cambios de conexión (redirects automático)
```

---

## 8. Consideraciones de Costo

### 8.1 PostgreSQL (EC2)

```
Escenario: 3 instancias t2.medium en AWS

Costo mensual:
  - 3x t2.medium: $90/mes (~$0.05/hora)
  - Almacenamiento EBS (100GB): $5/mes
  - Data transfer: $10/mes
  ────────────────
  Total: ~$105/mes

Operación:
  - DBA time: High (manual partitioning, backup, etc)
  - Backup manual: Yes
  - Scaling: Manual (downtime)
```

### 8.2 CockroachDB

```
Escenario: Cluster básico auto-managed

Costo mensual:
  - 3 nodos t2.medium: $90/mes
  - Almacenamiento: $5/mes
  - Backup automático: Incluido
  ────────────────
  Total: ~$95/mes

Operación:
  - DBA time: Low (auto-management)
  - Backup: Automático
  - Scaling: Automático (sin downtime)
```

**Conclusión:** Similar en infraestructura, pero CockroachDB reduce operational overhead.

---

## 9. Recomendaciones de Uso

### 9.1 Usar PostgreSQL cuando:
- Datos no escalables horizontalmente (< 1TB)
- Equipo muy familiarizado con PostgreSQL
- Presupuesto muy limitado
- Tolerancia a complejidad operacional
- No necesita alta disponibilidad automática

### 9.2 Usar CockroachDB cuando:
- Datos crecerán masivamente (> 1TB)
- Necesita disponibilidad automática
- Queremos simplificar operaciones
- Geo-distribución futura
- ACID distribuidas nativas son críticas
- Presupuesto permite software especializado

---

**Versión:** 1.0 | **Última actualización:** Abril 2026

