# Análisis CAP y PACELC: PostgreSQL vs CockroachDB

Este documento analiza los compromisos técnicos (trade-offs) de las dos arquitecturas evaluadas en el Proyecto 2, basándose en los teoremas CAP y PACELC.

## 1. Contexto Teórico

### Teorema CAP
En presencia de una **P**artición de red, un sistema debe elegir entre:
- **C**onsistencia: Todos los nodos ven los mismos datos al mismo tiempo.
- **A**vailability (Disponibilidad): Cada petición recibe una respuesta (éxito/fallo).

### Teorema PACELC
Extiende CAP al estado normal (sin partición):
- **P**artition -> (**A**vailability vs **C**onsistency)
- **E**lse -> (**L**atency vs **C**onsistency)

---

## 2. Análisis por Motor

### PostgreSQL (Arquitectura Sharding + Replicación)
PostgreSQL no es un sistema distribuido nativo, por lo que su comportamiento depende de la configuración:

- **CAP**: En partición de red, PostgreSQL suele ser **CP** (Consistencia sobre Disponibilidad) si se usa 2PC, o **AP** si se permite que los esclavos respondan lecturas stale.
- **PACELC (P-A / E-C)**:
  - **P-A**: Ante un fallo del líder, el sistema queda indispuesto para escritura hasta un failover manual (Prioriza consistencia).
  - **E-L**: Prioriza **Latencia** sobre Consistencia (Replicación Asíncrona por defecto).

### CockroachDB (Arquitectura NewSQL)
Diseñado nativamente para la distribución mediante el protocolo de consenso Raft.

- **CAP**: Es estrictamente **CP**. Si no hay quórum (mayoría de nodos), el sistema deja de aceptar peticiones para evitar el "split-brain" y garantizar la consistencia fuerte.
- **PACELC (P-C / E-C)**:
  - **P-C**: Ante partición, detiene el servicio en el lado minoritario para asegurar consistencia.
  - **E-C**: Incluso en estado normal, el sistema elige **Consistencia** sobre Latencia. Cada escritura debe ser confirmada por el quórum de réplicas antes de retornar éxito.

---

## 3. Matriz de Trade-offs Observados

| Escenario | PostgreSQL | CockroachDB |
|-----------|------------|-------------|
| **Fallo de Nodo Unico** | Requiere failover manual (latencia de gestión). | Recuperación automática via Raft (<30s). |
| **Escritura Normal** | Muy rápida (local). | Más lenta (requiere consenso de red). |
| **Lectura Normal** | Muy rápida (local). | Rápida (desde Leaseholder). |
| **Transacción Dist.** | Bloqueante (2PC). | No bloqueante (Nativa). |

---

## 4. Conclusión Analítica

Mientras que **PostgreSQL** permite "tunear" el sistema para ser increíblemente rápido sacrificando seguridad distribuida, **CockroachDB** garantiza la integridad de los datos por diseño, al costo de una latencia base superior.

Para nuestra **Red Social**, CockroachDB es la opción recomendada para el core de datos (usuarios/seguidores), mientras que PostgreSQL podría ser útil para logs o analítica donde la latencia de ingestión es crítica y la consistencia fuerte no es obligatoria.

---

## 5. Integración Especial (Bonus Track)

Para extender nuestra comparativa hacia arquitecturas más avanzadas, consideramos los siguientes patrones:

### 5.1. Patrón CQRS (Command Query Responsibility Segregation)
En una Red Social madura, mezclar el modelo de lectura (Newsfeed) con el de escritura (Likes/Comments) genera bloqueos. Usando CQRS:
- **CockroachDB**: Sirve excelentemente como la "Single Source of Truth" para comandos gracias a su consistencia fuerte. 
- **PostgreSQL (Replicación Asíncrona)**: Se puede utilizar como el modelo de lectura masivo y rápido, alimentado por un event broker o Kafka, permitiendo que PostgreSQL brille sin cargar la complejidad de las transacciones 2PC en las consultas.

### 5.2. Transacciones: 2PC vs SAGA
Mientras **CockroachDB** resuelve escenarios ACID multi-nodo de forma transparente en su capa de almacenamiento, **PostgreSQL** mediante `PREPARE TRANSACTION` sufre si el coordinador cae (bloqueo total). 
El **Patrón SAGA** mediante microservicios y compensación asíncrona es la solución moderna para usar PostgreSQL descentralizado sin bloquear recursos, aunque transfiere una enorme complejidad de estado a la aplicación. CockroachDB es el ganador rotundo si queremos aliviar la "carga de compensación" técnica.

### 5.3. Impacto de Geodistribución y Quórum
CockroachDB introduce un trade-off fascinante:
- *Geodistribución*: Asigna el **Leaseholder** lo más cerca posible al cliente de origen. Postgres clásico no puede hacer esto sin fragmentar o crear bases de datos independientes por región.
- *Fallo de Quórum*: Si simulamos la caída de dos de tres instancias en un Data Center, CockroachDB detiene en seco las escrituras (Pierde Availability por Consistency). Con Postgres (Master/Slave clásico con async), se puede seguir operando usando un slave degradado si la organización acepta perder unas eventuales escrituras.

### 5.4. Sintesis de resultados bonus (integracion final)

Con base en la ejecucion consolidada de bonus y experimentos comparativos:

1. **CQRS validado**: el flujo comando/consulta desacoplado funciona correctamente y reduce acoplamiento operacional para escalar lecturas.
2. **Async en PostgreSQL**: se observo mejora en latencia media de escritura frente a `synchronous_commit=on` en la corrida registrada.
3. **SAGA en PostgreSQL**: permite evitar el bloqueo operativo del 2PC, pero desplaza complejidad al codigo de aplicacion (orquestacion y compensacion).
4. **Quorum en CockroachDB**: ante perdida de mayoria, las escrituras son rechazadas de forma consistente con CAP (modelo CP).

Decision tecnica integrada:

- Para un core transaccional distribuido de red social, CockroachDB sigue siendo la opcion recomendada por seguridad operativa y consistencia fuerte.
- Para consultas de alto volumen y baja latencia, PostgreSQL en modo de lectura desacoplada (CQRS) es un complemento efectivo.
