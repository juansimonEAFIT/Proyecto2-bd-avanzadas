# Medidas DAX — RetailBI

**Persona responsable:** Daniel Arcila (Persona 4)  
**Archivo Power BI:** `RetailBI.pbix`  
**Tabla de medidas:** `_Medidas`

> Crear una tabla vacía en Power BI: `_Medidas = ROW("x", 1)`  
> Todas las medidas van en esa tabla para mantener el modelo organizado.

---

## 📦 Grupo 1 — Medidas Base de Ventas

### 1. Total Ventas
```dax
Total Ventas = SUM(FactVentas[ValorVenta])
```
**Tipo:** Aditiva | **Uso:** KPI principal en todas las páginas.

---

### 2. Total Costo
```dax
Total Costo = SUM(FactVentas[CostoTotal])
```
**Tipo:** Aditiva | **Uso:** Cálculo de rentabilidad.

---

### 3. Utilidad Bruta
```dax
Utilidad Bruta = [Total Ventas] - [Total Costo]
```
**Tipo:** Aditiva | **Uso:** KPI de rentabilidad.

---

### 4. Margen Bruto %
```dax
Margen Bruto % = DIVIDE([Utilidad Bruta], [Total Ventas], 0)
```
**Tipo:** No aditiva (ratio) | **Formato:** Porcentaje con 1 decimal.

---

### 5. Cantidad Vendida
```dax
Cantidad Vendida = SUM(FactVentas[Cantidad])
```
**Tipo:** Aditiva | **Uso:** Análisis de volumen.

---

### 6. Ticket Promedio
```dax
Ticket Promedio =
DIVIDE(
    [Total Ventas],
    DISTINCTCOUNT(FactVentas[NumeroFactura]),
    0
)
```
**Tipo:** No aditiva | **Uso:** KPI de valor promedio por transacción.

---

## ⏱️ Grupo 2 — Inteligencia de Tiempo

### 7. Ventas Año Anterior
```dax
Ventas Anio Anterior =
CALCULATE(
    [Total Ventas],
    SAMEPERIODLASTYEAR(DimFecha[Fecha])
)
```
**Nota:** Requiere que DimFecha esté marcada como *Date Table*.

---

### 8. Crecimiento Ventas %
```dax
Crecimiento Ventas % =
DIVIDE(
    [Total Ventas] - [Ventas Anio Anterior],
    [Ventas Anio Anterior],
    0
)
```
**Formato:** Porcentaje | **Uso:** Comparativo YoY en página ejecutiva.

---

### 9. Ventas YTD (Acumulado del año)
```dax
Ventas YTD =
TOTALYTD([Total Ventas], DimFecha[Fecha])
```
**Uso:** Barras de progreso anual.

---

### 10. Promedio Móvil 3 Meses
```dax
Promedio Movil 3M =
CALCULATE(
    [Total Ventas],
    DATESINPERIOD(
        DimFecha[Fecha],
        LASTDATE(DimFecha[Fecha]),
        -3,
        MONTH
    )
) / 3
```
**Uso:** Línea de tendencia suavizada.

---

## 🎯 Grupo 3 — Metas Comerciales

### 11. Total Meta
```dax
Total Meta = SUM(FactMetasComerciales[ValorMeta])
```
**Tipo:** Aditiva | **Uso:** Comparativo ventas vs meta.

---

### 12. Cumplimiento Meta %
```dax
Cumplimiento Meta % =
DIVIDE([Total Ventas], [Total Meta], 0)
```
**Formato:** Porcentaje | **Uso:** Gauge de cumplimiento, semáforo.

---

### 13. Brecha Meta
```dax
Brecha Meta = [Total Ventas] - [Total Meta]
```
**Tipo:** Aditiva (puede ser negativa) | **Formato:** Moneda COP.

---

## 📦 Grupo 4 — Inventario

### 14. Inventario Promedio
```dax
Inventario Promedio =
AVERAGEX(
    FactInventarioDiario,
    FactInventarioDiario[StockFinal]
)
```
**Tipo:** Semi-aditiva (promedio, no suma entre fechas) | **Uso:** KPI de inventario.

---

### 15. Rotación de Inventario
```dax
Rotacion Inventario =
DIVIDE([Total Costo], [Inventario Promedio], 0)
```
**Tipo:** No aditiva (ratio) | **Uso:** Eficiencia de inventario (veces/período).

---

## 🏆 Grupo 5 — Ranking y Participación

### 16. Ranking Producto Ventas
```dax
Ranking Producto Ventas =
RANKX(
    ALL(DimProducto[NombreProducto]),
    [Total Ventas],
    ,
    DESC,
    DENSE
)
```
**Uso:** Top productos en tablas y gráficos.

---

### 17. Ranking Tienda Ventas
```dax
Ranking Tienda Ventas =
RANKX(
    ALL(DimTienda[NombreTienda]),
    [Total Ventas],
    ,
    DESC,
    DENSE
)
```
**Uso:** Comparativo de tiendas.

---

### 18. Participación Ventas %
```dax
Participacion Ventas % =
DIVIDE(
    [Total Ventas],
    CALCULATE([Total Ventas], ALL(DimProducto)),
    0
)
```
**Uso:** Treemap y gráficos de participación.

---

## 📉 Grupo 6 — Devoluciones

### 19. Total Devoluciones
```dax
Total Devoluciones = SUM(FactDevoluciones[ValorDevuelto])
```

---

### 20. Tasa Devolución %
```dax
Tasa Devolucion % =
DIVIDE([Total Devoluciones], [Total Ventas], 0)
```
**Formato:** Porcentaje.

---

## 📊 Medidas Auxiliares para Visualizaciones

### Semáforo Cumplimiento (texto)
```dax
Semaforo Cumplimiento =
SWITCH(
    TRUE(),
    [Cumplimiento Meta %] >= 1.0,  "🟢 Cumplido",
    [Cumplimiento Meta %] >= 0.85, "🟡 En riesgo",
    "🔴 Incumplido"
)
```

### Color Cumplimiento (para formato condicional)
```dax
Color Cumplimiento =
SWITCH(
    TRUE(),
    [Cumplimiento Meta %] >= 1.0,  "#2ECC71",
    [Cumplimiento Meta %] >= 0.85, "#F39C12",
    "#E74C3C"
)
```

---

## 💡 Notas importantes sobre DAX en este modelo

| Concepto | Aplicación en el modelo |
|----------|------------------------|
| **Context Transition** | Ocurre en `RANKX` y en medidas dentro de `CALCULATE` cuando se usan en tablas con filas |
| **SAMEPERIODLASTYEAR** | Solo funciona si DimFecha está marcada como *Date Table* en Power BI |
| **StockFinal SEMI-ADITIVA** | Usar `AVERAGEX` o `LASTDATE` para inventario, NUNCA `SUM` entre períodos |
| **ALL vs ALLEXCEPT** | `ALL(DimProducto)` en participación elimina el filtro de producto; usar `ALLEXCEPT` si se quiere mantener otro filtro activo |
| **DIVIDE vs /** | Siempre usar `DIVIDE(num, den, 0)` para evitar errores de división por cero |

---

*Proyecto 3 — Universidad EAFIT — 2026-1*
