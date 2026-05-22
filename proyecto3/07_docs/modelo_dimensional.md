# Modelo Dimensional — Diagrama y Descripción

**Proyecto 3 — Bases de Datos Avanzadas SI3009 (2026-1)**  
**Universidad EAFIT — Ingeniería de Sistemas**

---

## Diagrama del Modelo Estrella (FactVentas)

```
                        ┌──────────────────┐
                        │   DimPromocion   │
                        │ PromocionKey  PK │
                        │ NombreCampana    │
                        │ TipoCampana      │
                        │ DescuentoPct     │
                        └────────┬─────────┘
                                 │
          ┌──────────────┐       │       ┌──────────────────┐
          │  DimVendedor │       │       │   DimCanalVenta  │
          │ VendedorKey  │       │       │ CanalKey      PK │
          │ NombreVend.. │       │       │ NombreCanal      │
          │ TiendaAsig.. │       │       │ TipoCanal        │
          └──────┬───────┘       │       └────────┬─────────┘
                 │               │                │
┌────────────┐   │   ┌───────────┴──────────────┐ │  ┌─────────────┐
│  DimFecha  │   │   │       FactVentas          │ │  │  DimCliente │
│ FechaKey PK├───┤   │ FactVentaID  BIGINT PK   ├─┤  │ ClienteKey  │
│ Fecha      │   └───┤ FechaKey     INT FK      │ │  │ Nombre...   │
│ Anio       │       │ ClienteKey   INT FK      ├─┘  │ Segmento    │
│ Trimestre  │       │ ProductoKey  INT FK      │    │ Ciudad      │
│ NombreMes  │       │ TiendaKey    INT FK      ├──┐ └─────────────┘
│ EsFeriado  │       │ VendedorKey  INT FK      │  │
└────────────┘       │ CanalKey     INT FK      │  │ ┌─────────────┐
                     │ PromocionKey INT FK      │  └─┤  DimTienda  │
┌────────────┐       │ ─────────────────────── │    │ TiendaKey PK│
│ DimProducto│       │ Cantidad     ADITIVA     │    │ NombreTienda│
│ProductoKeyP├───────┤ ValorVenta   ADITIVA     │    │ Ciudad      │
│ CodigoSKU  │       │ CostoTotal   ADITIVA     │    │ Region      │
│ Categoria  │       │ Descuento    ADITIVA     │    └─────────────┘
│ Proveedor  │       │ MargenBruto  ADITIVA     │
│ Precio     │       └──────────────────────────┘
└────────────┘
```

---

## Diagrama FactInventarioDiario (Esquema Estrella)

```
              ┌───────────────┐
              │    DimFecha   │
              │  FechaKey  PK │
              └───────┬───────┘
                      │
┌────────────┐         │         ┌────────────┐
│ DimProducto│         │         │  DimTienda │
│ProductoKeyP├─────────┤         ├──────────┐ │
└────────────┘  ┌──────┴──────────────────┐ │ │
                │   FactInventarioDiario  │ │ └─┘
                │ FactInventarioID PK     │ │
                │ FechaKey     FK         │ │
                │ ProductoKey  FK         │ │
                │ TiendaKey    FK      ───┘ │
                │ ─────────────────────     │
                │ StockInicial  ADITIVA      │
                │ Entradas      ADITIVA      │
                │ Salidas       ADITIVA      │
                │ Ajustes       ADITIVA      │
                │ StockFinal    SEMI-ADITIVA │
                └────────────────────────────┘
```

---

## Diagrama FactMetasComerciales

```
┌──────────────┐    ┌────────────────────────┐    ┌──────────────┐
│  DimTienda   │    │   FactMetasComerciales │    │  DimVendedor │
│ TiendaKey PK ├────┤ FactMetaID  PK         ├────┤ VendedorKey  │
└──────────────┘    │ TiendaKey   FK         │    └──────────────┘
                    │ ProductoKey FK         │
┌──────────────┐    │ VendedorKey FK         │    ┌──────────────────┐
│ DimProducto  ├────┤ CanalKey    FK         ├────┤  DimCanalVenta   │
│ ProductoKey  │    │ ─────────────────────  │    │  CanalKey        │
└──────────────┘    │ Anio    (degenerado)   │    └──────────────────┘
                    │ Mes     (degenerado)   │
                    │ ValorMeta  ADITIVA     │
                    └────────────────────────┘
```

---

## Resumen de Dimensiones

| Dimensión | Filas aprox. | Jerarquías | SCD |
|-----------|-------------|-----------|-----|
| `DimFecha` | 1.461 (4 años) | Año→Trim→Mes→Sem→Día | — (estática) |
| `DimGeografia` | ~15 | Región→Depto→Ciudad | Tipo 1 |
| `DimCliente` | ~1.000 | Región→Ciudad→Segmento | **Tipo 2** |
| `DimProducto` | ~200 | CatPadre→Cat→Producto | **Tipo 2** |
| `DimTienda` | 10 | Región→Ciudad→Tienda | Tipo 1 |
| `DimVendedor` | 20 | (plana) | Tipo 1 |
| `DimProveedor` | 20 | (plana) | Tipo 1 |
| `DimCanalVenta` | 5 | TipoCanal→Canal | Tipo 1 |
| `DimPromocion` | ~12 | TipoCampaña→Campaña | Tipo 1 |

---

## Resumen de Tablas de Hechos

| Fact Table | Granularidad | Filas aprox. | Dimensiones |
|-----------|-------------|-------------|-------------|
| `FactVentas` | Línea de venta | ~150.000 | 7 dimensiones |
| `FactInventarioDiario` | Día×Prod×Tienda | ~109.500 | 3 dimensiones |
| `FactMetasComerciales` | Mes×Tienda×Cat | ~960 | 4 dimensiones |
| `FactDevoluciones` | Devolución | ~500 | 4 dimensiones |

---

## Decisiones de Diseño Tomadas

1. **Granularidad de FactVentas por línea** (no por factura): permite analizar rentabilidad por producto y categoría. La agregación a nivel de factura se puede hacer con `DISTINCTCOUNT(NumeroFactura)`.

2. **FactMetasComerciales usa ProductoKey como proxy de CategoriaID**: no existe una DimCategoria independiente; la categoría se accede a través de `DimProducto[Categoria]`. Esto simplifica el modelo a costa de requerir filtros correctos en DAX.

3. **Fila "DESCONOCIDO" (-1) en todas las dimensiones**: cualquier surrogate key que no se resuelva en el ETL apunta a -1, evitando NULLs en las claves foráneas y garantizando la integridad referencial del DW.

4. **DimFecha como tabla estática**: generada una sola vez para 4 años, no se recarga en cada ejecución del ETL (salvo para agregar nuevos años).

5. **FactInventarioDiario limitado a 30 productos × 10 tiendas**: el inventario diario completo (200 productos × 10 tiendas × 365 días = 730.000 filas/año) puede ser inmanejable en Azure con VM pequeña. Se amplía fácilmente modificando el script `03_generate_data.sql`.

---

*Proyecto 3 — Universidad EAFIT — 2026-1*
