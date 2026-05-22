-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 03_create_facts.sql
-- Descripción: Crea las 4 tablas de hechos del modelo dimensional.
--   - FactVentas           (granularidad: línea de venta)
--   - FactInventarioDiario (granularidad: día × producto × tienda)
--   - FactMetasComerciales (granularidad: mes × tienda × categoría)
--   - FactDevoluciones     (granularidad: devolución individual)
-- Ejecutar DESPUÉS de 02_create_dimensions.sql
-- ============================================================

USE RetailDW;
GO

-- ============================================================
-- FactVentas
-- Granularidad: una fila por línea de venta (producto×cliente×tienda×vendedor×fecha)
-- Medidas: Aditivas (ValorVenta, CostoTotal, Cantidad, Descuento)
-- ============================================================
CREATE TABLE FactVentas (
    FactVentaID     BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- Claves foráneas a dimensiones (surrogate keys)
    FechaKey        INT          NOT NULL DEFAULT -1,
    ClienteKey      INT          NOT NULL DEFAULT -1,
    ProductoKey     INT          NOT NULL DEFAULT -1,
    TiendaKey       INT          NOT NULL DEFAULT -1,
    VendedorKey     INT          NOT NULL DEFAULT -1,
    CanalKey        INT          NOT NULL DEFAULT -1,
    PromocionKey    INT          NOT NULL DEFAULT -1,

    -- Claves naturales (para trazabilidad)
    VentaID         INT          NOT NULL,
    DetalleID       INT          NOT NULL,
    NumeroFactura   VARCHAR(50)  NOT NULL,

    -- Atributos degenerados (no dimensionan)
    EstadoVenta     VARCHAR(20)  NOT NULL,
    FechaVenta      DATE         NOT NULL,   -- Para drill-down sin join

    -- Medidas (ADITIVAS)
    Cantidad        INT          NOT NULL,
    PrecioUnitario  DECIMAL(18,2) NOT NULL,
    ValorBruto      DECIMAL(18,2) NOT NULL,  -- Cant × PrecioUnitario (sin descuento)
    Descuento       DECIMAL(18,2) NOT NULL,  -- Monto de descuento aplicado
    ValorVenta      DECIMAL(18,2) NOT NULL,  -- Ingreso neto (sin IVA)
    CostoTotal      DECIMAL(18,2) NOT NULL,  -- Cant × CostoUnitario
    MargenBruto     DECIMAL(18,2) NOT NULL,  -- ValorVenta - CostoTotal

    -- Foreign keys
    CONSTRAINT FK_FV_Fecha     FOREIGN KEY (FechaKey)     REFERENCES DimFecha(FechaKey),
    CONSTRAINT FK_FV_Cliente   FOREIGN KEY (ClienteKey)   REFERENCES DimCliente(ClienteKey),
    CONSTRAINT FK_FV_Producto  FOREIGN KEY (ProductoKey)  REFERENCES DimProducto(ProductoKey),
    CONSTRAINT FK_FV_Tienda    FOREIGN KEY (TiendaKey)    REFERENCES DimTienda(TiendaKey),
    CONSTRAINT FK_FV_Vendedor  FOREIGN KEY (VendedorKey)  REFERENCES DimVendedor(VendedorKey),
    CONSTRAINT FK_FV_Canal     FOREIGN KEY (CanalKey)     REFERENCES DimCanalVenta(CanalKey),
    CONSTRAINT FK_FV_Promo     FOREIGN KEY (PromocionKey) REFERENCES DimPromocion(PromocionKey)
);

-- Índices de rendimiento (uno por FK + compostos para slicing BI)
CREATE INDEX IX_FVentas_Fecha    ON FactVentas (FechaKey);
CREATE INDEX IX_FVentas_Cliente  ON FactVentas (ClienteKey);
CREATE INDEX IX_FVentas_Producto ON FactVentas (ProductoKey);
CREATE INDEX IX_FVentas_Tienda   ON FactVentas (TiendaKey);
CREATE INDEX IX_FVentas_Vendedor ON FactVentas (VendedorKey);
CREATE INDEX IX_FVentas_Canal    ON FactVentas (CanalKey);
CREATE INDEX IX_FVentas_Comp1    ON FactVentas (TiendaKey, FechaKey, ProductoKey);
GO

-- ============================================================
-- FactInventarioDiario
-- Granularidad: una fila por día × producto × tienda
-- Medidas: StockFinal es SEMI-ADITIVA (no sumar entre fechas)
--          Entradas y Salidas son ADITIVAS
-- ============================================================
CREATE TABLE FactInventarioDiario (
    FactInventarioID  BIGINT IDENTITY(1,1) PRIMARY KEY,

    -- Claves foráneas
    FechaKey          INT          NOT NULL DEFAULT -1,
    ProductoKey       INT          NOT NULL DEFAULT -1,
    TiendaKey         INT          NOT NULL DEFAULT -1,

    -- Clave natural
    InventarioID      INT          NOT NULL,
    FechaInventario   DATE         NOT NULL,

    -- Medidas ADITIVAS (se pueden sumar entre tiendas, no entre fechas)
    StockInicial      INT          NOT NULL,
    Entradas          INT          NOT NULL,
    Salidas           INT          NOT NULL,
    Ajustes           INT          NOT NULL,

    -- Medida SEMI-ADITIVA (sumar entre tiendas OK, entre fechas NO)
    StockFinal        INT          NOT NULL,

    -- Medida derivada
    DiasInventarioDisponible AS
        CASE WHEN Salidas > 0
             THEN CAST(StockFinal AS DECIMAL(18,2)) / NULLIF(Salidas, 0)
             ELSE NULL
        END PERSISTED,

    CONSTRAINT FK_FI_Fecha    FOREIGN KEY (FechaKey)   REFERENCES DimFecha(FechaKey),
    CONSTRAINT FK_FI_Producto FOREIGN KEY (ProductoKey) REFERENCES DimProducto(ProductoKey),
    CONSTRAINT FK_FI_Tienda   FOREIGN KEY (TiendaKey)  REFERENCES DimTienda(TiendaKey)
);

CREATE INDEX IX_FInv_Fecha    ON FactInventarioDiario (FechaKey);
CREATE INDEX IX_FInv_Producto ON FactInventarioDiario (ProductoKey);
CREATE INDEX IX_FInv_Tienda   ON FactInventarioDiario (TiendaKey);
CREATE INDEX IX_FInv_Comp     ON FactInventarioDiario (TiendaKey, ProductoKey, FechaKey);
GO

-- ============================================================
-- FactMetasComerciales
-- Granularidad: una fila por mes × tienda × categoría
-- Medida ValorMeta: ADITIVA (se puede sumar entre tiendas/categorías)
-- ============================================================
CREATE TABLE FactMetasComerciales (
    FactMetaID       INT IDENTITY(1,1) PRIMARY KEY,

    -- Claves foráneas (no hay FK a DimFecha directa; se usa Anio+Mes)
    TiendaKey        INT          NOT NULL DEFAULT -1,
    ProductoKey      INT          NOT NULL DEFAULT -1,  -- Apunta a categoría del producto
    VendedorKey      INT          NOT NULL DEFAULT -1,
    CanalKey         INT          NOT NULL DEFAULT -1,

    -- Claves naturales degeneradas (granularidad de tiempo)
    MetaID           INT          NOT NULL,
    Anio             INT          NOT NULL,
    Mes              INT          NOT NULL,

    -- Medida ADITIVA
    ValorMeta        DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_FM_Tienda   FOREIGN KEY (TiendaKey)   REFERENCES DimTienda(TiendaKey),
    CONSTRAINT FK_FM_Producto FOREIGN KEY (ProductoKey)  REFERENCES DimProducto(ProductoKey),
    CONSTRAINT FK_FM_Vendedor FOREIGN KEY (VendedorKey)  REFERENCES DimVendedor(VendedorKey),
    CONSTRAINT FK_FM_Canal    FOREIGN KEY (CanalKey)     REFERENCES DimCanalVenta(CanalKey)
);

CREATE INDEX IX_FMeta_Tienda  ON FactMetasComerciales (TiendaKey);
CREATE INDEX IX_FMeta_Anio    ON FactMetasComerciales (Anio, Mes);
GO

-- ============================================================
-- FactDevoluciones
-- Granularidad: una fila por devolución individual
-- Medidas: ValorDevuelto, CantidadDevuelta son ADITIVAS
-- ============================================================
CREATE TABLE FactDevoluciones (
    FactDevolucionID  INT IDENTITY(1,1) PRIMARY KEY,

    -- Claves foráneas
    FechaKey          INT          NOT NULL DEFAULT -1,
    ClienteKey        INT          NOT NULL DEFAULT -1,
    ProductoKey       INT          NOT NULL DEFAULT -1,
    TiendaKey         INT          NOT NULL DEFAULT -1,

    -- Clave natural
    DevolucionID      INT          NOT NULL,
    VentaID           INT          NOT NULL,
    FechaDevolucion   DATE         NOT NULL,
    MotivoDevolucion  VARCHAR(200) NOT NULL,

    -- Medidas ADITIVAS
    CantidadDevuelta  INT          NOT NULL,
    ValorDevuelto     DECIMAL(18,2) NOT NULL,

    CONSTRAINT FK_FD_Fecha    FOREIGN KEY (FechaKey)    REFERENCES DimFecha(FechaKey),
    CONSTRAINT FK_FD_Cliente  FOREIGN KEY (ClienteKey)  REFERENCES DimCliente(ClienteKey),
    CONSTRAINT FK_FD_Producto FOREIGN KEY (ProductoKey) REFERENCES DimProducto(ProductoKey),
    CONSTRAINT FK_FD_Tienda   FOREIGN KEY (TiendaKey)   REFERENCES DimTienda(TiendaKey)
);

CREATE INDEX IX_FDev_Fecha    ON FactDevoluciones (FechaKey);
CREATE INDEX IX_FDev_Producto ON FactDevoluciones (ProductoKey);
CREATE INDEX IX_FDev_Tienda   ON FactDevoluciones (TiendaKey);
GO

PRINT '✔ Tablas de hechos creadas:';
PRINT '  - FactVentas           (granularidad: línea de venta)';
PRINT '  - FactInventarioDiario (granularidad: día × producto × tienda)';
PRINT '  - FactMetasComerciales (granularidad: mes × tienda × categoría)';
PRINT '  - FactDevoluciones     (granularidad: devolución individual)';
