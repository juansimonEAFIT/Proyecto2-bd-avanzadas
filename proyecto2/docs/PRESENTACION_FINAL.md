# Presentacion Final - Proyecto 2

## Slide 1 - Portada
- Proyecto 2: Bases de Datos Distribuidas
- Curso: SI3009 Bases de Datos Avanzadas (2026-1)
- Integrantes: Alejandro, Sebastian, Simon, Daniel

## Slide 2 - Problema y Objetivo
- Caso de estudio: Red social con crecimiento horizontal
- Comparar PostgreSQL (sharding/replicacion manual) vs CockroachDB (NewSQL nativo)
- Evaluar latencia, consistencia, operacion y tolerancia a fallos

## Slide 3 - Arquitectura Evaluada
- PostgreSQL: particionamiento manual + replicas + 2PC
- CockroachDB: auto-sharding + consenso Raft + ACID distribuido
- Flujo bonus: CQRS, SAGA, quorum/geodistribucion, async replication

## Slide 4 - Metodologia Experimental
- Exp1/2/3/6 en CockroachDB
- Exp1/2/3/4/5 en PostgreSQL
- Instrumentacion con scripts en `experiments/` y salidas en `docs/results/`
- Graficos finales en `docs/images/`

## Slide 5 - Resultados de Latencia
- CockroachDB Exp1 (2026-04-12): write mean 10.31 ms, read mean 4.18 ms
- PostgreSQL Exp1/Exp3: write primary 235.01 ms, read replica2 234.43 ms, mejora async 56.6%
- CockroachDB: mejor perfil de simplicidad distribuida y consistencia nativa

## Slide 6 - Transacciones Distribuidas
- PostgreSQL 2PC: funcional, pero sensible a bloqueos del coordinador
- CockroachDB: transacciones distribuidas nativas con rollback consistente
- SAGA: alternativa para PostgreSQL cuando se prioriza resiliencia de aplicacion

## Slide 7 - CAP / PACELC
- PostgreSQL: mas flexible en latencia, mayor carga operativa distribuida
- CockroachDB: CP estricto con costo de latencia base
- Validacion de quorum: sin mayoria, CockroachDB rechaza escrituras (consistencia)

## Slide 8 - Bonus CQRS
- Modelo comando y modelo lectura desacoplados
- Proyeccion por eventos validada en demo
- Recomendacion: CockroachDB para write model, PostgreSQL para read model

## Slide 9 - Conclusion y Recomendacion
- CockroachDB recomendado para core transaccional de la red social
- PostgreSQL recomendado para lecturas masivas y analitica
- Arquitectura objetivo: hibrida, orientada a CQRS

## Slide 10 - Evidencia y Cierre
- Documentos: `docs/CAP_PACELC_ANALYSIS.md`, `docs/RESUMEN_EJECUTIVO.md`, `docs/BONUS.md`
- Resultados: `docs/results/exp6_comparison.json`, `docs/results/postgres_explain_analyze.json`
- Graficos: `docs/images/latency_comparison.png`, `docs/images/throughput_scalability.png`, `docs/images/postgres_explain_analyze.png`
