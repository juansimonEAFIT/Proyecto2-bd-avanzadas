-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 2: Sebastian Duran
-- Script: 01_create_staging.sql
-- Descripción: Crea la base de datos de Staging (BI_Staging)
--              con todas las tablas intermedias y la tabla de QA
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'BI_Staging')
BEGIN
    ALTER DATABASE BI_Staging SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE BI_Staging;
    PRINT 'Base de datos BI_Staging eliminada para re-creación.';
END
GO

CREATE DATABASE BI_Staging;
GO

PRINT '✔ Base de datos BI_Staging creada.';

USE BI_Staging;
GO

-- ============================================================
-- TABLAS DE STAGING (replican estructura OLTP + columnas de control)
-- ============================================================

-- STG_Clientes
CREATE TABLE STG_Clientes (
    ClienteID       INT,
    Documento       VARCHAR(20),
    TipoDocumento   VARCHAR(10),
    NombreCliente   VARCHAR(200),
    Email           VARCHAR(100),
    Telefono        VARCHAR(20),
    CiudadNombre    VARCHAR(100),
    Departamento    VARCHAR(100),
    Region          VARCHAR(50),
    Segmento        VARCHAR(20),
    FechaNacimiento DATE,
    FechaRegistro   DATETIME,
    Activo          BIT,
    -- Columnas de control
    FechaCarga      DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad      VARCHAR(500) NULL,
    EsDuplicado     BIT NOT NULL DEFAULT 0
);

-- STG_Productos
CREATE TABLE STG_Productos (
    ProductoID      INT,
    CodigoSKU       VARCHAR(50),
    NombreProducto  VARCHAR(200),
    NombreCategoria VARCHAR(100),
    CategoriaParent VARCHAR(100),
    NombreProveedor VARCHAR(150),
    PrecioUnitario  DECIMAL(18,2),
    CostoUnitario   DECIMAL(18,2),
    MargenPct       DECIMAL(5,2),
    UnidadMedida    VARCHAR(20),
    StockMinimo     INT,
    Activo          BIT,
    -- Columnas de control
    FechaCarga      DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad      VARCHAR(500) NULL,
    EsDuplicado     BIT NOT NULL DEFAULT 0
);

-- STG_Ventas
CREATE TABLE STG_Ventas (
    VentaID        INT,
    NumeroFactura  VARCHAR(50),
    ClienteID      INT,
    NombreCliente  VARCHAR(200),
    TiendaID       INT,
    NombreTienda   VARCHAR(100),
    VendedorID     INT,
    NombreVendedor VARCHAR(200),
    CanalID        INT,
    NombreCanal    VARCHAR(50),
    CampanaID      INT,
    NombreCampana  VARCHAR(100),
    FechaVenta     DATETIME,
    Anio           INT,
    Mes            INT,
    Dia            INT,
    DiaSemana      INT,
    Subtotal       DECIMAL(18,2),
    TotalDescuento DECIMAL(18,2),
    TotalImpuesto  DECIMAL(18,2),
    TotalVenta     DECIMAL(18,2),
    Estado         VARCHAR(20),
    -- Columnas de control
    FechaCarga     DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad    VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad     VARCHAR(500) NULL,
    EsDuplicado    BIT NOT NULL DEFAULT 0
);

-- STG_DetalleVentas
CREATE TABLE STG_DetalleVentas (
    DetalleID      INT,
    VentaID        INT,
    NumeroFactura  VARCHAR(50),
    ProductoID     INT,
    CodigoSKU      VARCHAR(50),
    NombreProducto VARCHAR(200),
    NombreCategoria VARCHAR(100),
    Cantidad       INT,
    PrecioUnitario DECIMAL(18,2),
    CostoUnitario  DECIMAL(18,2),
    DescuentoPct   DECIMAL(5,2),
    TotalLinea     DECIMAL(18,2),
    CostoTotal     DECIMAL(18,2),
    MargenLinea    DECIMAL(18,2),
    FechaVenta     DATETIME,
    -- Columnas de control
    FechaCarga     DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad    VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad     VARCHAR(500) NULL
);

-- STG_Inventario
CREATE TABLE STG_Inventario (
    InventarioID    INT,
    FechaInventario DATE,
    ProductoID      INT,
    CodigoSKU       VARCHAR(50),
    NombreProducto  VARCHAR(200),
    TiendaID        INT,
    NombreTienda    VARCHAR(100),
    StockInicial    INT,
    Entradas        INT,
    Salidas         INT,
    Ajustes         INT,
    StockFinal      INT,
    -- Columnas de control
    FechaCarga      DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad      VARCHAR(500) NULL
);

-- STG_Metas (desde OLTP)
CREATE TABLE STG_Metas (
    MetaID          INT,
    Anio            INT,
    Mes             INT,
    TiendaID        INT,
    NombreTienda    VARCHAR(100),
    CategoriaID     INT,
    NombreCategoria VARCHAR(100),
    VendedorID      INT,
    NombreVendedor  VARCHAR(200),
    CanalID         INT,
    NombreCanal     VARCHAR(50),
    ValorMeta       DECIMAL(18,2),
    -- Columnas de control
    FechaCarga      DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad      VARCHAR(500) NULL
);

-- STG_Devoluciones
CREATE TABLE STG_Devoluciones (
    DevolucionID     INT,
    VentaID          INT,
    NumeroFactura    VARCHAR(50),
    ClienteID        INT,
    NombreCliente    VARCHAR(200),
    TiendaID         INT,
    NombreTienda     VARCHAR(100),
    ProductoID       INT,
    NombreProducto   VARCHAR(200),
    FechaDevolucion  DATETIME,
    MotivoDevolucion VARCHAR(200),
    CantidadDevuelta INT,
    ValorDevuelto    DECIMAL(18,2),
    -- Columnas de control
    FechaCarga       DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad      VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad       VARCHAR(500) NULL
);

-- STG_Compras
CREATE TABLE STG_Compras (
    CompraID        INT,
    NumeroOrden     VARCHAR(50),
    ProveedorID     INT,
    NombreProveedor VARCHAR(150),
    TiendaID        INT,
    NombreTienda    VARCHAR(100),
    FechaOrden      DATE,
    FechaRecepcion  DATE,
    DiasEntrega     INT,
    TotalCompra     DECIMAL(18,2),
    Estado          VARCHAR(20),
    -- Columnas de control
    FechaCarga      DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad      VARCHAR(500) NULL
);

-- STG_MetasExternas (desde CSV externo)
CREATE TABLE STG_MetasExternas (
    Anio            INT,
    Mes             INT,
    NombreTienda    VARCHAR(100),
    NombreCategoria VARCHAR(100),
    ValorMeta       DECIMAL(18,2),
    Fuente          VARCHAR(50) NOT NULL DEFAULT 'CSV_EXTERNO',
    FechaCarga      DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad      VARCHAR(500) NULL
);

-- STG_InventarioFisico (desde CSV externo)
CREATE TABLE STG_InventarioFisico (
    FechaConteo     DATE,
    CodigoSKU       VARCHAR(50),
    NombreTienda    VARCHAR(100),
    StockContado    INT,
    StockSistema    INT,
    Diferencia      INT,
    Observacion     VARCHAR(200),
    Fuente          VARCHAR(50) NOT NULL DEFAULT 'CSV_EXTERNO',
    FechaCarga      DATETIME NOT NULL DEFAULT GETDATE(),
    FlagCalidad     VARCHAR(20) NOT NULL DEFAULT 'PENDIENTE',
    ObsCalidad      VARCHAR(500) NULL
);

-- ============================================================
-- TABLA DE REPORTE DE CALIDAD DE DATOS
-- ============================================================
CREATE TABLE QA_Reporte (
    QA_ID          INT IDENTITY(1,1) PRIMARY KEY,
    FechaEjecucion DATETIME NOT NULL DEFAULT GETDATE(),
    TablaOrigen    VARCHAR(100) NOT NULL,
    TipoValidacion VARCHAR(100) NOT NULL,
    TotalRegistros INT NOT NULL DEFAULT 0,
    RegistrosOK    INT NOT NULL DEFAULT 0,
    RegistrosError INT NOT NULL DEFAULT 0,
    PctError       DECIMAL(5,2) NOT NULL DEFAULT 0,
    Detalle        VARCHAR(MAX) NULL
);
GO

PRINT '✔ Tablas de BI_Staging creadas exitosamente.';
PRINT '  Tablas: STG_Clientes, STG_Productos, STG_Ventas, STG_DetalleVentas,';
PRINT '          STG_Inventario, STG_Metas, STG_Devoluciones, STG_Compras,';
PRINT '          STG_MetasExternas, STG_InventarioFisico, QA_Reporte';
