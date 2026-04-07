# Experimentos

## 1. Propósito

Este documento define la metodología de experimentación del proyecto **Social Network Distributed DB**. Su objetivo es establecer, de forma ordenada y verificable, qué pruebas se realizarán sobre la arquitectura distribuida, qué métricas se recogerán, cómo se interpretarán los resultados y qué evidencia deberá conservarse para el informe final y la sustentación.

La experimentación se divide en dos grandes contextos:

1. PostgreSQL clásico en entorno distribuido manual.
2. Motor NewSQL distribuido para comparación posterior.

Dentro del caso PostgreSQL, los experimentos se organizan en dos escenarios:

- sharding manual entre tres nodos independientes;
- replicación líder-seguidor con un nodo primario y dos réplicas.

## 2. Objetivo general de los experimentos

Evaluar el impacto del particionamiento, la replicación, la consistencia y las transacciones distribuidas sobre una arquitectura de base de datos para una red social universitaria, utilizando métricas observables y comparables entre PostgreSQL y una solución NewSQL.

## 3. Preguntas de análisis

Los experimentos del proyecto buscan responder las siguientes preguntas:

- ¿Cómo cambia la latencia de lectura cuando los datos están distribuidos entre nodos?
- ¿Cómo cambia la latencia de escritura cuando se agrega replicación?
- ¿Qué complejidad adicional introduce PostgreSQL al requerir lógica manual de enrutamiento?
- ¿Cuál es el impacto de un join distribuido frente a un join local?
- ¿Qué comportamiento presenta una transacción distribuida coordinada con Two-Phase Commit?
- ¿Qué ocurre con la disponibilidad del sistema cuando falla el nodo líder?
- ¿Qué diferencias aparecen entre PostgreSQL y una base de datos NewSQL al resolver estos mismos problemas?

## 4. Variables y métricas principales

### 4.1 Variables de configuración

Las variables principales que se tendrán en cuenta durante las pruebas son:

- número de nodos activos;
- tipo de arquitectura evaluada;
- tipo de operación ejecutada;
- volumen de datos cargado;
- configuración de replicación;
- presencia o ausencia de fallo inducido;
- motor de base de datos usado.

### 4.2 Métricas principales

Las métricas obligatorias del proyecto serán:

- latencia de escritura;
- latencia de lectura;
- consistencia observada;
- impacto del número de réplicas.

Adicionalmente, se documentarán:

- tiempo total de ejecución de consultas relevantes;
- costo estimado del plan de ejecución;
- complejidad operativa observada;
- comportamiento ante fallos;
- esfuerzo manual requerido por cada motor.

## 5. Dataset y preparación de datos

El dominio del proyecto corresponde a una red social universitaria. Para las pruebas se utilizarán datos sintéticos generados a partir del modelo definido en el proyecto, incluyendo:

- usuarios;
- publicaciones;
- comentarios;
- likes;
- follows;
- eventos de interacción.

La tabla `interaction_log` será la principal tabla de alto volumen para análisis de carga, distribución y consultas agregadas.

### 5.1 Volumen inicial sugerido

Como línea base de pruebas se trabajará con un dataset inicial compuesto por:

- 300 usuarios;
- 900 publicaciones;
- 1800 comentarios;
- 2700 likes;
- 600 relaciones de seguimiento;
- 6000 eventos en `interaction_log`.

Este volumen sirve como base inicial de validación funcional. Si el despliegue y los recursos disponibles lo permiten, podrán realizarse pruebas adicionales con un volumen mayor.

## 6. Escenarios experimentales

## 6.1 Escenario A: PostgreSQL con sharding manual

En este escenario se utilizarán tres nodos PostgreSQL independientes:

- `shard_1`
- `shard_2`
- `shard_3`

La distribución de datos se realizará de manera manual usando la regla:

- `user_id % 3 = 0` → `shard_1`
- `user_id % 3 = 1` → `shard_2`
- `user_id % 3 = 2` → `shard_3`

Este escenario permitirá estudiar:

- distribución horizontal;
- lógica de enrutamiento;
- consultas entre particiones;
- joins distribuidos;
- transacciones distribuidas con 2PC.

## 6.2 Escenario B: PostgreSQL con replicación líder-seguidor

En este escenario se utilizarán:

- `primary`
- `replica1`
- `replica2`

Este entorno permitirá estudiar:

- propagación de escrituras;
- lectura desde réplicas;
- impacto de la configuración de confirmación de escritura;
- failover;
- validación posterior a promoción de réplica.

## 6.3 Escenario C: Motor NewSQL distribuido

En una fase posterior se desplegará un clúster de una base de datos NewSQL, como CockroachDB o YugabyteDB, para comparar el comportamiento frente a PostgreSQL.

En este escenario se analizará:

- distribución automática;
- replicación nativa;
- manejo de transacciones distribuidas;
- tolerancia a fallos;
- esfuerzo manual requerido;
- comparación de latencias y complejidad.

## 7. Diseño de experimentos para PostgreSQL

## 7.1 Experimento 1: Validación del enrutamiento por shard

### Objetivo

Verificar que la lógica de distribución basada en `user_id` envía los datos al nodo correcto.

### Procedimiento

1. Seleccionar varios usuarios de prueba.
2. Calcular manualmente `user_id % 3`.
3. Insertar o consultar datos asociados al usuario.
4. Confirmar que el dato se encuentra en el shard esperado.

### Evidencia esperada

- capturas o salidas SQL por shard;
- tabla de ejemplos con `user_id`, residuo y shard destino;
- observaciones sobre facilidad o dificultad del proceso.

### Métrica principal

- exactitud del enrutamiento.

## 7.2 Experimento 2: Latencia de lectura local

### Objetivo

Medir el tiempo de respuesta de consultas ejecutadas sobre datos contenidos en un solo nodo.

### Consultas sugeridas

- búsqueda de publicaciones por usuario;
- conteo de eventos por tipo;
- listado de actividad reciente de un usuario.

### Procedimiento

1. Ejecutar consultas locales sobre un shard.
2. Medir tiempo con `EXPLAIN ANALYZE`.
3. Repetir varias veces.
4. Calcular promedio, mínimo y máximo.

### Métricas

- tiempo de ejecución;
- costo estimado;
- cantidad de filas procesadas.

## 7.3 Experimento 3: Join distribuido

### Objetivo

Analizar el impacto de una consulta que deba cruzar información ubicada en diferentes nodos.

### Caso sugerido

Relacionar comentarios, publicaciones y usuarios para reconstruir información de interacción social.

### Procedimiento

1. Seleccionar una consulta que una varias tablas.
2. Ejecutarla en contexto local si aplica.
3. Ejecutarla en el escenario distribuido usando el mecanismo escogido.
4. Comparar tiempos, complejidad y plan de ejecución.

### Evidencia esperada

- consulta utilizada;
- `EXPLAIN`;
- `EXPLAIN ANALYZE`;
- observaciones sobre costo y dificultad de implementación.

### Métricas

- tiempo de ejecución;
- costo del plan;
- número de filas leídas;
- complejidad técnica observada.

## 7.4 Experimento 4: Transacción distribuida con Two-Phase Commit

### Objetivo

Evaluar el comportamiento de una operación que afecta dos shards diferentes.

### Caso de prueba

Operación de seguir a otro usuario cuando ambos usuarios pertenecen a shards distintos.

### Procedimiento

1. Seleccionar dos usuarios ubicados en nodos diferentes.
2. Ejecutar la operación por bloques usando:
   - `BEGIN`
   - cambios en cada nodo
   - `PREPARE TRANSACTION`
   - `COMMIT PREPARED`
3. Verificar el resultado final.
4. Repetir el caso con rollback.
5. Documentar el comportamiento y la coordinación requerida.

### Escenario adicional

Analizar qué ocurriría si el coordinador falla después del `PREPARE TRANSACTION` y antes del commit final.

### Métricas

- éxito o fallo de la operación;
- tiempo total de coordinación;
- complejidad del proceso;
- recursos bloqueados si aplica.

## 7.5 Experimento 5: Latencia de escritura en sharding

### Objetivo

Medir el tiempo de inserción o actualización sobre nodos independientes en el esquema de sharding.

### Procedimiento

1. Ejecutar inserciones de prueba en un shard.
2. Medir duración.
3. Repetir para varios tipos de operación:
   - inserción de publicación;
   - inserción de comentario;
   - actualización de contador;
   - inserción en `interaction_log`.

### Métricas

- tiempo de escritura;
- filas afectadas;
- nodo involucrado.

## 8. Diseño de experimentos para replicación

## 8.1 Experimento 6: Validación del rol de cada nodo

### Objetivo

Confirmar que el sistema distingue correctamente entre nodo primario y nodos réplica.

### Procedimiento

1. Ejecutar consultas de validación sobre cada nodo.
2. Confirmar qué nodos están en modo recuperación.
3. Verificar que solo el primario acepta escrituras.

### Métricas

- estado del nodo;
- modo lectura o escritura.

## 8.2 Experimento 7: Propagación de escritura hacia réplicas

### Objetivo

Observar cuánto tarda una escritura realizada en el primario en hacerse visible en las réplicas.

### Procedimiento

1. Insertar una publicación en el primario.
2. Consultarla inmediatamente en el primario.
3. Verificar su aparición en `replica1`.
4. Verificar su aparición en `replica2`.
5. Registrar el tiempo observado.

### Métricas

- latencia de escritura;
- latencia de visibilidad en réplica;
- consistencia observada entre nodos.

## 8.3 Experimento 8: Lecturas desde réplicas

### Objetivo

Comparar lecturas realizadas desde el primario y desde las réplicas.

### Procedimiento

1. Ejecutar una misma consulta en el primario.
2. Ejecutar la misma consulta en las réplicas.
3. Comparar tiempos y resultados.
4. Verificar si la información ya está sincronizada.

### Métricas

- tiempo de lectura;
- diferencia entre primario y réplicas;
- consistencia del resultado.

## 8.4 Experimento 9: Impacto de la configuración de confirmación de escritura

### Objetivo

Analizar cómo cambia la latencia de escritura según la configuración de confirmación utilizada en PostgreSQL.

### Procedimiento

1. Registrar la configuración activa.
2. Ejecutar varias escrituras.
3. Medir la latencia promedio.
4. Repetir si se decide experimentar con configuraciones distintas.
5. Comparar resultados.

### Métricas

- latencia de escritura;
- variación entre configuraciones;
- interpretación del trade-off entre consistencia y rendimiento.

## 8.5 Experimento 10: Failover manual

### Objetivo

Evaluar el comportamiento del sistema cuando el nodo líder deja de estar disponible.

### Procedimiento

1. Confirmar el estado normal del clúster.
2. Simular la caída del primario.
3. Promover una réplica.
4. Validar que el nodo promovido acepta escrituras.
5. Ejecutar una nueva inserción de prueba.
6. Verificar el nuevo estado del sistema.

### Métricas

- tiempo de recuperación;
- éxito o fallo de la promoción;
- continuidad de operaciones;
- observaciones sobre riesgo de split-brain.

## 9. Experimentos para comparación con NewSQL

## 9.1 Distribución automática

Se evaluará cómo el motor distribuido maneja el auto-sharding sin necesidad de lógica manual externa.

## 9.2 Replicación nativa

Se evaluará cómo se administra la replicación dentro del motor y qué nivel de intervención manual exige frente a PostgreSQL.

## 9.3 Transacciones distribuidas

Se analizará si el motor NewSQL simplifica la coordinación entre nodos para operaciones que afectan varias particiones.

## 9.4 Tolerancia a fallos

Se documentará el comportamiento del sistema cuando uno o más nodos fallen o queden fuera de servicio.

## 9.5 Comparación final

La comparación final entre PostgreSQL y NewSQL se hará respecto a:

- particionamiento;
- replicación;
- consistencia;
- latencia;
- manejo de transacciones;
- manejo de fallos;
- complejidad operativa.

## 10. Forma de medición

Para mantener consistencia metodológica, cada experimento deberá documentarse con la misma estructura.

### 10.1 Datos mínimos por experimento

- nombre del experimento;
- fecha;
- motor utilizado;
- arquitectura utilizada;
- nodo o nodos involucrados;
- consulta u operación ejecutada;
- configuración relevante;
- tiempo de inicio;
- tiempo de fin;
- latencia calculada;
- resultado obtenido;
- observaciones.

### 10.2 Cálculo de latencia

La latencia deberá calcularse como:

`latencia = tiempo_final - tiempo_inicial`

Cuando se use `EXPLAIN ANALYZE`, también deberá registrarse el tiempo real reportado por PostgreSQL para la consulta.

## 11. Evidencias requeridas

Para cada experimento se recomienda guardar:

- consulta o bloque SQL ejecutado;
- salida obtenida;
- capturas de consola o cliente SQL;
- resultado en tabla de apoyo;
- plan de ejecución cuando aplique;
- observaciones técnicas del equipo.

## 12. Formato de registro sugerido

Cada prueba podrá registrarse en una tabla como la siguiente:

| Experimento | Motor | Escenario | Nodo | Operación | Latencia | Resultado | Observaciones |
|------------|------|-----------|------|-----------|----------|-----------|---------------|
| Join distribuido | PostgreSQL | Sharding | shard_1 + shard_2 | SELECT | 0.00 ms | Éxito | Consulta entre dos particiones |
| Escritura en primario | PostgreSQL | Replicación | primary | INSERT | 0.00 ms | Éxito | Validación de propagación |
| Failover manual | PostgreSQL | Replicación | replica1 | Promotion | 0.00 ms | Éxito | Nodo promovido |

## 13. Criterios de análisis

Los resultados no deben limitarse a registrar tiempos. También deberán interpretarse desde las siguientes perspectivas:

- facilidad o dificultad de implementación;
- complejidad administrativa;
- impacto en consistencia;
- comportamiento observado ante fallos;
- esfuerzo manual necesario;
- viabilidad práctica de la solución en contextos reales.

## 14. Análisis crítico esperado

Además de presentar datos y tiempos, el proyecto deberá incluir una reflexión crítica sobre la experiencia de aprendizaje y sobre la diferencia entre una implementación distribuida académica y una implementación industrial real.

En particular, se espera que el análisis final responda preguntas como:

- ¿qué tan complejo fue operar PostgreSQL como sistema distribuido?
- ¿qué partes dependieron de lógica manual?
- ¿qué ventajas aportó la replicación?
- ¿qué dificultades aparecieron al coordinar nodos?
- ¿qué tareas fueron más sencillas en el motor NewSQL?

## 15. Conclusión metodológica

Este documento define la base experimental del proyecto y busca asegurar que todas las pruebas se realicen de forma organizada, comparable y sustentable. Su finalidad no es solo medir tiempos, sino también capturar la complejidad técnica y operativa de una arquitectura distribuida, permitiendo que los resultados finales se analicen con rigor y en relación directa con los objetivos del proyecto.