# Justificación del Modelo Dimensional — RetailBI

**Proyecto 3 — Bases de Datos Avanzadas SI3009 (2026-1)**  
**Universidad EAFIT — Ingeniería de Sistemas**

> Este documento responde las preguntas conceptuales del Numeral 5 del enunciado.

---

## 1. Granularidad de cada tabla de hechos

| Tabla de Hechos | Granularidad | Justificación |
|----------------|-------------|--------------|
| **FactVentas** | Una fila por **línea de venta** (producto × cliente × tienda × vendedor × fecha) | Permite análisis al máximo nivel de detalle: qué producto compró quién, dónde y cuándo. Nivel de factura perdería información de mezcla de productos. |
| **FactInventarioDiario** | Una fila por **día × producto × tienda** | El inventario es un estado en un punto del tiempo. La granularidad diaria permite calcular rotación, días de cobertura y detectar quiebres de stock. Granularidad mensual sería insuficiente para operaciones. |
| **FactMetasComerciales** | Una fila por **mes × tienda × categoría** | Las metas se definen mensualmente por sede y categoría. Granularidad más fina (semanal) sería artificial y más gruesa (trimestral) perdería el ciclo de revisión real. |
| **FactDevoluciones** | Una fila por **devolución individual** | Cada devolución tiene un motivo específico y puede corresponder a cualquier producto de la venta original. La granularidad por devolución permite análisis de motivos y productos con alto retorno. |

---

## 2. Clasificación de medidas: Aditivas, Semi-aditivas y No aditivas

### FactVentas
| Medida | Tipo | Justificación |
|--------|------|--------------|
| `ValorVenta` | **Aditiva** | Se puede sumar entre productos, tiendas, fechas y clientes sin distorsión |
| `CostoTotal` | **Aditiva** | Ídem anterior |
| `MargenBruto` | **Aditiva** | Es la diferencia de dos aditivas |
| `Cantidad` | **Aditiva** | Conteo de unidades es sumable en todas las dimensiones |
| `Margen %` (calculado) | **No aditiva** | Es un ratio. Sumar márgenes % de dos productos no da el margen % del conjunto |
| `Ticket Promedio` (calculado) | **No aditiva** | Promedio de promedios no es un promedio. Debe calcularse dividiendo totales |

### FactInventarioDiario
| Medida | Tipo | Justificación |
|--------|------|--------------|
| `Entradas` | **Aditiva** | Las entradas del mes son la suma de entradas diarias |
| `Salidas` | **Aditiva** | Ídem |
| `Ajustes` | **Aditiva** | Puede ser negativo pero es sumable |
| `StockFinal` | **Semi-aditiva** | **No debe sumarse entre fechas** (ver pregunta 4). Sí se puede sumar entre tiendas para el stock total en un día dado |

### FactMetasComerciales
| Medida | Tipo | Justificación |
|--------|------|--------------|
| `ValorMeta` | **Aditiva** | La meta anual es la suma de metas mensuales |
| `Cumplimiento %` (calculado) | **No aditiva** | Ratio calculado dinámicamente |

---

## 3. Problemas de resumibilidad identificados

### Problema 1: StockFinal no es sumable entre fechas
Si se suman los `StockFinal` de enero a diciembre de un mismo producto en una tienda, el resultado es incoherente (estaríamos contando el mismo inventario 12 veces). El stock correcto para un período es el del **último día del período** o el **promedio** del período.

**Solución en DAX:**
```dax
-- INCORRECTO: SUM(FactInventarioDiario[StockFinal]) en un rango de fechas
-- CORRECTO:
Stock Ultimo Dia =
CALCULATE(
    LASTNONBLANK(FactInventarioDiario[StockFinal], 1),
    LASTDATE(DimFecha[Fecha])
)
```

### Problema 2: Margen % como promedio de márgenes
El margen porcentual de una categoría NO es el promedio de los márgenes de sus productos. Debe calcularse dividiendo el margen total entre el ingreso total.

**Solución:** Siempre calcular `DIVIDE([Utilidad Bruta], [Total Ventas])` y nunca hacer `AVERAGE` de márgenes unitarios.

### Problema 3: Metas vs Ventas en diferentes granularidades
Las metas están en `FactMetasComerciales` a nivel mensual, mientras las ventas están en `FactVentas` a nivel de línea. Para comparar cumplimiento se debe agregar ventas al nivel mensual/tienda primero.

---

## 4. Por qué el inventario no debe sumarse a través del tiempo

El inventario es un **stock**, no un flujo. Representa la cantidad de unidades presentes en un momento dado.

**Analogía:** El saldo bancario a fin de mes no es la suma de saldos de todos los días del mes; es el valor del último día.

**En el modelo:**
- `StockFinal` del 31 de enero = inventario al finalizar enero (correcto)
- `SUM(StockFinal)` enero + febrero = inventario del 28 de febrero **contado dos veces** (incorrecto)

**Consecuencia:** Si Power BI suma automáticamente `StockFinal` en un visual con eje de tiempo, el resultado es una sobreestimación masiva del inventario real.

**Tratamiento correcto:**
- Para un punto en el tiempo → usar `StockFinal` del último día
- Para un período → usar `AVERAGEX` del `StockFinal` diario (inventario promedio)
- Las entradas y salidas sí son aditivas en el tiempo (son flujos, no stocks)

---

## 5. Dimensiones con jerarquías

| Dimensión | Jerarquía |
|-----------|-----------|
| **DimFecha** | Año → Trimestre → Mes → Semana → Día |
| **DimGeografia** | Región → Departamento → Ciudad |
| **DimProducto** | Categoría Padre → Categoría → Producto |
| **DimTienda** | Región → Ciudad → Tienda |
| **DimCliente** | Región → Ciudad → Segmento → Cliente |

**Impacto en Power BI:** Estas jerarquías permiten drill-down/drill-up en visuals. Se deben crear explícitamente en el modelo semántico de Power BI.

---

## 6. Dimensiones que podrían implementar SCD Tipo 2

| Dimensión | Atributo que cambia | Motivo SCD2 |
|-----------|--------------------|-|
| **DimCliente** | `Segmento` (VIP → Regular) | El historial de ventas debe analizarse con el segmento que tenía el cliente **en el momento de la compra**, no el actual |
| **DimProducto** | `PrecioLista`, `Categoria` | Si un producto cambia de categoría o de precio de lista, el análisis histórico de margen se distorsiona |
| **DimVendedor** | `TiendaAsignada` | Si un vendedor se traslada de tienda, sus ventas anteriores deben seguir asociadas a su tienda original |

**Implementación SCD2 en el modelo:**  
Se agregaron columnas `FechaInicioSCD`, `FechaFinSCD` y `EsVersionActual` en `DimCliente` y `DimProducto`. El ETL cierra la versión anterior (`FechaFinSCD = hoy`, `EsVersionActual = 0`) e inserta una nueva versión cuando detecta cambios en atributos clave.

---

## 7. Diferencia entre el modelo OLTP y el modelo OLAP

| Aspecto | OLTP (RetailOLTP) | OLAP (RetailDW) |
|---------|------------------|-----------------|
| **Objetivo** | Registrar transacciones (velocidad de escritura) | Analizar datos (velocidad de lectura) |
| **Normalización** | 3FN — sin redundancia | Desnormalizado — redundancia intencional |
| **Cantidad de tablas** | 16 tablas relacionadas | 13 tablas (9 dim + 4 hechos) |
| **Tipo de queries** | INSERT/UPDATE de pocas filas | SELECT de millones de filas con GROUP BY |
| **Claves** | Claves naturales (Documento, SKU, NIT) | Surrogate keys enteras (autoincrement) |
| **Fechas** | DATETIME en cada transacción | DimFecha con atributos calendario |
| **Historial** | Solo estado actual | SCD2 mantiene historia de cambios |
| **Rendimiento** | Muchos índices en FK y UK | Índices en columnas de join (FechaKey, etc.) |
| **Usuarios** | Sistema de punto de venta (POS) | Analistas, gerentes (Power BI) |
| **Volumen por query** | Baja latencia, pocas filas | Alta latencia aceptable, millones de filas |

---

*Proyecto 3 — Universidad EAFIT — 2026-1*
