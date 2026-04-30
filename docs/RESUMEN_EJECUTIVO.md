# Resumen Ejecutivo: Proyecto 2 - Bases de Datos Distribuidas

## Visión General
El proyecto tuvo como objetivo comparar la arquitectura de una **Red Social** implementada en un motor relacional clásico (**PostgreSQL**) configurado manualmente para la distribución, frente a un motor **NewSQL** nativo (**CockroachDB**).

## Hallazgos Clave

### 1. Facilidad de Implementación
- **PostgreSQL**: Requirió una gestión compleja de disparadores (triggers), esquemas de particionamiento manual y una capa de aplicación consciente de la distribución.
- **CockroachDB**: La distribución fue totalmente transparente para la aplicación. El "Auto-sharding" eliminó la necesidad de definir particiones manuales.

### 2. Rendimiento (Latencia)
- En operaciones **Intra-shard**, PostgreSQL fue superior (~2-5ms) vs CockroachDB (~10-15ms).
- En operaciones **Inter-shard** (Joins complejos), CockroachDB demostró un optimizador distribuido más eficiente, evitando la materialización pesada en el coordinador que penaliza a Postgres.

### 3. Confiabilidad y Transacciones
- **CockroachDB** garantiza transacciones ACID distribuidas de forma nativa sin riesgo de bloqueos prolongados.
- **PostgreSQL** mediante 2PC (Two-Phase Commit) es funcional pero vulnerable a bloqueos si el nodo coordinador falla entre las fases.

### 4. Complejidad vs Madurez Arquitectónica (SAGA y CQRS)
- Como se evaluó en la fase "Bonus", implementar patrones como **SAGA** sobre PostgreSQL resuelve el problema de bloqueos 2PC, pero aumenta exponencialmente la complejidad del código. CockroachDB ofrece esos beneficios fuera de la caja.
- Al aislar lecturas y escrituras (**CQRS**), PostgreSQL asíncrono se muestra imbatible como réplica de lectura para el News Feed, mientras CockroachDB sería óptimo para absorber la criticidad transaccional.

## Recomendación Final
Para el desarrollo de la Red Social:
- **CockroachDB** es la plataforma ideal en la capa transaccional principal, gracias a su escalabilidad lineal, geodistribución y redundancia automática (tolerancia a fallos por quórum). El pequeño "gap" en latencia se compensa con la reducción drástica en costos de mantenimiento (DevOps).
- **Adicionalmente**, se sugiere adoptar un modelo **CQRS** de cara al futuro de la red social, donde CockroachDB sirva como "Write Model" y se proyecten vistas a PostgreSQL (o un ElasticSearch) para servir el "Read Model" masivo reduciendo latencias a nivel de 1-2 milisegundos.

## Estado de Cierre del Entregable (Integrante 4)

Estado al 2026-04-12:
1. Experimentos de CockroachDB ejecutados y documentados (Exp1, Exp2, Exp3, Exp6).
2. Matriz comparativa y graficos exportados en `docs/images/` y `docs/results/`.
3. Bonus integrados en el analisis final: CQRS, geodistribucion/quorum, SAGA y replicacion asincronica.
4. Recomendacion consolidada: arquitectura hibrida CQRS con CockroachDB para comandos criticos y PostgreSQL para lecturas masivas.

## Créditos
- **Integrantes**: Alejandro, Sebastian, Simon, Daniel.
- **Curso**: SI3009 Bases de Datos Avanzadas, 2026-1.
