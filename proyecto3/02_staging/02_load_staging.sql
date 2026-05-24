-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 2: Sebastian Duran
-- Script: 02_load_staging.sql
-- Descripción: Carga datos del OLTP (RetailOLTP) al Staging (BI_Staging)
--              e importa las fuentes externas CSV.
-- Ejecutar DESPUÉS de 01_create_staging.sql y de que el OLTP tenga datos.
-- ============================================================

USE BI_Staging;
GO

SET NOCOUNT ON;
PRINT '=== Iniciando carga de OLTP → Staging ===';
PRINT CAST(GETDATE() AS VARCHAR);
GO

-- ============================================================
-- LIMPIAR STAGING (preparar para nueva carga)
-- ============================================================
TRUNCATE TABLE STG_DetalleVentas;
TRUNCATE TABLE STG_Ventas;
TRUNCATE TABLE STG_Clientes;
TRUNCATE TABLE STG_Productos;
TRUNCATE TABLE STG_Inventario;
TRUNCATE TABLE STG_Metas;
TRUNCATE TABLE STG_Devoluciones;
TRUNCATE TABLE STG_Compras;
TRUNCATE TABLE STG_MetasExternas;
TRUNCATE TABLE STG_InventarioFisico;
DELETE FROM QA_Reporte;
PRINT '✔ Staging limpiado.';
GO

-- ============================================================
-- 1. CARGAR STG_CLIENTES
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_Clientes (
    ClienteID, Documento, TipoDocumento, NombreCliente, Email, Telefono,
    CiudadNombre, Departamento, Region, Segmento, FechaNacimiento, FechaRegistro, Activo,
    FlagCalidad, ObsCalidad
)
SELECT
    c.ClienteID,
    c.Documento,
    c.TipoDocumento,
    c.NombreCliente,
    c.Email,
    c.Telefono,
    ISNULL(ci.NombreCiudad, 'DESCONOCIDA'),
    ISNULL(ci.Departamento, 'DESCONOCIDO'),
    ISNULL(ci.Region,       'DESCONOCIDA'),
    c.Segmento,
    c.FechaNacimiento,
    c.FechaRegistro,
    c.Activo,
    'PENDIENTE',
    NULL
FROM RetailOLTP.dbo.Clientes c
LEFT JOIN RetailOLTP.dbo.Ciudades ci ON c.CiudadID = ci.CiudadID;

PRINT '✔ STG_Clientes cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 2. CARGAR STG_PRODUCTOS
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_Productos (
    ProductoID, CodigoSKU, NombreProducto, NombreCategoria, CategoriaParent,
    NombreProveedor, PrecioUnitario, CostoUnitario, MargenPct,
    UnidadMedida, StockMinimo, Activo, FlagCalidad
)
SELECT
    p.ProductoID,
    p.CodigoSKU,
    p.NombreProducto,
    cat.NombreCategoria,
    ISNULL(catP.NombreCategoria, 'SIN CATEGORÍA PADRE'),
    prov.NombreProveedor,
    p.PrecioUnitario,
    p.CostoUnitario,
    CAST((p.PrecioUnitario - p.CostoUnitario) * 100.0 / NULLIF(p.PrecioUnitario, 0) AS DECIMAL(5,2)),
    p.UnidadMedida,
    p.StockMinimo,
    p.Activo,
    'PENDIENTE'
FROM RetailOLTP.dbo.Productos p
JOIN RetailOLTP.dbo.Categorias cat  ON p.CategoriaID = cat.CategoriaID
LEFT JOIN RetailOLTP.dbo.Categorias catP ON cat.CategoriaParent = catP.CategoriaID
JOIN RetailOLTP.dbo.Proveedores prov ON p.ProveedorID = prov.ProveedorID;

PRINT '✔ STG_Productos cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 3. CARGAR STG_VENTAS (desnormalizado para el DW)
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_Ventas (
    VentaID, NumeroFactura, ClienteID, NombreCliente, TiendaID, NombreTienda,
    VendedorID, NombreVendedor, CanalID, NombreCanal, CampanaID, NombreCampana,
    FechaVenta, Anio, Mes, Dia, DiaSemana,
    Subtotal, TotalDescuento, TotalImpuesto, TotalVenta, Estado, FlagCalidad
)
SELECT
    v.VentaID,
    v.NumeroFactura,
    v.ClienteID,
    c.NombreCliente,
    v.TiendaID,
    t.NombreTienda,
    v.VendedorID,
    ve.NombreVendedor,
    v.CanalID,
    cv.NombreCanal,
    v.CampanaID,
    ISNULL(cam.NombreCampana, 'SIN CAMPAÑA'),
    v.FechaVenta,
    YEAR(v.FechaVenta),
    MONTH(v.FechaVenta),
    DAY(v.FechaVenta),
    DATEPART(WEEKDAY, v.FechaVenta),
    v.Subtotal,
    v.TotalDescuento,
    v.TotalImpuesto,
    v.TotalVenta,
    v.Estado,
    'PENDIENTE'
FROM RetailOLTP.dbo.Ventas v
JOIN RetailOLTP.dbo.Clientes   c   ON v.ClienteID  = c.ClienteID
JOIN RetailOLTP.dbo.Tiendas    t   ON v.TiendaID   = t.TiendaID
JOIN RetailOLTP.dbo.Vendedores ve  ON v.VendedorID = ve.VendedorID
JOIN RetailOLTP.dbo.CanalVenta cv  ON v.CanalID    = cv.CanalID
LEFT JOIN RetailOLTP.dbo.Campanas cam ON v.CampanaID = cam.CampanaID;

PRINT '✔ STG_Ventas cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 4. CARGAR STG_DETALLEVENTAS (tabla más grande: ~150K filas)
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_DetalleVentas (
    DetalleID, VentaID, NumeroFactura, ProductoID, CodigoSKU, NombreProducto,
    NombreCategoria, Cantidad, PrecioUnitario, CostoUnitario, DescuentoPct,
    TotalLinea, CostoTotal, MargenLinea, FechaVenta, FlagCalidad
)
SELECT
    dv.DetalleID,
    dv.VentaID,
    v.NumeroFactura,
    dv.ProductoID,
    p.CodigoSKU,
    p.NombreProducto,
    cat.NombreCategoria,
    dv.Cantidad,
    dv.PrecioUnitario,
    dv.CostoUnitario,
    dv.DescuentoPct,
    dv.TotalLinea,
    ROUND(dv.Cantidad * dv.CostoUnitario, 2),
    ROUND(dv.TotalLinea - (dv.Cantidad * dv.CostoUnitario), 2),
    v.FechaVenta,
    'PENDIENTE'
FROM RetailOLTP.dbo.DetalleVentas dv
JOIN RetailOLTP.dbo.Ventas      v   ON dv.VentaID    = v.VentaID
JOIN RetailOLTP.dbo.Productos   p   ON dv.ProductoID = p.ProductoID
JOIN RetailOLTP.dbo.Categorias  cat ON p.CategoriaID = cat.CategoriaID;

PRINT '✔ STG_DetalleVentas cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 5. CARGAR STG_INVENTARIO
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_Inventario (
    InventarioID, FechaInventario, ProductoID, CodigoSKU, NombreProducto,
    TiendaID, NombreTienda, StockInicial, Entradas, Salidas, Ajustes, StockFinal, FlagCalidad
)
SELECT
    inv.InventarioID,
    inv.FechaInventario,
    inv.ProductoID,
    p.CodigoSKU,
    p.NombreProducto,
    inv.TiendaID,
    t.NombreTienda,
    inv.StockInicial,
    inv.Entradas,
    inv.Salidas,
    inv.Ajustes,
    inv.StockFinal,
    'PENDIENTE'
FROM RetailOLTP.dbo.InventarioDiario inv
JOIN RetailOLTP.dbo.Productos p ON inv.ProductoID = p.ProductoID
JOIN RetailOLTP.dbo.Tiendas   t ON inv.TiendaID   = t.TiendaID;

PRINT '✔ STG_Inventario cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 6. CARGAR STG_METAS
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_Metas (
    MetaID, Anio, Mes, TiendaID, NombreTienda, CategoriaID, NombreCategoria,
    VendedorID, NombreVendedor, CanalID, NombreCanal, ValorMeta, FlagCalidad
)
SELECT
    m.MetaID,
    m.Anio,
    m.Mes,
    m.TiendaID,
    t.NombreTienda,
    m.CategoriaID,
    ISNULL(cat.NombreCategoria, 'TODAS LAS CATEGORIAS'),
    m.VendedorID,
    ISNULL(v.NombreVendedor, 'TODOS LOS VENDEDORES'),
    m.CanalID,
    ISNULL(cv.NombreCanal, 'TODOS LOS CANALES'),
    m.ValorMeta,
    'PENDIENTE'
FROM RetailOLTP.dbo.MetasComerciales m
JOIN RetailOLTP.dbo.Tiendas     t   ON m.TiendaID   = t.TiendaID
LEFT JOIN RetailOLTP.dbo.Categorias cat ON m.CategoriaID = cat.CategoriaID
LEFT JOIN RetailOLTP.dbo.Vendedores v   ON m.VendedorID  = v.VendedorID
LEFT JOIN RetailOLTP.dbo.CanalVenta cv  ON m.CanalID     = cv.CanalID;

PRINT '✔ STG_Metas cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 7. CARGAR STG_DEVOLUCIONES
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_Devoluciones (
    DevolucionID, VentaID, NumeroFactura, ClienteID, NombreCliente,
    TiendaID, NombreTienda, ProductoID, NombreProducto,
    FechaDevolucion, MotivoDevolucion, CantidadDevuelta, ValorDevuelto, FlagCalidad
)
SELECT
    d.DevolucionID,
    d.VentaID,
    v.NumeroFactura,
    d.ClienteID,
    c.NombreCliente,
    d.TiendaID,
    t.NombreTienda,
    d.ProductoID,
    p.NombreProducto,
    d.FechaDevolucion,
    d.MotivoDevolucion,
    d.CantidadDevuelta,
    d.ValorDevuelto,
    'PENDIENTE'
FROM RetailOLTP.dbo.Devoluciones d
JOIN RetailOLTP.dbo.Ventas    v ON d.VentaID    = v.VentaID
JOIN RetailOLTP.dbo.Clientes  c ON d.ClienteID  = c.ClienteID
JOIN RetailOLTP.dbo.Tiendas   t ON d.TiendaID   = t.TiendaID
JOIN RetailOLTP.dbo.Productos p ON d.ProductoID = p.ProductoID;

PRINT '✔ STG_Devoluciones cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 8. CARGAR STG_COMPRAS
-- ============================================================
INSERT INTO BI_Staging.dbo.STG_Compras (
    CompraID, NumeroOrden, ProveedorID, NombreProveedor, TiendaID, NombreTienda,
    FechaOrden, FechaRecepcion, DiasEntrega, TotalCompra, Estado, FlagCalidad
)
SELECT
    comp.CompraID,
    comp.NumeroOrden,
    comp.ProveedorID,
    prov.NombreProveedor,
    comp.TiendaID,
    t.NombreTienda,
    comp.FechaOrden,
    comp.FechaRecepcion,
    ISNULL(DATEDIFF(DAY, comp.FechaOrden, comp.FechaRecepcion), 0),
    comp.TotalCompra,
    comp.Estado,
    'PENDIENTE'
FROM RetailOLTP.dbo.Compras comp
JOIN RetailOLTP.dbo.Proveedores prov ON comp.ProveedorID = prov.ProveedorID
JOIN RetailOLTP.dbo.Tiendas     t    ON comp.TiendaID    = t.TiendaID;

PRINT '✔ STG_Compras cargado: ' + CAST(@@ROWCOUNT AS VARCHAR) + ' registros';
GO

-- ============================================================
-- 9. IMPORTAR FUENTES EXTERNAS CSV
--    En entornos cloud como AWS RDS no se puede usar BULK INSERT 
--    desde archivos locales. La insercion a las tablas:
--    - BI_Staging.dbo.STG_MetasExternas
--    - BI_Staging.dbo.STG_InventarioFisico
--    se realiza a traves de script Python o el asistente SSMS Import.
-- ============================================================

PRINT '✔ Las fuentes externas (CSV) deben ser importadas vía script Python o SSMS Import en entornos RDS.';
GO

-- ============================================================
-- RESUMEN DE CARGA
-- ============================================================
PRINT '';
PRINT '=== RESUMEN DE CARGA AL STAGING ===';
SELECT 'STG_Clientes'        AS Tabla, COUNT(*) AS Total FROM STG_Clientes
UNION ALL SELECT 'STG_Productos',      COUNT(*) FROM STG_Productos
UNION ALL SELECT 'STG_Ventas',         COUNT(*) FROM STG_Ventas
UNION ALL SELECT 'STG_DetalleVentas',  COUNT(*) FROM STG_DetalleVentas
UNION ALL SELECT 'STG_Inventario',     COUNT(*) FROM STG_Inventario
UNION ALL SELECT 'STG_Metas',          COUNT(*) FROM STG_Metas
UNION ALL SELECT 'STG_Devoluciones',   COUNT(*) FROM STG_Devoluciones
UNION ALL SELECT 'STG_Compras',        COUNT(*) FROM STG_Compras
UNION ALL SELECT 'STG_MetasExternas',  COUNT(*) FROM STG_MetasExternas
UNION ALL SELECT 'STG_InventarioFisico', COUNT(*) FROM STG_InventarioFisico
ORDER BY Tabla;

PRINT '=== Carga Staging completada: ' + CAST(GETDATE() AS VARCHAR) + ' ===';
