# Proyecto 2: Bases de Datos avanzadas

**Social Network Distributed DB** es un proyecto académico de bases de datos distribuidas que propone el diseño de una arquitectura para una red social universitaria, tomando como caso de estudio un sistema donde los usuarios pueden publicar contenido, comentar, reaccionar con likes y seguir a otros usuarios.

El proyecto tiene como propósito analizar cómo se comporta una arquitectura distribuida cuando debe equilibrar escalabilidad, disponibilidad, consistencia y complejidad operativa dentro de un dominio cercano a la realidad de una aplicación moderna. Para ello, la solución se construye inicialmente sobre PostgreSQL, planteando mecanismos de distribución horizontal, replicación y transacciones distribuidas, con el fin de estudiar de forma práctica los retos de un motor SQL clásico en un entorno multinodo.

## Descripción general

La aplicación modelada corresponde a una red social universitaria llamada **CampusConnect**, en la que la actividad de los usuarios genera un flujo constante de operaciones transaccionales: creación de publicaciones, comentarios, reacciones y relaciones de seguimiento. Este comportamiento convierte a la plataforma en un escenario adecuado para estudiar problemas típicos de las bases de datos distribuidas, como el particionamiento de grandes volúmenes de datos, la necesidad de replicación para mejorar disponibilidad y los compromisos entre consistencia y latencia.

La propuesta se enfoca en construir una arquitectura que permita observar de manera clara las diferencias entre una base de datos centralizada y una arquitectura distribuida. En lugar de asumir que la distribución de datos es transparente, este proyecto la convierte en parte explícita del análisis, mostrando cómo deben diseñarse la lógica de enrutamiento, la coordinación entre nodos y la recuperación ante fallos.

## Objetivo del proyecto

Diseñar una arquitectura de base de datos distribuida para una red social universitaria que permita estudiar el impacto del particionamiento horizontal, la replicación, la consistencia y las transacciones distribuidas en PostgreSQL, y realizar una comparación con un motor NewSQL.

## Problema abordado

En una red social, el crecimiento del número de usuarios y de interacciones genera presión constante sobre el sistema de almacenamiento. A medida que aumentan las publicaciones, los comentarios, los likes y las relaciones entre usuarios, una base de datos centralizada puede convertirse en un cuello de botella en términos de rendimiento, disponibilidad y capacidad de escalar.

Este proyecto aborda ese problema proponiendo una arquitectura distribuida donde los datos no se almacenan en un único nodo, sino que se reparten y replican entre varias instancias de PostgreSQL. A partir de este enfoque, se busca analizar cómo cambia la complejidad del sistema cuando se incorporan mecanismos de sharding manual, replicación líder-seguidor y coordinación de transacciones entre nodos diferentes.

## Arquitectura propuesta

La arquitectura se organiza en dos escenarios principales dentro de PostgreSQL.

El primer escenario corresponde a un modelo de **sharding manual**, en el que la información se distribuye entre tres nodos independientes. Esta parte de la arquitectura está orientada al estudio de la escalabilidad horizontal y del problema del enrutamiento de datos, es decir, cómo se decide en qué nodo debe almacenarse o consultarse cada registro.

El segundo escenario corresponde a un modelo de **replicación líder-seguidor**, en el que un nodo primario recibe escrituras y dos réplicas mantienen copias para lectura y tolerancia a fallos. Este segundo entorno permite analizar el impacto de la replicación sobre la latencia, la disponibilidad del sistema y el comportamiento ante fallos del líder.

De esta forma, la arquitectura no se limita a almacenar datos, sino que constituye un entorno de experimentación para estudiar de manera estructurada los compromisos técnicos que aparecen cuando una base de datos pasa de ser centralizada a distribuida.

## Modelo de datos

El dominio de la red social se representa mediante un conjunto de tablas que modelan las entidades y operaciones principales del sistema:

- `users`
- `posts`
- `comments`
- `likes`
- `follows`
- `interaction_log`
- `experiment_results`

Las tablas `users`, `posts`, `comments`, `likes` y `follows` representan la operación normal de la red social. La tabla `interaction_log` concentra eventos de alto volumen y se convierte en una pieza clave para el análisis de distribución, carga y consultas agregadas. La tabla `experiment_results` permite registrar resultados de pruebas y mediciones realizadas sobre la arquitectura.

## Estrategia de distribución

La arquitectura distribuida plantea una regla de particionamiento horizontal basada en el identificador del usuario. Cada dato se asigna a uno de tres shards según el valor de `user_id % 3`. Esta estrategia permite distribuir la carga de forma sencilla y entendible dentro del contexto académico del proyecto, al mismo tiempo que hace visible una de las principales dificultades de PostgreSQL clásico: la necesidad de que la lógica de distribución sea controlada externamente por la aplicación o por scripts intermedios.

Este enfoque permite estudiar de manera concreta cómo se enrutan operaciones de lectura y escritura, qué ocurre cuando una consulta necesita unir datos repartidos entre nodos diferentes y cómo deben coordinarse operaciones que afectan varias particiones al mismo tiempo.

## Transacciones distribuidas

Uno de los casos más representativos del proyecto es la operación de seguimiento entre usuarios. Cuando un usuario comienza a seguir a otro y ambos pertenecen a shards distintos, la operación deja de ser local y requiere coordinación entre nodos. Esto convierte a la acción de “seguir” en un caso natural para demostrar una transacción distribuida con protocolo de dos fases, evidenciando la complejidad adicional que introduce la distribución en un motor tradicional como PostgreSQL.

## Replicación y disponibilidad

La arquitectura también incorpora un entorno de replicación líder-seguidor para estudiar cómo se propagan las escrituras, cómo se realizan lecturas desde nodos réplica y cómo puede reaccionar el sistema ante la caída del nodo principal. Esta parte del proyecto permite observar de forma práctica la relación entre consistencia, disponibilidad y latencia, así como los retos asociados al failover y a la promoción manual de réplicas.

## Estructura del repositorio

```text
social-network-distributed-db/
│
├── infra/
│   ├── postgres-sharding/
│   │   ├── docker-compose.yml
│   │   ├── shard1/
│   │   │   └── init.sql
│   │   ├── shard2/
│   │   │   └── init.sql
│   │   └── shard3/
│   │       └── init.sql
│   │
│   └── postgres-replication/
│       ├── docker-compose.yml
│       ├── primary/
│       │   ├── postgresql.conf
│       │   └── pg_hba.conf
│       ├── replica1/
│       │   └── setup-replica.sh
│       └── replica2/
│           └── setup-replica.sh
│
├── scripts/
│   ├── create_tables.sql
│   ├── seed_data.sql
│   ├── routing_notes.md
│   ├── distributed_queries.sql
│   ├── two_phase_commit.sql
│   ├── replication_tests.sql
│   └── explain_tests.sql
│
├── docs/
│   ├── architecture.md
│   ├── experiments.md
│   └── results_template.md
│
└── README.md
```
## Integrantes

- Juan Simón Ospina
- Sebastián Durán 
- Daniel Arcila
