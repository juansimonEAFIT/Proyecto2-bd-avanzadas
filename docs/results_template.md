# Plantilla de resultados de experimentos

Este documento está diseñado para registrar de forma ordenada la ejecución de los experimentos del proyecto. La idea es que, cuando el entorno ya esté desplegado, el equipo solo tenga que seguir cada bloque, ejecutar las pruebas y pegar aquí los resultados obtenidos.

---

# 1. Información general de la ejecución

## Datos básicos

- **Fecha de ejecución:**  
- **Integrantes presentes:**  
- **Motor evaluado:**  
- **Escenario evaluado:**  
- **Ambiente usado:**  
- **Máquina o instancia utilizada:**  
- **Observaciones generales previas:**  

---

# 2. Experimento: Validación del enrutamiento por shard

## Objetivo

Verificar que la lógica de distribución basada en `user_id % 3` envía cada dato al shard correcto.

## Paso a paso

### Paso 1. Seleccionar usuarios de prueba

Registrar los usuarios elegidos para la validación.

| user_id | Cálculo `user_id % 3` | Shard esperado |
|--------|------------------------|----------------|
|        |                        |                |
|        |                        |                |
|        |                        |                |

### Paso 2. Ejecutar consulta o inserción de validación

**Comando o consulta ejecutada:**

```sql
-- Pegar aquí la consulta usada
```

### Paso 3. Registrar resultados observados

| user_id | Shard esperado | Shard encontrado | ¿Coincide? | Observaciones |
|--------|----------------|------------------|------------|---------------|
|        |                |                  |            |               |
|        |                |                  |            |               |
|        |                |                  |            |               |

## Resultado del experimento

- **Resultado general:**  
- **Conclusión breve:**  

---

# 3. Experimento: Latencia de lectura local

## Objetivo

Medir el tiempo de respuesta de consultas ejecutadas en un solo shard.

## Paso a paso

### Paso 1. Registrar la consulta evaluada

```sql
-- Pegar aquí la consulta usada con EXPLAIN ANALYZE
```

### Paso 2. Ejecutar varias veces

| Intento | Nodo | Tiempo reportado | Filas procesadas | Observaciones |
|--------|------|------------------|------------------|---------------|
| 1      |      |                  |                  |               |
| 2      |      |                  |                  |               |
| 3      |      |                  |                  |               |

### Paso 3. Calcular resumen

- **Tiempo mínimo:**  
- **Tiempo máximo:**  
- **Tiempo promedio:**  

## Resultado del experimento

- **Consulta evaluada:**  
- **Comportamiento observado:**  
- **Conclusión breve:**  

---

# 4. Experimento: Join distribuido

## Objetivo

Analizar el impacto de una consulta que cruza información ubicada en distintos nodos.

## Paso a paso

### Paso 1. Registrar la consulta utilizada

```sql
-- Pegar aquí la consulta del join distribuido
```

### Paso 2. Registrar la ejecución con EXPLAIN

**Salida relevante de EXPLAIN:**

```text
Pegar aquí la parte importante de la salida
```

### Paso 3. Registrar la ejecución con EXPLAIN ANALYZE

**Salida relevante de EXPLAIN ANALYZE:**

```text
Pegar aquí la parte importante de la salida
```

### Paso 4. Registrar resultados

| Nodo(s) involucrado(s) | Tiempo total | Costo estimado | Filas procesadas | Observaciones |
|------------------------|--------------|----------------|------------------|---------------|
|                        |              |                |                  |               |

## Resultado del experimento

- **¿La consulta fue exitosa?:**  
- **Complejidad observada:**  
- **Impacto en rendimiento:**  
- **Conclusión breve:**  

---

# 5. Experimento: Transacción distribuida con 2PC

## Objetivo

Evaluar una operación que afecta dos shards diferentes y requiere coordinación manual.

## Caso de prueba

- **Usuario origen:**  
- **Usuario destino:**  
- **Shard origen:**  
- **Shard destino:**  

## Paso a paso

### Paso 1. Ejecutar bloque en el primer shard

**Consulta ejecutada:**

```sql
-- Pegar aquí el bloque ejecutado en el shard origen
```

**Resultado observado:**

```text
Pegar aquí la salida obtenida
```

### Paso 2. Ejecutar bloque en el segundo shard

**Consulta ejecutada:**

```sql
-- Pegar aquí el bloque ejecutado en el shard destino
```

**Resultado observado:**

```text
Pegar aquí la salida obtenida
```

### Paso 3. Registrar fase de prepare

| Nodo | GID de transacción | ¿Prepare exitoso? | Observaciones |
|------|--------------------|-------------------|---------------|
|      |                    |                   |               |
|      |                    |                   |               |

### Paso 4. Registrar fase final

- **¿Se ejecutó `COMMIT PREPARED` o `ROLLBACK PREPARED`?:**  
- **Motivo:**  

### Paso 5. Validar estado final

| Validación | Resultado esperado | Resultado observado | ¿Coincide? |
|-----------|--------------------|---------------------|------------|
| Relación follow registrada | | | |
| following_count actualizado | | | |
| followers_count actualizado | | | |

## Resultado del experimento

- **Resultado general:**  
- **Dificultad observada:**  
- **Conclusión breve:**  

---

# 6. Experimento: Escritura en el nodo primario

## Objetivo

Medir el comportamiento de una escritura realizada en el nodo líder del entorno de replicación.

## Paso a paso

### Paso 1. Registrar la consulta ejecutada

```sql
-- Pegar aquí el INSERT ejecutado en primary
```

### Paso 2. Registrar tiempos

| Nodo | Hora de inicio | Hora de fin | Latencia calculada | Observaciones |
|------|----------------|-------------|--------------------|---------------|
| primary |              |             |                    |               |

### Paso 3. Validar resultado en el primario

```text
Pegar aquí la salida obtenida
```

## Resultado del experimento

- **¿La escritura fue exitosa?:**  
- **Latencia observada:**  
- **Conclusión breve:**  

---

# 7. Experimento: Propagación hacia réplicas

## Objetivo

Verificar si una escritura realizada en el primario se refleja correctamente en las réplicas.

## Paso a paso

### Paso 1. Registrar la escritura origen

- **ID del registro insertado:**  
- **Hora de inserción en primary:**  

### Paso 2. Validar en replica1

| Nodo | ¿Registro visible? | Hora de verificación | Observaciones |
|------|---------------------|----------------------|---------------|
| replica1 |                 |                      |               |

### Paso 3. Validar en replica2

| Nodo | ¿Registro visible? | Hora de verificación | Observaciones |
|------|---------------------|----------------------|---------------|
| replica2 |                 |                      |               |

## Resultado del experimento

- **Consistencia observada entre nodos:**  
- **Diferencia temporal observada:**  
- **Conclusión breve:**  

---

# 8. Experimento: Lectura en réplicas

## Objetivo

Comparar lecturas realizadas en el primario y en las réplicas.

## Paso a paso

### Paso 1. Registrar la consulta evaluada

```sql
-- Pegar aquí la consulta de lectura
```

### Paso 2. Ejecutar en cada nodo

| Nodo | Tiempo reportado | Resultado correcto | Observaciones |
|------|------------------|-------------------|---------------|
| primary  |              |                   |               |
| replica1 |              |                   |               |
| replica2 |              |                   |               |

## Resultado del experimento

- **Nodo con mejor tiempo:**  
- **¿Los resultados coincidieron?:**  
- **Conclusión breve:**  

---

# 9. Experimento: Failover manual

## Objetivo

Evaluar el comportamiento del sistema cuando el nodo primario deja de estar disponible y una réplica es promovida.

## Paso a paso

### Paso 1. Estado inicial del clúster

| Nodo | Rol esperado | Rol observado | Observaciones |
|------|--------------|---------------|---------------|
| primary  | primario |               |               |
| replica1 | réplica  |               |               |
| replica2 | réplica  |               |               |

### Paso 2. Registrar caída del nodo principal

- **Acción realizada para simular la caída:**  
- **Hora de la caída:**  

### Paso 3. Registrar promoción de réplica

- **Nodo promovido:**  
- **Comando usado:**  

```bash
# Pegar aquí el comando ejecutado
```

- **Hora de promoción:**  

### Paso 4. Validar nuevo estado

| Nodo | ¿Está en recuperación? | ¿Acepta escrituras? | Observaciones |
|------|-------------------------|---------------------|---------------|
|      |                         |                     |               |

### Paso 5. Ejecutar escritura de prueba

```sql
-- Pegar aquí la consulta ejecutada después del failover
```

**Resultado observado:**

```text
Pegar aquí la salida obtenida
```

## Resultado del experimento

- **¿El failover fue exitoso?:**  
- **¿Se logró escribir en el nuevo líder?:**  
- **Conclusión breve:**  

---

# 10. Experimento: Comparación final entre motores

## Objetivo

Comparar PostgreSQL y el motor NewSQL elegido respecto a particionamiento, replicación, consistencia, latencia y complejidad.

## Tabla comparativa

| Criterio | PostgreSQL | NewSQL | Observaciones |
|---------|------------|--------|---------------|
| Particionamiento | | | |
| Replicación | | | |
| Consistencia | | | |
| Latencia de lectura | | | |
| Latencia de escritura | | | |
| Transacciones distribuidas | | | |
| Manejo de fallos | | | |
| Complejidad operativa | | | |

## Conclusión comparativa

- **Ventajas observadas en PostgreSQL:**  
- **Ventajas observadas en NewSQL:**  
- **Motor más simple de operar:**  
- **Motor más conveniente para este caso:**  
- **Conclusión final del equipo:**  

---

# 11. Resumen ejecutivo de resultados

## Hallazgos principales

-  
-  
-  

## Dificultades encontradas

-  
-  
-  

## Aprendizajes del equipo

-  
-  
-  