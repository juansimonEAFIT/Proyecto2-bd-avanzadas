# Routing Notes

## Propósito

Este archivo documenta la lógica de enrutamiento utilizada en el escenario de sharding manual con PostgreSQL para el proyecto de red social distribuida.

## Regla de distribución

La distribución de los datos se realizará con base en el identificador del usuario (`user_id`), aplicando una función módulo sobre tres nodos.

- Si `user_id % 3 = 0`, el dato se almacena en `shard_1`
- Si `user_id % 3 = 1`, el dato se almacena en `shard_2`
- Si `user_id % 3 = 2`, el dato se almacena en `shard_3`

## Tablas afectadas por la regla

La lógica de enrutamiento se aplicará principalmente a las tablas cuyo acceso depende directamente del usuario:

- `users`
- `posts`
- `likes`
- `interaction_log`

En el caso de `comments` y `follows`, la ubicación puede depender de la estrategia de implementación elegida para mantener cercanía con el usuario o con la publicación relacionada.

## Ejemplos de enrutamiento

- Usuario 10: `10 % 3 = 1` → `shard_2`
- Usuario 12: `12 % 3 = 0` → `shard_1`
- Usuario 25: `25 % 3 = 1` → `shard_2`

Si el usuario 25 crea una publicación, esta debe almacenarse en `shard_2`.

## Operaciones distribuidas

No todas las operaciones quedan contenidas en un único shard. Algunas acciones pueden involucrar varios nodos.

Ejemplo:
Si el usuario 10 sigue al usuario 12:

- el usuario 10 pertenece a `shard_2`
- el usuario 12 pertenece a `shard_1`

En ese caso, la operación requiere coordinación entre nodos, ya que se debe registrar la relación de seguimiento y actualizar contadores en shards diferentes.

## Papel de la aplicación

Dado que PostgreSQL clásico no realiza distribución automática entre nodos independientes, la aplicación o el middleware debe calcular el shard destino antes de ejecutar la operación.

Esto implica que el enrutamiento no es transparente por defecto, sino que debe ser implementado explícitamente.

## Observación

Esta estrategia se adopta para facilitar el análisis del proyecto en PostgreSQL clásico y contrastarlo posteriormente con una base de datos NewSQL, donde el particionamiento y la ubicación de datos suelen manejarse de forma nativa por el motor.