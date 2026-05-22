# Power BI — Instrucciones de Conexión y Publicación

**Persona responsable:** Daniel Arcila (Persona 4)

---

## Prerrequisitos

- Power BI Desktop instalado (última versión desde powerbi.microsoft.com/desktop)
- Acceso al servidor SQL Server en Azure (IP, usuario, contraseña de Persona 1)
- El Data Warehouse `RetailDW` completamente cargado (confirmado por Persona 3)
- Cuenta con Power BI Pro o trial activo (60 días gratuitos)

---

## Paso 1 — Conectar Power BI al Data Warehouse

1. Abrir **Power BI Desktop**
2. Clic en **"Get Data"** → **"SQL Server"**
3. Completar la conexión:
   ```
   Server:   [IP_PUBLICA_VM],1433
   Database: RetailDW
   ```
4. Seleccionar **"Import"** (no DirectQuery)
5. En las credenciales: **Database** → usuario `retail_admin` + contraseña
6. En el **Navigator**, seleccionar **todas** las tablas:
   - ✅ DimFecha, DimGeografia, DimCliente, DimProducto, DimTienda
   - ✅ DimVendedor, DimProveedor, DimCanalVenta, DimPromocion
   - ✅ FactVentas, FactInventarioDiario, FactMetasComerciales, FactDevoluciones
7. Clic en **"Load"** (puede tardar 2-5 minutos con 150K+ filas)

---

## Paso 2 — Configurar el Modelo de Relaciones

Ir a la vista **Model** (ícono de grafo en barra lateral izquierda).

### Relaciones requeridas (todas Many-to-One `*→1`)

| Tabla de Hechos | Campo | → | Dimensión | Campo |
|----------------|-------|---|-----------|-------|
| FactVentas | FechaKey | → | DimFecha | FechaKey |
| FactVentas | ClienteKey | → | DimCliente | ClienteKey |
| FactVentas | ProductoKey | → | DimProducto | ProductoKey |
| FactVentas | TiendaKey | → | DimTienda | TiendaKey |
| FactVentas | VendedorKey | → | DimVendedor | VendedorKey |
| FactVentas | CanalKey | → | DimCanalVenta | CanalKey |
| FactVentas | PromocionKey | → | DimPromocion | PromocionKey |
| FactInventarioDiario | FechaKey | → | DimFecha | FechaKey |
| FactInventarioDiario | ProductoKey | → | DimProducto | ProductoKey |
| FactInventarioDiario | TiendaKey | → | DimTienda | TiendaKey |
| FactMetasComerciales | TiendaKey | → | DimTienda | TiendaKey |
| FactMetasComerciales | VendedorKey | → | DimVendedor | VendedorKey |
| FactMetasComerciales | CanalKey | → | DimCanalVenta | CanalKey |
| FactDevoluciones | FechaKey | → | DimFecha | FechaKey |
| FactDevoluciones | ClienteKey | → | DimCliente | ClienteKey |
| FactDevoluciones | ProductoKey | → | DimProducto | ProductoKey |
| FactDevoluciones | TiendaKey | → | DimTienda | TiendaKey |

### Configurar DimFecha como Date Table
1. Seleccionar la tabla `DimFecha`
2. Pestaña **"Table Tools"** → **"Mark as date table"**
3. Campo de fecha: `Fecha`

---

## Paso 3 — Crear Tabla de Medidas

```dax
_Medidas = ROW("x", 1)
```
Ir a **"Modeling"** → **"New Table"** → escribir la expresión arriba.  
Crear todas las medidas en `_Medidas` (ver `medidas_dax.md`).

---

## Paso 4 — Estructura de las 6 Páginas

### Página 1 — Dashboard Ejecutivo
**Visuals sugeridos:**
- 4 Cards: `Total Ventas`, `Utilidad Bruta`, `Margen Bruto %`, `Cumplimiento Meta %`
- Line chart: Ventas mensuales (año actual vs `Ventas Anio Anterior`)
- Bar chart horizontal: Top 5 tiendas (`Ranking Tienda Ventas ≤ 5`)
- Bar chart horizontal: Top 5 productos (`Ranking Producto Ventas ≤ 5`)
- Gauge: `Cumplimiento Meta %` (min=0, max=1, target=1)
- Slicers: Año (`DimFecha[Anio]`), Región (`DimTienda[Region]`)

### Página 2 — Análisis de Ventas
**Visuals sugeridos:**
- Area chart: `Total Ventas` por `DimFecha[NombreMes]`
- Stacked bar: `Total Ventas` por `DimProducto[Categoria]` y `DimTienda[NombreTienda]`
- Table: Vendedor, `Total Ventas`, `Ranking Tienda Ventas`, `Ticket Promedio`
- Donut: `Total Ventas` por `DimCanalVenta[NombreCanal]`
- Map (si disponible): `Total Ventas` por `DimTienda[Ciudad]`
- Slicers: Período, Tienda, Categoría, Canal

### Página 3 — Inventario
**Visuals sugeridos:**
- 3 Cards: `Inventario Promedio`, `Rotacion Inventario`, Stock actual total
- Bar chart: Top 10 productos con menor `StockFinal` (usar filtro RANKX)
- Line chart: Evolución `Inventario Promedio` por semana
- Matrix: Tienda × Producto → `StockFinal`
- Slicers: Tienda, Categoría, Rango de fechas

### Página 4 — Rentabilidad
**Visuals sugeridos:**
- Clustered bar: Ingresos vs Costos por `DimProducto[Categoria]`
- Scatter plot: `Margen Bruto %` (eje Y) vs `Total Ventas` (eje X) por Producto
- Table: Tienda, Ventas, Costo, Margen, `Margen Bruto %`
- Treemap: `Participacion Ventas %` por Categoría
- Slicers: Período, Categoría, Tienda

### Página 5 — Cumplimiento de Metas
**Visuals sugeridos:**
- Multi-row card: `Cumplimiento Meta %` y `Brecha Meta` por tienda
- Clustered bar: `Total Ventas` vs `Total Meta` por mes
- Matrix: Tienda (filas) × Mes (columnas) → `Cumplimiento Meta %`
  - Aplicar formato condicional con `Color Cumplimiento`
- KPI visual: `Total Ventas` vs `Total Meta`
- Slicers: Año, Tienda, Categoría

### Página 6 — Exploración OLAP
**Visuals sugeridos:**
- Matrix con drill-down: Anio → NombreTrimestre → NombreMes → NombreDia
- Bar chart con drill-through hacia Página 2
- Slicer jerárquico: Categoria → Subcategoria → Producto (usar jerarquía en DimProducto)
- Botones: "Drill Up" / "Drill Down" con acción de página
- Slicers: Canal, Vendedor

---

## Paso 5 — Aplicar Tema Visual

1. Ir a **"View"** → **"Themes"** → **"Customize current theme"**
2. Configurar colores corporativos sugeridos:
   ```
   Color primario:    #1B4F8A  (azul oscuro)
   Color secundario:  #27AE60  (verde)
   Color acento:      #F39C12  (ámbar)
   Fondo:             #F8F9FA  (gris muy claro)
   Texto:             #2C3E50  (azul oscuro casi negro)
   ```
3. Fuente recomendada: **Segoe UI** (nativa de Power BI)

---

## Paso 6 — Publicar en Power BI Service

1. En Power BI Desktop → **"Home"** → **"Publish"**
2. Seleccionar workspace: `Proyecto3-RetailBI` (crear si no existe)
3. En https://app.powerbi.com → **"Datasets"** → dataset `RetailDW`
4. Ir a **"Settings"** → **"Data source credentials"** → editar → ingresar credenciales
5. Para URL pública: **"File"** → **"Embed report"** → **"Publish to web (public)"**
6. Copiar la URL y registrar en `README.md`

---

## Credenciales del servidor (completar)

| Campo | Valor |
|-------|-------|
| IP del servidor | `[COMPLETAR]` |
| Puerto | `1433` |
| Base de datos | `RetailDW` |
| Usuario | `retail_admin` |
| URL Power BI publicada | `[COMPLETAR]` |

---

*Proyecto 3 — Universidad EAFIT — Ingeniería de Sistemas — 2026-1*
