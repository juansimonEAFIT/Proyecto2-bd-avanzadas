**SI3009 Bases de datos Avanzadas, 2026-1**

**Ingeniería de Sistemas**

**Proyecto 2:**

**Arquitecturas Distribuidas: Escalabilidad, Replicación, Consistencia y Transacciones Distribuidas**

**1\. Introducción**

A lo largo de la unidad 2, se han visto temas fundamentales en los sistemas distribuidos y en especial en las bases de datos, aspectos como Escalabilidad, Particionamiento, Replicación, Consistencia de datos y Transacciones distribuidas forman parte integral de la problemática y solución. Inclusive, incorporando temas de la unidad 1 relacionados con la optimización se ven altamente impactadas por los temas vistos en este unidad 2.

Igualmente a lo largo de las semanas y temas de esta unidad, se han enunciado diferentes laboratorios, para que los estudiantes afiancen sus conocimientos y proyecten su aplicación, igualmente formando una visión crítica de que no todo lo distribuido necesariamente será mejor.

El reto de las bases de datos modernas no es solo mantener la integridad (ACID), sino gestionar volúmenes masivos de datos mediante la distribución física (particionamiento), que favorecen tambien temas de rendimiento, pero a su vez aumentan la complejidad de los sistemas conllevando temas como la inconsistencia de datos, fallos, retos de las transacciones distribuidas entre otras.

Por lo tanto, es el objetivo de este trabajo, que el grupo de estudiantes diseñe e implemente una arquitectura de datos donde la escalabilidad (particionamiento) y la disponibilidad (replicación) coexistan con la integridad (transacciones y consistencia), identificando los compromisos (trade-offs) técnicos según los modelos CAP y PACELC que implican bases de datos 'clasicas' vs newSQL, que contendrá entre otros, los siguientes requerimientos:

- Aplicar escalamiento horizontal de las bases datos
- Implementar Particionamiento Horizontal (Sharding) para distribuir la carga de trabajo, a nivel de tabla, registro y columna de una forma transparente para las aplicaciones usuarias.
- Configurar esquemas de Replicación (Líder-Seguidor) y evaluar su impacto en la latencia, disponibilidad y consistencia.
- Realizar la experimentación con bases de datos clásicas como Postgresql en una configuración multinodo real con al menos 3 instancias EC2 en Amazon o GCP.
- Realizar la experimentación con bases de datos clásicas como Postgresql como un servicio administrado en Nube, podrá usar AWS academy con las limitaciones que representa, o una nube con GCP o inclusive Azure.
- Realizar la experimentación y configuración de una base de datos distribuida NewSQL como Cockroach, DBYugabyte, CoachDB, voltDB
- En sintesis, realizar un analisis e impacto en cada una de las dimensiones fundamentales de las bases de datos distribuidas: escalabilidad, particionamiento, replicaciones, consistencia, disponibilidad, transacciones distribuidas, etc tanto para un motor clasico como Postgresql como un motor NewSQL.

**2\. Objetivo**

Diseñar, implementar y evaluar una arquitectura de base de datos distribuida que permita analizar los trade-offs entre:

- Escalabilidad (particionamiento)
- Disponibilidad (replicación)
- Consistencia (ACID vs eventual)

Comparando:

- Un motor **SQL clásico (PostgreSQL)**
- Un motor **NewSQL distribuido (CockroachDB / YugabyteDB / etc)**

**3\. Contexto del problema**

Cada grupo de estudiantes debe seleccionar un dominio de aplicación de su interés donde aplique los diferentes requerimientos del proyecto2, dominios como:

- Ecommerce (pedidos, pagos, catálogo)
- Banca (cuentas y transferencias)
- Redes sociales (posts, likes, comentarios)
- IoT (sensores)

Deberán definir:

- Contexto
- Modelo de datos
- Volumenes estimados, para los datasets de trabajo, deberán utilizar generados de datos sintéticos como se han realizado en laboratorios y trabajos anteriores.
- Operaciones OLTP y OLAP

**4\. Requerimientos técnicos específicos:**

**4.1 Experiencia en PostgreSQL:** Enfrentar la complejidad de distribución de datos en un motor que no es distribuido de forma nativa

Ambiente: Configurar 3 instancias independientes de PostgreSQL, ideal en 3 máquinas virtuales diferentes.

- Configuración de Particionamiento:
  - Crear una tabla de gran volumen (ej. Transacciones_Log) y particionarla por Rango (fecha), Hash (ID de usuario) o List (tipo) en al menos 3 nodos de PostgreSQL vs newSQL
- Implementar la lógica de enrutamiento: ¿Cómo sabe la aplicación en qué nodo reside el dato? Y como se enruta o se logra la transparencia en una base de datos newSQL
- El Reto del Join Distribuido:
  - Realizar una consulta que requiera cruzar datos de dos particiones diferentes. Deben documentar el impacto en el rendimiento y la complejidad de mantener la Atomicidad cuando una transacción afecta a múltiples fragmentos (aplicando 2PC). Ver con EXPLAIN y EXPLAIN ANALYZE. Y como facilita o no en una newSQL
- Transacciones distribuidas (2PC):
  - Realizar una operación que afecte a dos nodos diferentes (ej. transferencia entre cuentas en distintos shards) y ejecutar manualmente las fases de PREPARE TRANSACTION y COMMIT PREPARED
  - Consideración: ¿Qué sucede si el nodo coordinador falla tras el _Prepare_? (Bloqueo de recursos).
- Disponibilidad y replicación intra base de datos (bonus: y entre bases de datos (CQRS)). Gestión del Fail-over / fail-back ante fallos de lider o replicas.
- Acercamiento Líder-Seguidor:
  - Configurar una instancia Primary (Lectura/Escritura) y dos Replicas (Solo Lectura).
- Replicación Sincrónica vs. Asincrónica:
  - Experimentar con synchronous_commit. Demostrar qué sucede con la latencia de escritura cuando se garantiza que el dato llegó a todas las réplicas. Bonus: Como sería el reto de replicación asincrónica (tendría que usar o no un MOM como rabbitmq, kafka o similar)
- Escenario de Failover:
  - Simular la caída del nodo líder. Se deben realizar un proceso de Promotion (convertir un seguidor en líder) de forma manual o automática y explicar cómo se evita el escenario de Split-brain.
- Bonus: Integración de bases de datos independientes bajo el patrón CQRS:
  - Realizar la simulación de 2 microservicios integrados con el patrón CQRS. Puede usar los ejemplos tipicos de ecommerce con checkout y navegación de catalogo, o register y login/logout para autenticación.

**4.2 Hacia la distribución nativa con newSQL**

Ambiente: Desplegar un cluster de alguna bd newsql como CockroachDB o YugabuteDB de 3 nodos.

Dado una bd newSQL seleccionada, Comparar el esfuerzo manual de las bases de datos 'clasicas' como Postgresql vs un sistema diseñado para la distribución.

- Particionamiento: Distribución Automática:
  - En el clúster NewSQL, cargar datos y observar cómo el motor realiza el Auto-sharding (fragmentación por rangos de llaves).
- Replicación/Raft: Consenso y Localidad:
  - Utilizar el protocolo Raft para entender cómo el sistema decide qué réplica es la "Líder de Rango" (Leaseholder).
  - Reto de Geodistribución: Simular (mediante Docker) latencia entre nodos y observar cómo el sistema mueve las réplicas para acercar los datos a donde más se consultan.
- Gestión de transacciones distribuidas
- Evaluar tolerancia a fallos, fail-over, failback

Retos adicionales: Consistencia y Fallos

- Quórum: Para bases de datos newSQL, configurar el sistema para que el número de nodos activos sea menor al quórum necesario (R+W > N). Experimentar con compromisos (tradeoffs) de si el sistema prefiere ser consistente (Consistencia) o permitir datos inconsistentes (Disponibilidad).
- Simulación de fallos (particionamiento de red) para observar Disponibilidad vs Consistencia (CAP). Revisar herramientas como Pumba o reglas de iptables en red
- Análisis PACELC: Realizar una tabla comparativa final:
  - ¿Cómo maneja cada motor el particionamiento?
  - ¿Cómo se recuperan de una partición de red?
  - ¿Cuál es la penalización de latencia por mantener consistencia fuerte?

**5\. Experimentos**

Cada grupo debe medir, analizar y documentar:

- Latencia Escritura
- Latencia Lectura
- Consistencia
- Impacto en nro de replicas

Finalmente, realizar una comparación entre PostgreSQL y NewSQL, respecto a:

- Particionamiento
- Replicación
- Consistencia
- Latencia
- Manejo de transacciones
- Manejo de fallos
- Complejidad

**3\. Entregables y Criteriors de evaluación**

- Informe en README.md y documentos anexos (10 pags máx)
- Presentación (15 mins)
- Código en github
- Despliegue y Experimentos

**3.1 Entregables en GitHub de cada equipo de trabajo:**

- Directorio /infra: Archivos docker-compose.yaml con la red configurada para simular latencia y particiones.
- Directorio /scripts: Código SQL para la creación de particiones y procedimientos almacenados de 2PC.
- README.md: \* Diagrama de Arquitectura y Documentación: Detalle de replicación de la infraestructura mono-nodo con docker, o entre nodos con varias máquinas virtuales. Visualización y Documentación de detalles técnicos de los motores sobre particionamiento, replicación, consistencia, etc.
- Pruebas EXPLAIN / EXPLAIN ANALYZE cuando se requiera
- Analisis critico del equipo de estudiantes, acerca de la experiencia de aprendizaje, pensamiento crítico sobre la realidad de implementación a nivel industrial de todos los conceptos vistos en la unidad 2, y nivel de consciencia / transparencia que se hacer de estos conceptos en la vida real. Puede usar casos de estudio reales a nivel nacional o internacional para apoyar su analísis crítico.
- Impacto en costos de estas soluciones. No todo lo que brilla es oro.
- Impacto en administración de un sistema de bases de datos distribuida vs una centralizada vs un servicio administrado en nube.

**3.2 Criterios de Calificación:**

| **Componente**         | **Peso** | **Descripción**                                                                                        |
| ---------------------- | -------- | ------------------------------------------------------------------------------------------------------ |
| Implementación técnica | 30%      | Despligue correcto de ambiente postgresql y newsql + datos, transacciones y consultas                  |
| Experimentos           | 30%      | Ejecución, análisis y documentación de los experimentos llevados a cabo en el proyecto                 |
| Análisis de Resultados | 25%      | Solidez, Argumentación y Soporte para Analisis de resultados, y comparación entre ambas bases de datos |
| Presentación           | 15%      | Presentación de máx 20 mins de los Experimentos y Analisis de resultados                               |

20% sobre la nota final: Bonus Track:

Experimentar con transacciones largas o microservicios con patrones SAGA sobre 2PC. Explicar y ejemplarizar este patrón en BD clásicas como Postgresql y newsql.

En sintesis queda como Bonus, y no es parte obligatoria del trabajo2:

- CQRS
- geodistribución
- quorum
- SAGA
- Replicación asincronica