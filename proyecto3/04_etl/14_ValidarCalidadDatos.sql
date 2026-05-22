-- ============================================================
-- PROYECTO 3 - BI análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 14_ValidarCalidadDatos.sql
-- Descripción: Consultas de validación post-ETL del Data Warehouse.
--   Compara totales OLTP vs DW, verifica integridad referencial,
--   detecta NULLs en medidas críticas y valida surrogate keys.
-- ============================================================

USE RetailDW;
GO

SET NOCOUNT ON;
PRINT '=========================================================';
PRINT ' INFORME DE VALIDACIÓN DEL DATA WAREHOUSE — RetailDW';
PRINT ' Fecha: ' + CAST(GETDATE() AS VARCHAR);
PRINT '=========================================================';
PRINT '';

-- ============================================================
-- 1. CONTEO DE REGISTROS EN TODAS LAS TABLAS
-- ============================================================
PRINT '--- [1] VOLÚMENES DEL DATA WAREHOUSE ---';
SELECT
    t.name AS Tabla,
    SUM(p.rows) AS TotalFilas
FROM sys.tables t
JOIN sys.partitions p ON t.object_id = p.object_id
WHERE p.index_id IN (0,1)
  AND t.name IN (
    'DimFecha','DimGeografia','DimCliente','DimProducto','DimTienda',
    'DimVendedor','DimProveedor','DimCanalVenta','DimPromocion',
    'FactVentas','FactInventarioDiario','FactMetasComerciales','FactDevoluciones',
    'ETL_Log'
  )
GROUP BY t.name
ORDER BY t.name;
GO

-- ============================================================
-- 2. COMPARACIÓN DE TOTALES OLTP vs DW
-- ============================================================
PRINT '--- [2] COMPARACIÓN OLTP vs DW ---';
SELECT
    'Líneas de venta'           AS Concepto,
    (SELECT COUNT(*) FROM RetailOLTP.dbo.DetalleVentas)      AS OLTP_Total,
    (SELECT COUNT(*) FROM RetailDW.dbo.FactVentas)            AS DW_Total,
    (SELECT COUNT(*) FROM RetailOLTP.dbo.DetalleVentas) -
    (SELECT COUNT(*) FROM RetailDW.dbo.FactVentas)            AS Diferencia

UNION ALL SELECT
    'Total Ventas ($)',
    CAST((SELECT SUM(TotalLinea) FROM RetailOLTP.dbo.DetalleVentas) AS INT),
    CAST((SELECT SUM(ValorVenta) FROM RetailDW.dbo.FactVentas)      AS INT),
    CAST((SELECT SUM(TotalLinea) FROM RetailOLTP.dbo.DetalleVentas) AS INT) -
    CAST((SELECT SUM(ValorVenta) FROM RetailDW.dbo.FactVentas)      AS INT)

UNION ALL SELECT
    'Registros inventario',
    (SELECT COUNT(*) FROM RetailOLTP.dbo.InventarioDiario),
    (SELECT COUNT(*) FROM RetailDW.dbo.FactInventarioDiario),
    (SELECT COUNT(*) FROM RetailOLTP.dbo.InventarioDiario) -
    (SELECT COUNT(*) FROM RetailDW.dbo.FactInventarioDiario)

UNION ALL SELECT
    'Metas comerciales',
    (SELECT COUNT(*) FROM RetailOLTP.dbo.MetasComerciales),
    (SELECT COUNT(*) FROM RetailDW.dbo.FactMetasComerciales),
    (SELECT COUNT(*) FROM RetailOLTP.dbo.MetasComerciales) -
    (SELECT COUNT(*) FROM RetailDW.dbo.FactMetasComerciales)

UNION ALL SELECT
    'Devoluciones',
    (SELECT COUNT(*) FROM RetailOLTP.dbo.Devoluciones),
    (SELECT COUNT(*) FROM RetailDW.dbo.FactDevoluciones),
    (SELECT COUNT(*) FROM RetailOLTP.dbo.Devoluciones) -
    (SELECT COUNT(*) FROM RetailDW.dbo.FactDevoluciones);
GO

-- ============================================================
-- 3. SURROGATE KEYS SIN RESOLVER (valor -1)
-- ============================================================
PRINT '--- [3] SURROGATE KEYS SIN RESOLVER (deben ser 0 idealmente) ---';
SELECT
    'FactVentas - Sin Fecha'     AS Problema,
    COUNT(*) AS Cantidad
FROM FactVentas WHERE FechaKey = -1

UNION ALL SELECT 'FactVentas - Sin Cliente',   COUNT(*) FROM FactVentas WHERE ClienteKey  = -1
UNION ALL SELECT 'FactVentas - Sin Producto',  COUNT(*) FROM FactVentas WHERE ProductoKey = -1
UNION ALL SELECT 'FactVentas - Sin Tienda',    COUNT(*) FROM FactVentas WHERE TiendaKey   = -1
UNION ALL SELECT 'FactVentas - Sin Vendedor',  COUNT(*) FROM FactVentas WHERE VendedorKey = -1
UNION ALL SELECT 'FactVentas - Sin Canal',     COUNT(*) FROM FactVentas WHERE CanalKey    = -1
UNION ALL SELECT 'FactInv   - Sin Fecha',      COUNT(*) FROM FactInventarioDiario WHERE FechaKey    = -1
UNION ALL SELECT 'FactInv   - Sin Producto',   COUNT(*) FROM FactInventarioDiario WHERE ProductoKey = -1
UNION ALL SELECT 'FactInv   - Sin Tienda',     COUNT(*) FROM FactInventarioDiario WHERE TiendaKey   = -1
UNION ALL SELECT 'FactDev   - Sin Cliente',    COUNT(*) FROM FactDevoluciones     WHERE ClienteKey  = -1;
GO

-- ============================================================
-- 4. NULOS EN MEDIDAS CRÍTICAS DE HECHOS
-- ============================================================
PRINT '--- [4] NULOS EN MEDIDAS CRÍTICAS ---';
SELECT
    'FactVentas.ValorVenta NULL'   AS Campo, COUNT(*) AS Cantidad
FROM FactVentas WHERE ValorVenta IS NULL

UNION ALL SELECT 'FactVentas.CostoTotal NULL',    COUNT(*) FROM FactVentas WHERE CostoTotal IS NULL
UNION ALL SELECT 'FactVentas.Cantidad NULL',       COUNT(*) FROM FactVentas WHERE Cantidad   IS NULL
UNION ALL SELECT 'FactInv.StockFinal NULL',        COUNT(*) FROM FactInventarioDiario WHERE StockFinal IS NULL
UNION ALL SELECT 'FactMetas.ValorMeta NULL',       COUNT(*) FROM FactMetasComerciales WHERE ValorMeta IS NULL
UNION ALL SELECT 'FactDev.ValorDevuelto NULL',     COUNT(*) FROM FactDevoluciones WHERE ValorDevuelto IS NULL;
GO

-- ============================================================
-- 5. VALORES NEGATIVOS INCORRECTOS EN MEDIDAS
-- ============================================================
PRINT '--- [5] VALORES NEGATIVOS INCORRECTOS ---';
SELECT 'FactVentas.ValorVenta < 0'  AS Campo, COUNT(*) AS Cantidad
FROM FactVentas WHERE ValorVenta < 0

UNION ALL SELECT 'FactVentas.CostoTotal < 0',  COUNT(*) FROM FactVentas WHERE CostoTotal < 0
UNION ALL SELECT 'FactInv.StockFinal < 0',     COUNT(*) FROM FactInventarioDiario WHERE StockFinal < 0
UNION ALL SELECT 'FactMetas.ValorMeta < 0',    COUNT(*) FROM FactMetasComerciales WHERE ValorMeta < 0
UNION ALL SELECT 'FactDev.ValorDevuelto < 0',  COUNT(*) FROM FactDevoluciones WHERE ValorDevuelto < 0;
GO

-- ============================================================
-- 6. COBERTURA DE FECHAS EN DimFecha vs FactVentas
-- ============================================================
PRINT '--- [6] COBERTURA DE FECHAS ---';
SELECT
    MIN(fv.FechaVenta) AS FechaMinVenta,
    MAX(fv.FechaVenta) AS FechaMaxVenta,
    (SELECT MIN(Fecha) FROM DimFecha WHERE FechaKey > 0) AS FechaMinDimFecha,
    (SELECT MAX(Fecha) FROM DimFecha WHERE FechaKey > 0) AS FechaMaxDimFecha,
    COUNT(DISTINCT fv.FechaVenta)  AS DiasDistintosConVenta,
    (SELECT COUNT(*) FROM DimFecha WHERE FechaKey > 0) AS DiasEnDimFecha
FROM FactVentas fv;
GO

-- ============================================================
-- 7. RESUMEN DEL ETL_LOG (todos los procesos ejecutados)
-- ============================================================
PRINT '--- [7] RESUMEN ETL_LOG ---';
SELECT
    NombreProceso,
    Estado,
    RegistrosLeidos,
    RegistrosCargados,
    RegistrosRechazados,
    CAST(RegistrosCargados * 100.0 / NULLIF(RegistrosLeidos,0) AS DECIMAL(5,2)) AS TasaExitoPct,
    DATEDIFF(SECOND, FechaInicio, FechaFin) AS DuracionSeg,
    ISNULL(MensajeError, '—') AS MensajeError
FROM ETL_Log
ORDER BY FechaInicio;
GO

-- ============================================================
-- 8. TOP 5 VENTAS POR TIENDA (prueba analítica rápida)
-- ============================================================
PRINT '--- [8] VENTAS TOTALES POR TIENDA (prueba analítica) ---';
SELECT TOP 5
    t.NombreTienda,
    t.Ciudad,
    COUNT(fv.FactVentaID)           AS NumLineas,
    SUM(fv.ValorVenta)              AS TotalVentas,
    SUM(fv.CostoTotal)              AS TotalCosto,
    CAST(SUM(fv.MargenBruto) * 100.0
         / NULLIF(SUM(fv.ValorVenta),0) AS DECIMAL(5,2)) AS MargenPct
FROM FactVentas fv
JOIN DimTienda t ON fv.TiendaKey = t.TiendaKey
WHERE t.TiendaKey > 0
GROUP BY t.NombreTienda, t.Ciudad
ORDER BY TotalVentas DESC;
GO

PRINT '';
PRINT '=========================================================';
PRINT ' FIN DEL INFORME DE VALIDACIÓN';
PRINT '=========================================================';
