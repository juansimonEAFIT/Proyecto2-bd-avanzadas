-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Personas 2 y 3: Sebastian Duran / Juan Simon Ospina
-- Script: 02_create_dimensions.sql
-- Descripción: Crea las 9 tablas de dimensiones del modelo estrella.
--   - DimFecha, DimGeografia, DimCliente, DimProducto, DimTienda
--   - DimVendedor, DimProveedor, DimCanalVenta, DimPromocion
-- Ejecutar DESPUÉS de 01_create_dw_database.sql
-- ============================================================

USE RetailDW;
GO

-- ============================================================
-- DimFecha — Dimensión de tiempo con jerarquías completas
-- ============================================================
CREATE TABLE DimFecha (
    FechaKey        INT          NOT NULL PRIMARY KEY,  -- YYYYMMDD
    Fecha           DATE         NOT NULL UNIQUE,
    Anio            INT          NOT NULL,
    Trimestre       INT          NOT NULL CHECK (Trimestre BETWEEN 1 AND 4),
    NombreTrimestre VARCHAR(10)  NOT NULL,
    MesNum          INT          NOT NULL CHECK (MesNum BETWEEN 1 AND 12),
    NombreMes       VARCHAR(20)  NOT NULL,
    AbrevMes        CHAR(3)      NOT NULL,
    Semana          INT          NOT NULL,               -- Semana del año ISO
    DiaMes          INT          NOT NULL CHECK (DiaMes BETWEEN 1 AND 31),
    DiaSemanaNum    INT          NOT NULL CHECK (DiaSemanaNum BETWEEN 1 AND 7),
    NombreDia       VARCHAR(20)  NOT NULL,
    AbrevDia        CHAR(3)      NOT NULL,
    EsFinDeSemana   BIT          NOT NULL DEFAULT 0,
    EsFeriado       BIT          NOT NULL DEFAULT 0,
    NombreFeriado   VARCHAR(100) NULL,
    AnioMes         INT          NOT NULL,               -- YYYYMM para agrupaciones
    AnioTrimestre   VARCHAR(10)  NOT NULL                -- ej: '2024-Q3'
);

-- ============================================================
-- DimGeografia — Jerarquía: Región → Departamento → Ciudad
-- ============================================================
CREATE TABLE DimGeografia (
    GeografiaKey    INT IDENTITY(1,1) PRIMARY KEY,
    NombreCiudad    VARCHAR(100) NOT NULL,
    Departamento    VARCHAR(100) NOT NULL,
    Region          VARCHAR(50)  NOT NULL,
    CodigoDane      VARCHAR(10)  NULL,
    -- SCD Tipo 1 (sobrescritura)
    FechaCreacion   DATETIME     NOT NULL DEFAULT GETDATE(),
    FechaActualizacion DATETIME  NOT NULL DEFAULT GETDATE()
);

-- ============================================================
-- DimCliente — Dimensión de clientes con segmento
-- ============================================================
CREATE TABLE DimCliente (
    ClienteKey      INT IDENTITY(1,1) PRIMARY KEY,
    ClienteID       INT          NOT NULL,               -- NK (Natural Key)
    Documento       VARCHAR(20)  NOT NULL,
    TipoDocumento   VARCHAR(10)  NOT NULL,
    NombreCliente   VARCHAR(200) NOT NULL,
    Email           VARCHAR(100) NULL,
    Telefono        VARCHAR(20)  NULL,
    Ciudad          VARCHAR(100) NULL,
    Departamento    VARCHAR(100) NULL,
    Region          VARCHAR(50)  NULL,
    Segmento        VARCHAR(20)  NOT NULL,
    RangoEdad       VARCHAR(30)  NULL,                   -- Campo derivado
    AnioCohort      INT          NULL,                   -- Año de primera compra
    Activo          BIT          NOT NULL DEFAULT 1,
    -- SCD Tipo 2
    FechaInicioSCD  DATE         NOT NULL DEFAULT GETDATE(),
    FechaFinSCD     DATE         NULL,
    EsVersionActual BIT          NOT NULL DEFAULT 1
);

-- ============================================================
-- DimProducto — Dimensión de productos con jerarquía de categorías
-- ============================================================
CREATE TABLE DimProducto (
    ProductoKey     INT IDENTITY(1,1) PRIMARY KEY,
    ProductoID      INT          NOT NULL,               -- NK
    CodigoSKU       VARCHAR(50)  NOT NULL,
    NombreProducto  VARCHAR(200) NOT NULL,
    Categoria       VARCHAR(100) NOT NULL,
    CategoriaParent VARCHAR(100) NULL,
    NombreProveedor VARCHAR(150) NULL,
    PrecioLista     DECIMAL(18,2) NOT NULL,
    CostoStandard   DECIMAL(18,2) NOT NULL,
    MargenStandard  DECIMAL(5,2)  NOT NULL,
    UnidadMedida    VARCHAR(20)  NOT NULL,
    GrupoPrecio     VARCHAR(20)  NOT NULL,              -- 'ECONÓMICO','MID','PREMIUM'
    Activo          BIT          NOT NULL DEFAULT 1,
    -- SCD Tipo 2
    FechaInicioSCD  DATE         NOT NULL DEFAULT GETDATE(),
    FechaFinSCD     DATE         NULL,
    EsVersionActual BIT          NOT NULL DEFAULT 1
);

-- ============================================================
-- DimTienda — Dimensión de tiendas/sedes
-- ============================================================
CREATE TABLE DimTienda (
    TiendaKey       INT IDENTITY(1,1) PRIMARY KEY,
    TiendaID        INT          NOT NULL,               -- NK
    CodigoTienda    VARCHAR(20)  NOT NULL,
    NombreTienda    VARCHAR(100) NOT NULL,
    Ciudad          VARCHAR(100) NOT NULL,
    Departamento    VARCHAR(100) NOT NULL,
    Region          VARCHAR(50)  NOT NULL,
    Direccion       VARCHAR(200) NULL,
    AreaM2          DECIMAL(10,2) NULL,
    CategoriaTamanio VARCHAR(20) NOT NULL,              -- 'PEQUEÑA','MEDIANA','GRANDE'
    FechaApertura   DATE         NOT NULL,
    AnosOperacion   INT          NOT NULL,
    Activo          BIT          NOT NULL DEFAULT 1
);

-- ============================================================
-- DimVendedor — Dimensión de vendedores
-- ============================================================
CREATE TABLE DimVendedor (
    VendedorKey     INT IDENTITY(1,1) PRIMARY KEY,
    VendedorID      INT          NOT NULL,               -- NK
    Documento       VARCHAR(20)  NOT NULL,
    NombreVendedor  VARCHAR(200) NOT NULL,
    TiendaAsignada  VARCHAR(100) NOT NULL,
    CanalAsignado   VARCHAR(50)  NULL,
    AnosExperiencia INT          NOT NULL,
    Activo          BIT          NOT NULL DEFAULT 1,
    FechaIngreso    DATE         NOT NULL
);

-- ============================================================
-- DimProveedor — Dimensión de proveedores
-- ============================================================
CREATE TABLE DimProveedor (
    ProveedorKey    INT IDENTITY(1,1) PRIMARY KEY,
    ProveedorID     INT          NOT NULL,               -- NK
    NombreProveedor VARCHAR(150) NOT NULL,
    NIT             VARCHAR(20)  NOT NULL,
    Ciudad          VARCHAR(100) NOT NULL,
    Departamento    VARCHAR(100) NOT NULL,
    Activo          BIT          NOT NULL DEFAULT 1
);

-- ============================================================
-- DimCanalVenta — Dimensión de canales de venta
-- ============================================================
CREATE TABLE DimCanalVenta (
    CanalKey        INT IDENTITY(1,1) PRIMARY KEY,
    CanalID         INT          NOT NULL,               -- NK
    NombreCanal     VARCHAR(50)  NOT NULL,
    TipoCanal       VARCHAR(30)  NOT NULL,              -- 'FISICO','DIGITAL','HIBRIDO'
    Descripcion     VARCHAR(200) NULL,
    Activo          BIT          NOT NULL DEFAULT 1
);

-- ============================================================
-- DimPromocion — Dimensión de campañas y promociones
-- ============================================================
CREATE TABLE DimPromocion (
    PromocionKey    INT IDENTITY(1,1) PRIMARY KEY,
    CampanaID       INT          NULL,                   -- NK (NULL = sin campaña)
    NombreCampana   VARCHAR(100) NOT NULL,
    TipoCampana     VARCHAR(50)  NOT NULL,
    FechaInicio     DATE         NULL,
    FechaFin        DATE         NULL,
    DuracionDias    INT          NULL,
    DescuentoPct    DECIMAL(5,2) NOT NULL DEFAULT 0,
    EsPromocion     BIT          NOT NULL DEFAULT 1
);
GO

-- ============================================================
-- INSERTAR FILA ESPECIAL "DESCONOCIDO" EN CADA DIMENSIÓN
-- (Para manejar surrogate keys no resueltas → valor -1)
-- ============================================================
SET IDENTITY_INSERT DimGeografia ON;
INSERT INTO DimGeografia (GeografiaKey, NombreCiudad, Departamento, Region)
VALUES (-1, 'DESCONOCIDO', 'DESCONOCIDO', 'DESCONOCIDO');
SET IDENTITY_INSERT DimGeografia OFF;

SET IDENTITY_INSERT DimCliente ON;
INSERT INTO DimCliente (ClienteKey, ClienteID, Documento, TipoDocumento, NombreCliente, Segmento, EsVersionActual, FechaInicioSCD)
VALUES (-1, -1, '00000000', 'CC', 'CLIENTE DESCONOCIDO', 'General', 1, '2020-01-01');
SET IDENTITY_INSERT DimCliente OFF;

SET IDENTITY_INSERT DimProducto ON;
INSERT INTO DimProducto (ProductoKey, ProductoID, CodigoSKU, NombreProducto, Categoria, PrecioLista, CostoStandard, MargenStandard, UnidadMedida, GrupoPrecio, EsVersionActual, FechaInicioSCD)
VALUES (-1, -1, 'SKU-0000', 'PRODUCTO DESCONOCIDO', 'DESCONOCIDA', 0, 0, 0, 'UND', 'ECONÓMICO', 1, '2020-01-01');
SET IDENTITY_INSERT DimProducto OFF;

SET IDENTITY_INSERT DimTienda ON;
INSERT INTO DimTienda (TiendaKey, TiendaID, CodigoTienda, NombreTienda, Ciudad, Departamento, Region, CategoriaTamanio, FechaApertura, AnosOperacion)
VALUES (-1, -1, 'T000', 'TIENDA DESCONOCIDA', 'DESCONOCIDA', 'DESCONOCIDO', 'DESCONOCIDA', 'PEQUEÑA', '2020-01-01', 0);
SET IDENTITY_INSERT DimTienda OFF;

SET IDENTITY_INSERT DimVendedor ON;
INSERT INTO DimVendedor (VendedorKey, VendedorID, Documento, NombreVendedor, TiendaAsignada, AnosExperiencia, FechaIngreso)
VALUES (-1, -1, '00000000', 'VENDEDOR DESCONOCIDO', 'DESCONOCIDA', 0, '2020-01-01');
SET IDENTITY_INSERT DimVendedor OFF;

SET IDENTITY_INSERT DimProveedor ON;
INSERT INTO DimProveedor (ProveedorKey, ProveedorID, NombreProveedor, NIT, Ciudad, Departamento)
VALUES (-1, -1, 'PROVEEDOR DESCONOCIDO', '000000000-0', 'DESCONOCIDA', 'DESCONOCIDO');
SET IDENTITY_INSERT DimProveedor OFF;

SET IDENTITY_INSERT DimCanalVenta ON;
INSERT INTO DimCanalVenta (CanalKey, CanalID, NombreCanal, TipoCanal)
VALUES (-1, -1, 'CANAL DESCONOCIDO', 'DESCONOCIDO');
SET IDENTITY_INSERT DimCanalVenta OFF;

SET IDENTITY_INSERT DimPromocion ON;
INSERT INTO DimPromocion (PromocionKey, CampanaID, NombreCampana, TipoCampana, DescuentoPct, EsPromocion)
VALUES (-1, NULL, 'SIN CAMPAÑA', 'Ninguno', 0, 0);
SET IDENTITY_INSERT DimPromocion OFF;
GO

PRINT '✔ Dimensiones creadas con filas "DESCONOCIDO" (-1) insertadas.';
PRINT '  Dimensiones: DimFecha, DimGeografia, DimCliente, DimProducto, DimTienda,';
PRINT '               DimVendedor, DimProveedor, DimCanalVenta, DimPromocion';
