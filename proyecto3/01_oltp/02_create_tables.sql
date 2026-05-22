-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 1: Alejandro Posada
-- Script: 02_create_tables.sql
-- Descripción: Crea todas las tablas del módulo OLTP (normalizado 3FN)
-- Ejecutar DESPUÉS de 01_create_database.sql
-- ============================================================

USE RetailOLTP;
GO

-- ============================================================
-- TABLAS BASE (sin dependencias externas)
-- ============================================================

-- Tabla: Ciudades (referencia geográfica)
CREATE TABLE Ciudades (
    CiudadID        INT IDENTITY(1,1) PRIMARY KEY,
    NombreCiudad    VARCHAR(100) NOT NULL,
    Departamento    VARCHAR(100) NOT NULL,
    Region          VARCHAR(50)  NOT NULL
        CHECK (Region IN ('Andina','Caribe','Pacifica','Orinoquia','Amazonia','Insular')),
    CodigoDane      VARCHAR(10)  NULL,
    FechaCreacion   DATETIME     NOT NULL DEFAULT GETDATE()
);

-- Tabla: Categorias (puede ser jerarquica)
CREATE TABLE Categorias (
    CategoriaID      INT IDENTITY(1,1) PRIMARY KEY,
    NombreCategoria  VARCHAR(100) NOT NULL UNIQUE,
    Descripcion      VARCHAR(255) NULL,
    CategoriaParent  INT          NULL REFERENCES Categorias(CategoriaID),
    Activo           BIT          NOT NULL DEFAULT 1,
    FechaCreacion    DATETIME     NOT NULL DEFAULT GETDATE()
);

-- Tabla: Proveedores
CREATE TABLE Proveedores (
    ProveedorID     INT IDENTITY(1,1) PRIMARY KEY,
    NombreProveedor VARCHAR(150) NOT NULL,
    NIT             VARCHAR(20)  NOT NULL UNIQUE,
    Ciudad          VARCHAR(100) NOT NULL,
    Departamento    VARCHAR(100) NOT NULL,
    Telefono        VARCHAR(20)  NULL,
    Email           VARCHAR(100) NULL,
    Activo          BIT          NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME     NOT NULL DEFAULT GETDATE()
);

-- Tabla: Canal de Venta
CREATE TABLE CanalVenta (
    CanalID      INT IDENTITY(1,1) PRIMARY KEY,
    NombreCanal  VARCHAR(50)  NOT NULL UNIQUE,
    Descripcion  VARCHAR(200) NULL,
    Activo       BIT          NOT NULL DEFAULT 1
);

-- ============================================================
-- TABLAS CON DEPENDENCIAS SIMPLES
-- ============================================================

-- Tabla: Clientes
CREATE TABLE Clientes (
    ClienteID       INT IDENTITY(1,1) PRIMARY KEY,
    Documento       VARCHAR(20)  NOT NULL UNIQUE,
    TipoDocumento   VARCHAR(10)  NOT NULL
        CHECK (TipoDocumento IN ('CC','CE','NIT','TI','PAS')),
    NombreCliente   VARCHAR(200) NOT NULL,
    Email           VARCHAR(100) NULL,
    Telefono        VARCHAR(20)  NULL,
    CiudadID        INT          NULL REFERENCES Ciudades(CiudadID),
    Segmento        VARCHAR(20)  NOT NULL DEFAULT 'General'
        CHECK (Segmento IN ('VIP','Premium','Regular','General')),
    FechaNacimiento DATE         NULL,
    FechaRegistro   DATETIME     NOT NULL DEFAULT GETDATE(),
    Activo          BIT          NOT NULL DEFAULT 1
);

-- Tabla: Tiendas
CREATE TABLE Tiendas (
    TiendaID      INT IDENTITY(1,1) PRIMARY KEY,
    CodigoTienda  VARCHAR(20)  NOT NULL UNIQUE,
    NombreTienda  VARCHAR(100) NOT NULL,
    CiudadID      INT          NOT NULL REFERENCES Ciudades(CiudadID),
    Direccion     VARCHAR(200) NOT NULL,
    Telefono      VARCHAR(20)  NULL,
    AreaM2        DECIMAL(10,2) NULL CHECK (AreaM2 > 0),
    FechaApertura DATE         NOT NULL,
    Activo        BIT          NOT NULL DEFAULT 1
);

-- Tabla: Campanas Comerciales
CREATE TABLE Campanas (
    CampanaID     INT IDENTITY(1,1) PRIMARY KEY,
    NombreCampana VARCHAR(100) NOT NULL,
    TipoCampana   VARCHAR(50)  NOT NULL
        CHECK (TipoCampana IN ('Descuento','Liquidacion','Temporada','Fidelizacion','Otro')),
    FechaInicio   DATE         NOT NULL,
    FechaFin      DATE         NOT NULL,
    DescuentoPct  DECIMAL(5,2) NOT NULL DEFAULT 0
        CHECK (DescuentoPct BETWEEN 0 AND 100),
    Activo        BIT          NOT NULL DEFAULT 1,
    CONSTRAINT CHK_Campana_Fechas CHECK (FechaFin >= FechaInicio)
);

-- Tabla: Productos
CREATE TABLE Productos (
    ProductoID      INT IDENTITY(1,1) PRIMARY KEY,
    CodigoSKU       VARCHAR(50)   NOT NULL UNIQUE,
    NombreProducto  VARCHAR(200)  NOT NULL,
    CategoriaID     INT           NOT NULL REFERENCES Categorias(CategoriaID),
    ProveedorID     INT           NOT NULL REFERENCES Proveedores(ProveedorID),
    PrecioUnitario  DECIMAL(18,2) NOT NULL CHECK (PrecioUnitario > 0),
    CostoUnitario   DECIMAL(18,2) NOT NULL CHECK (CostoUnitario > 0),
    UnidadMedida    VARCHAR(20)   NOT NULL DEFAULT 'UND',
    StockMinimo     INT           NOT NULL DEFAULT 10 CHECK (StockMinimo >= 0),
    PesoKg          DECIMAL(10,3) NULL CHECK (PesoKg > 0),
    Activo          BIT           NOT NULL DEFAULT 1,
    FechaCreacion   DATETIME      NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CHK_Producto_Margen CHECK (PrecioUnitario >= CostoUnitario)
);

-- ============================================================
-- TABLAS CON DEPENDENCIAS COMPUESTAS
-- ============================================================

-- Tabla: Vendedores
CREATE TABLE Vendedores (
    VendedorID     INT IDENTITY(1,1) PRIMARY KEY,
    Documento      VARCHAR(20)  NOT NULL UNIQUE,
    NombreVendedor VARCHAR(200) NOT NULL,
    TiendaID       INT          NOT NULL REFERENCES Tiendas(TiendaID),
    CanalID        INT          NULL REFERENCES CanalVenta(CanalID),
    FechaIngreso   DATE         NOT NULL,
    Activo         BIT          NOT NULL DEFAULT 1
);

-- ============================================================
-- TABLAS TRANSACCIONALES
-- ============================================================

-- Tabla: Ventas (cabecera de factura)
CREATE TABLE Ventas (
    VentaID        INT IDENTITY(1,1) PRIMARY KEY,
    NumeroFactura  VARCHAR(50)   NOT NULL UNIQUE,
    ClienteID      INT           NOT NULL REFERENCES Clientes(ClienteID),
    TiendaID       INT           NOT NULL REFERENCES Tiendas(TiendaID),
    VendedorID     INT           NOT NULL REFERENCES Vendedores(VendedorID),
    CanalID        INT           NOT NULL REFERENCES CanalVenta(CanalID),
    CampanaID      INT           NULL REFERENCES Campanas(CampanaID),
    FechaVenta     DATETIME      NOT NULL DEFAULT GETDATE(),
    Subtotal       DECIMAL(18,2) NOT NULL CHECK (Subtotal >= 0),
    TotalDescuento DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TotalDescuento >= 0),
    TotalImpuesto  DECIMAL(18,2) NOT NULL DEFAULT 0 CHECK (TotalImpuesto >= 0),
    TotalVenta     DECIMAL(18,2) NOT NULL CHECK (TotalVenta >= 0),
    Estado         VARCHAR(20)   NOT NULL DEFAULT 'Completada'
        CHECK (Estado IN ('Completada','Anulada','Pendiente'))
);

-- Tabla: Detalle de Ventas (líneas de factura)
CREATE TABLE DetalleVentas (
    DetalleID      INT IDENTITY(1,1) PRIMARY KEY,
    VentaID        INT           NOT NULL REFERENCES Ventas(VentaID),
    ProductoID     INT           NOT NULL REFERENCES Productos(ProductoID),
    Cantidad       INT           NOT NULL CHECK (Cantidad > 0),
    PrecioUnitario DECIMAL(18,2) NOT NULL CHECK (PrecioUnitario > 0),
    CostoUnitario  DECIMAL(18,2) NOT NULL CHECK (CostoUnitario > 0),
    DescuentoPct   DECIMAL(5,2)  NOT NULL DEFAULT 0 CHECK (DescuentoPct BETWEEN 0 AND 100),
    TotalLinea     DECIMAL(18,2) NOT NULL CHECK (TotalLinea >= 0)
);

-- Tabla: Inventario Diario (snapshot diario por producto/tienda)
CREATE TABLE InventarioDiario (
    InventarioID    INT IDENTITY(1,1) PRIMARY KEY,
    FechaInventario DATE          NOT NULL,
    ProductoID      INT           NOT NULL REFERENCES Productos(ProductoID),
    TiendaID        INT           NOT NULL REFERENCES Tiendas(TiendaID),
    StockInicial    INT           NOT NULL DEFAULT 0 CHECK (StockInicial >= 0),
    Entradas        INT           NOT NULL DEFAULT 0 CHECK (Entradas >= 0),
    Salidas         INT           NOT NULL DEFAULT 0 CHECK (Salidas >= 0),
    Ajustes         INT           NOT NULL DEFAULT 0,
    StockFinal      INT           NOT NULL DEFAULT 0 CHECK (StockFinal >= 0),
    CONSTRAINT UQ_Inventario UNIQUE (FechaInventario, ProductoID, TiendaID)
);

-- Tabla: Compras (órdenes de compra a proveedores)
CREATE TABLE Compras (
    CompraID      INT IDENTITY(1,1) PRIMARY KEY,
    NumeroOrden   VARCHAR(50)   NOT NULL UNIQUE,
    ProveedorID   INT           NOT NULL REFERENCES Proveedores(ProveedorID),
    TiendaID      INT           NOT NULL REFERENCES Tiendas(TiendaID),
    FechaOrden    DATE          NOT NULL,
    FechaRecepcion DATE         NULL,
    TotalCompra   DECIMAL(18,2) NOT NULL CHECK (TotalCompra >= 0),
    Estado        VARCHAR(20)   NOT NULL DEFAULT 'Pendiente'
        CHECK (Estado IN ('Pendiente','Recibida','Cancelada')),
    CONSTRAINT CHK_Compra_Fechas CHECK (FechaRecepcion IS NULL OR FechaRecepcion >= FechaOrden)
);

-- Tabla: Detalle de Compras
CREATE TABLE DetalleCompras (
    DetalleCompraID   INT IDENTITY(1,1) PRIMARY KEY,
    CompraID          INT           NOT NULL REFERENCES Compras(CompraID),
    ProductoID        INT           NOT NULL REFERENCES Productos(ProductoID),
    CantidadOrdenada  INT           NOT NULL CHECK (CantidadOrdenada > 0),
    CantidadRecibida  INT           NOT NULL DEFAULT 0 CHECK (CantidadRecibida >= 0),
    CostoUnitario     DECIMAL(18,2) NOT NULL CHECK (CostoUnitario > 0),
    TotalLinea        DECIMAL(18,2) NOT NULL CHECK (TotalLinea >= 0)
);

-- Tabla: Devoluciones
CREATE TABLE Devoluciones (
    DevolucionID     INT IDENTITY(1,1) PRIMARY KEY,
    VentaID          INT           NOT NULL REFERENCES Ventas(VentaID),
    DetalleID        INT           NULL REFERENCES DetalleVentas(DetalleID),
    ClienteID        INT           NOT NULL REFERENCES Clientes(ClienteID),
    TiendaID         INT           NOT NULL REFERENCES Tiendas(TiendaID),
    ProductoID       INT           NOT NULL REFERENCES Productos(ProductoID),
    FechaDevolucion  DATETIME      NOT NULL DEFAULT GETDATE(),
    MotivoDevolucion VARCHAR(200)  NOT NULL,
    CantidadDevuelta INT           NOT NULL CHECK (CantidadDevuelta > 0),
    ValorDevuelto    DECIMAL(18,2) NOT NULL CHECK (ValorDevuelto >= 0)
);

-- Tabla: Metas Comerciales
CREATE TABLE MetasComerciales (
    MetaID      INT IDENTITY(1,1) PRIMARY KEY,
    Anio        INT           NOT NULL CHECK (Anio BETWEEN 2020 AND 2030),
    Mes         INT           NOT NULL CHECK (Mes BETWEEN 1 AND 12),
    TiendaID    INT           NOT NULL REFERENCES Tiendas(TiendaID),
    CategoriaID INT           NULL REFERENCES Categorias(CategoriaID),
    VendedorID  INT           NULL REFERENCES Vendedores(VendedorID),
    CanalID     INT           NULL REFERENCES CanalVenta(CanalID),
    ValorMeta   DECIMAL(18,2) NOT NULL CHECK (ValorMeta >= 0),
    CONSTRAINT UQ_Meta UNIQUE (Anio, Mes, TiendaID, CategoriaID, VendedorID, CanalID)
);
GO

-- ============================================================
-- ÍNDICES PARA OPTIMIZAR CONSULTAS BI
-- ============================================================

-- Índices en Ventas
CREATE INDEX IX_Ventas_Fecha      ON Ventas (FechaVenta);
CREATE INDEX IX_Ventas_Cliente    ON Ventas (ClienteID);
CREATE INDEX IX_Ventas_Tienda     ON Ventas (TiendaID);
CREATE INDEX IX_Ventas_Vendedor   ON Ventas (VendedorID);
CREATE INDEX IX_Ventas_Canal      ON Ventas (CanalID);

-- Índices en DetalleVentas
CREATE INDEX IX_Detalle_Venta     ON DetalleVentas (VentaID);
CREATE INDEX IX_Detalle_Producto  ON DetalleVentas (ProductoID);

-- Índices en InventarioDiario
CREATE INDEX IX_Inventario_Fecha  ON InventarioDiario (FechaInventario);
CREATE INDEX IX_Inventario_Prod   ON InventarioDiario (ProductoID);
CREATE INDEX IX_Inventario_Tienda ON InventarioDiario (TiendaID);
GO

PRINT '=== Tablas OLTP creadas exitosamente ===';
PRINT 'Tablas: Ciudades, Categorias, Proveedores, CanalVenta, Campanas,';
PRINT '        Clientes, Tiendas, Productos, Vendedores, Ventas, DetalleVentas,';
PRINT '        InventarioDiario, Compras, DetalleCompras, Devoluciones, MetasComerciales';
