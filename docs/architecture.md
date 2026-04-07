# Arquitectura propuesta para PostgreSQL

## 1. Introducción

Este documento describe la arquitectura propuesta para la fase de PostgreSQL del proyecto de bases de datos distribuidas, usando como dominio de aplicación una red social universitaria. La solución se plantea sobre un escenario realista en el que estudiantes publican contenido, comentan publicaciones, reaccionan con likes y siguen a otros usuarios dentro de una plataforma institucional.

El objetivo de esta arquitectura es permitir la experimentación y el análisis de los principales retos de una base de datos distribuida usando PostgreSQL clásico, especialmente en temas de escalabilidad por particionamiento horizontal, replicación, consistencia y transacciones distribuidas. Este enfoque está alineado con el enunciado del proyecto, que exige trabajar con un motor SQL clásico en configuración multinodo y comparar su comportamiento frente a alternativas NewSQL. 

## 2. Contexto del problema

La aplicación propuesta representa una red social universitaria llamada **CampusConnect**, en la cual los usuarios pueden:

- crear publicaciones,
- comentar publicaciones,
- dar like a publicaciones,
- seguir a otros usuarios,
- y generar eventos de interacción que luego pueden ser analizados.

A medida que el número de usuarios y actividades crece, una arquitectura centralizada empieza a presentar limitaciones en rendimiento, escalabilidad y disponibilidad. Por esta razón, se propone una arquitectura distribuida sobre PostgreSQL, dividida en dos escenarios de experimentación:

1. un escenario de **sharding manual**, orientado a analizar la distribución horizontal de los datos y la complejidad de operar con nodos independientes;
2. un escenario de **replicación líder-seguidor**, orientado a evaluar disponibilidad, latencia de escritura y comportamiento ante fallos.

Esta decisión permite estudiar de forma controlada los trade-offs entre particionamiento, consistencia, disponibilidad y complejidad operativa, que son precisamente algunos de los ejes centrales del proyecto. 

## 3. Objetivo de la arquitectura

La arquitectura busca demostrar, dentro del dominio de redes sociales, cómo PostgreSQL puede ser adaptado para simular una base de datos distribuida, aunque no esté diseñado nativamente para ello.

En particular, se pretende:

- distribuir datos entre varios nodos mediante sharding horizontal;
- implementar una lógica de enrutamiento para decidir a qué nodo pertenece cada dato;
- realizar consultas que crucen datos distribuidos en diferentes nodos;
- demostrar una transacción distribuida con protocolo de dos fases;
- configurar replicación líder-seguidor con un nodo primario y dos réplicas;
- y medir el impacto técnico de estas decisiones en latencia, consistencia y disponibilidad. 

## 4. Vista general de la solución

La arquitectura se divide en dos ambientes independientes dentro del mismo proyecto.

### 4.1 Escenario A: PostgreSQL con sharding manual

Este escenario está compuesto por tres instancias independientes de PostgreSQL:

- `shard_1`
- `shard_2`
- `shard_3`

Cada shard almacena una parte de los datos del sistema según una regla de distribución basada en `user_id`. Aquí no existe distribución automática por parte del motor, por lo que la aplicación o el middleware debe calcular manualmente a qué nodo enviar una operación.

Este ambiente se utiliza para estudiar:

- escalabilidad horizontal,
- distribución de carga,
- joins distribuidos,
- y transacciones distribuidas.

### 4.2 Escenario B: PostgreSQL con replicación líder-seguidor

Este segundo ambiente está compuesto por tres instancias:

- `primary`
- `replica1`
- `replica2`

El nodo primario es responsable de las escrituras y puede atender lecturas. Las réplicas reciben los cambios desde el primario y sirven principalmente para lectura y tolerancia a fallos.

Este ambiente se utiliza para estudiar:

- replicación en PostgreSQL,
- latencia de escritura bajo diferentes configuraciones,
- comportamiento de lecturas desde réplicas,
- failover manual,
- y promoción de un seguidor a líder. 

## 5. Modelo de datos

El modelo de datos propuesto para la red social incluye las siguientes tablas principales:

- `users`
- `posts`
- `comments`
- `likes`
- `follows`
- `interaction_log`
- `experiment_results`

### 5.1 Descripción de cada tabla

#### `users`
Almacena la información básica de cada usuario de la plataforma, incluyendo nombre, facultad, semestre y contadores agregados de seguidores y seguidos.

#### `posts`
Representa las publicaciones creadas por los usuarios. Incluye el texto de la publicación, visibilidad, fecha de creación y contadores de likes y comentarios.

#### `comments`
Registra los comentarios asociados a publicaciones específicas, junto con el autor y la fecha del comentario.

#### `likes`
Almacena las reacciones tipo like que un usuario realiza sobre una publicación.

#### `follows`
Representa la relación entre un usuario que sigue a otro. Esta tabla es especialmente importante para el caso de prueba de transacciones distribuidas.

#### `interaction_log`
Es la tabla de mayor volumen y concentra eventos del sistema como creación de publicaciones, comentarios, likes, follows y otros eventos relevantes. Esta tabla se usará como base principal para análisis de carga y para justificar el particionamiento horizontal.

#### `experiment_results`
Permite registrar resultados de experimentos realizados durante las pruebas, como latencia, tipo de operación, nodo involucrado y observaciones.

## 6. Estrategia de particionamiento

En el escenario de sharding manual, la distribución de los datos se realiza usando una regla basada en el identificador del usuario.

La función de enrutamiento propuesta es:

- si `user_id % 3 = 0`, el dato pertenece a `shard_1`
- si `user_id % 3 = 1`, el dato pertenece a `shard_2`
- si `user_id % 3 = 2`, el dato pertenece a `shard_3`

Esta estrategia fue seleccionada porque es simple, reproducible y fácil de explicar en un entorno académico. También permite distribuir de manera relativamente uniforme los usuarios entre los tres nodos.

### 6.1 Tablas afectadas por la estrategia de enrutamiento

La distribución basada en `user_id` se aplicará principalmente a las tablas cuyo acceso depende directamente del usuario:

- `users`
- `posts`
- `likes`
- `interaction_log`

Para `comments` y `follows`, la ubicación dependerá de la estrategia operacional que se elija en el despliegue. En el caso del proyecto, estas tablas se consideran útiles para mostrar operaciones que pueden involucrar más de un shard.

## 7. Lógica de enrutamiento

Dado que PostgreSQL clásico no incorpora distribución automática entre nodos independientes, la lógica de enrutamiento debe ser implementada explícitamente por la aplicación, por scripts externos o por el componente que haga de intermediario entre el cliente y la base de datos.

El flujo general es el siguiente:

1. la aplicación recibe una operación;
2. identifica el `user_id` principal asociado a esa operación;
3. calcula `user_id % 3`;
4. determina el shard correspondiente;
5. envía la consulta al nodo adecuado.

### 7.1 Ejemplo

Si el usuario 25 crea una publicación:

- se calcula `25 % 3 = 1`;
- por tanto, el dato debe enviarse a `shard_2`;
- la publicación se almacena en ese nodo.

Este mecanismo será documentado también en el archivo `routing_notes.md`, ya que forma parte de los requerimientos de transparencia y enrutamiento mencionados en el proyecto. 

## 8. Join distribuido

Uno de los retos principales del escenario con PostgreSQL clásico es la realización de consultas que cruzan información ubicada en nodos distintos.

En este proyecto, se propone como caso de análisis una consulta que relacione:

- comentarios,
- publicaciones,
- y usuarios.

Por ejemplo, una consulta que recupere el comentario, la publicación asociada y el nombre del usuario que comentó puede requerir datos que residan en nodos diferentes, dependiendo de cómo haya sido distribuida la información.

Este tipo de operación permite evidenciar:

- mayor complejidad de implementación,
- necesidad de mecanismos adicionales para acceso remoto entre nodos,
- y posible impacto negativo en el rendimiento frente a una consulta local.

El proyecto exige precisamente documentar el impacto del join distribuido y analizarlo con `EXPLAIN` y `EXPLAIN ANALYZE`, por lo que esta arquitectura deja preparado ese escenario de prueba. 

## 9. Transacción distribuida

El caso principal de transacción distribuida en esta arquitectura será la operación de **seguir a otro usuario**.

Supóngase el siguiente caso:

- el usuario 10 pertenece a `shard_2`;
- el usuario 12 pertenece a `shard_1`.

Cuando el usuario 10 sigue al usuario 12, la operación requiere:

1. registrar la relación en `follows`;
2. aumentar el contador `following_count` del usuario 10;
3. aumentar el contador `followers_count` del usuario 12.

Como estas acciones afectan nodos diferentes, se requiere coordinación distribuida. Para ello, el proyecto propone usar manualmente el protocolo **Two-Phase Commit (2PC)** mediante:

- `PREPARE TRANSACTION`
- `COMMIT PREPARED`
- o `ROLLBACK PREPARED`

Este caso muestra con claridad una de las limitaciones de PostgreSQL clásico en ambientes distribuidos: la atomicidad entre nodos no es transparente y requiere control explícito. El enunciado solicita justamente realizar una operación de este tipo y discutir qué ocurre si el coordinador falla después de la fase de prepare. 

## 10. Arquitectura de replicación

En el segundo ambiente, la arquitectura se orienta a disponibilidad y tolerancia a fallos mediante un esquema líder-seguidor.

### 10.1 Componentes

- `primary`: nodo principal que recibe escrituras y puede responder lecturas.
- `replica1`: réplica de solo lectura.
- `replica2`: réplica de solo lectura.

### 10.2 Propósito

Este ambiente permite estudiar:

- cómo se propagan las escrituras desde el primario hacia las réplicas;
- qué efecto tiene la configuración de `synchronous_commit` sobre la latencia de escritura;
- qué diferencias existen entre leer desde el primario y desde una réplica;
- y qué pasos se requieren para promover una réplica a primario en caso de fallo.

### 10.3 Escenario de failover

La arquitectura contempla la simulación de la caída del nodo líder y la promoción manual de una réplica. Esto permitirá documentar:

- cómo detectar el fallo,
- cómo promover una réplica,
- cómo validar que el nodo promovido ya no está en modo recuperación,
- y cómo evitar condiciones de inconsistencia o split-brain durante la transición. 

## 11. Componentes del repositorio y relación con la arquitectura

La arquitectura propuesta se encuentra organizada dentro del repositorio de la siguiente manera:

- `infra/postgres-sharding/`: contiene los archivos de despliegue para el ambiente de sharding.
- `infra/postgres-replication/`: contiene los archivos de despliegue para el ambiente de replicación.
- `scripts/create_tables.sql`: define el esquema lógico.
- `scripts/seed_data.sql`: carga datos sintéticos.
- `scripts/distributed_queries.sql`: contiene las consultas de análisis.
- `scripts/two_phase_commit.sql`: documenta el caso de transacción distribuida.
- `scripts/replication_tests.sql`: reúne las pruebas del ambiente líder-seguidor.
- `scripts/explain_tests.sql`: contiene consultas para análisis con `EXPLAIN` y `EXPLAIN ANALYZE`.

Esta separación facilita que la infraestructura, la lógica SQL y la documentación técnica permanezcan claramente delimitadas.

## 12. Ventajas y limitaciones de la propuesta

### 12.1 Ventajas

La arquitectura propuesta tiene varias ventajas para un proyecto universitario:

- es realista dentro del dominio de redes sociales;
- permite demostrar de forma clara el concepto de sharding manual;
- hace evidente la necesidad de enrutamiento externo;
- permite construir un caso concreto de 2PC;
- y facilita una comparación posterior contra una solución NewSQL.

### 12.2 Limitaciones

También presenta limitaciones que son parte importante del análisis:

- PostgreSQL no distribuye automáticamente los datos entre nodos;
- los joins distribuidos requieren trabajo adicional;
- la integridad entre nodos no puede delegarse completamente al motor local;
- la coordinación de transacciones distribuidas es compleja;
- y la administración general del sistema distribuido aumenta considerablemente frente a una base centralizada.

Estas limitaciones no son un error del diseño, sino parte del valor del experimento, ya que permiten evidenciar los compromisos técnicos de usar un motor clásico para resolver problemas distribuidos. 

## 13. Conclusión

La arquitectura propuesta para PostgreSQL permite abordar de forma estructurada los requerimientos del proyecto dentro del dominio de una red social universitaria. La separación entre un ambiente de sharding manual y un ambiente de replicación líder-seguidor facilita estudiar de manera independiente los problemas de escalabilidad, consistencia, disponibilidad y transacciones distribuidas.

Este diseño no busca ocultar la complejidad de PostgreSQL en escenarios distribuidos, sino exponerla deliberadamente para que pueda ser analizada y comparada con la experiencia posterior en un motor NewSQL. De esta forma, la arquitectura cumple no solo una función técnica, sino también pedagógica y experimental, en coherencia con los objetivos del proyecto. 