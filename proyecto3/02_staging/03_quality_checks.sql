-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 2: Sebastian Duran
-- Script: 03_quality_checks.sql
-- Descripción: Transformaciones de calidad de datos en Staging.
--   - Limpieza de nulos
--   - Estandarización de ciudades y regiones
--   - Normalización de categorías
--   - Detección de duplicados
--   - Validación de fechas
--   - Validación de integridad referencial
--   - Cálculo de campos derivados
-- Ejecutar DESPUÉS de 02_load_staging.sql
-- ============================================================

USE BI_Staging;
GO

SET NOCOUNT ON;
PRINT '=== Iniciando validaciones de calidad de datos ===';
PRINT CAST(GETDATE() AS VARCHAR);
GO

-- ============================================================
-- HELPER: Registrar resultado en QA_Reporte
-- ============================================================
-- Se llama después de cada bloque de validación:
-- INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
-- VALUES (...)

-- ============================================================
-- 1. LIMPIEZA DE NULOS EN STG_CLIENTES
-- ============================================================
PRINT '--- [1/8] Limpiando nulos en STG_Clientes...';

-- Email nulo → valor por defecto
UPDATE STG_Clientes
SET Email = 'sin_email@retailpro.com.co',
    ObsCalidad = ISNULL(ObsCalidad + ' | ', '') + 'Email nulo reemplazado'
WHERE Email IS NULL OR LTRIM(RTRIM(Email)) = '';

-- Teléfono nulo → valor por defecto
UPDATE STG_Clientes
SET Telefono = '0000000000',
    ObsCalidad = ISNULL(ObsCalidad + ' | ', '') + 'Telefono nulo reemplazado'
WHERE Telefono IS NULL OR LTRIM(RTRIM(Telefono)) = '';

-- Ciudad nula → DESCONOCIDA
UPDATE STG_Clientes
SET CiudadNombre = 'DESCONOCIDA',
    Departamento = 'DESCONOCIDO',
    Region = 'DESCONOCIDA',
    ObsCalidad = ISNULL(ObsCalidad + ' | ', '') + 'Ciudad nula'
WHERE CiudadNombre IS NULL;

-- Estandarizar nombres de ciudades (UPPER + TRIM + sin tildes comunes)
UPDATE STG_Clientes
SET CiudadNombre = UPPER(LTRIM(RTRIM(
    REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
        CiudadNombre, 'á','a'), 'é','e'), 'í','i'), 'ó','o'), 'ú','u')
)));

UPDATE STG_Clientes
SET Departamento = UPPER(LTRIM(RTRIM(Departamento)));

UPDATE STG_Clientes
SET Region = UPPER(LTRIM(RTRIM(Region)));

DECLARE @total_cli INT = (SELECT COUNT(*) FROM STG_Clientes);
DECLARE @error_cli INT = (SELECT COUNT(*) FROM STG_Clientes WHERE ObsCalidad IS NOT NULL);
DECLARE @ok_cli    INT = @total_cli - @error_cli;

INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
VALUES ('STG_Clientes', 'Limpieza Nulos + Estandarizacion',
        @total_cli, @ok_cli, @error_cli,
        CAST(@error_cli * 100.0 / NULLIF(@total_cli, 0) AS DECIMAL(5,2)),
        'Email/Telefono/Ciudad nulos corregidos; campos estandarizados a UPPER');

PRINT '  ✔ STG_Clientes: ' + CAST(@error_cli AS VARCHAR) + ' registros con observaciones';
GO

-- ============================================================
-- 2. NORMALIZACIÓN DE CATEGORÍAS EN STG_PRODUCTOS
-- ============================================================
PRINT '--- [2/8] Normalizando categorías en STG_Productos...';

UPDATE STG_Productos
SET NombreCategoria = UPPER(LTRIM(RTRIM(NombreCategoria)));

-- Unificar variantes comunes de nombres de categoría
UPDATE STG_Productos
SET NombreCategoria = CASE
    WHEN NombreCategoria IN ('ELECTRONICA','ELECTRONICO','ELECTRÓNICA') THEN 'ELECTRÓNICA'
    WHEN NombreCategoria IN ('ROPA','ROPA Y CALZADO','VESTIDO') THEN 'ROPA Y CALZADO'
    WHEN NombreCategoria IN ('ALIMENTO','ALIMENTOS','ALIMENTACION') THEN 'ALIMENTOS'
    WHEN NombreCategoria IN ('HOGAR','HOGAR Y DECO','DECORACION') THEN 'HOGAR Y DECO'
    ELSE NombreCategoria
END;

-- Detectar productos con margen negativo (precio < costo)
UPDATE STG_Productos
SET FlagCalidad = 'RECHAZADO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'Margen negativo: precio < costo'
WHERE PrecioUnitario < CostoUnitario;

-- Detectar productos con precio = 0
UPDATE STG_Productos
SET FlagCalidad = 'RECHAZADO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'Precio o costo = 0'
WHERE PrecioUnitario <= 0 OR CostoUnitario <= 0;

DECLARE @total_prod INT = (SELECT COUNT(*) FROM STG_Productos);
DECLARE @error_prod INT = (SELECT COUNT(*) FROM STG_Productos WHERE FlagCalidad = 'RECHAZADO');

INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
VALUES ('STG_Productos', 'Normalizacion Categorias + Validacion Precios',
        @total_prod, @total_prod - @error_prod, @error_prod,
        CAST(@error_prod * 100.0 / NULLIF(@total_prod, 0) AS DECIMAL(5,2)),
        'Categorias normalizadas; productos con margen negativo marcados como RECHAZADO');

PRINT '  ✔ STG_Productos: ' + CAST(@error_prod AS VARCHAR) + ' productos rechazados';
GO

-- ============================================================
-- 3. VALIDACIÓN DE FECHAS EN STG_VENTAS
-- ============================================================
PRINT '--- [3/8] Validando fechas en STG_Ventas...';

-- Marcar fechas futuras como sospechosas
UPDATE STG_Ventas
SET FlagCalidad = 'SOSPECHOSO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'Fecha de venta en el futuro'
WHERE FechaVenta > GETDATE();

-- Marcar fechas anteriores al sistema (antes de 2020)
UPDATE STG_Ventas
SET FlagCalidad = 'SOSPECHOSO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'Fecha anterior al año 2020'
WHERE YEAR(FechaVenta) < 2020;

-- Ventas anuladas se marcan pero no se rechazan (van al DW como indicador)
UPDATE STG_Ventas
SET ObsCalidad = ISNULL(ObsCalidad + ' | ', '') + 'Venta anulada - incluida para análisis'
WHERE Estado = 'Anulada';

-- Ventas con TotalVenta <= 0 (sospechosas excepto anuladas)
UPDATE STG_Ventas
SET FlagCalidad = 'RECHAZADO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'TotalVenta <= 0 sin estado Anulada'
WHERE TotalVenta <= 0 AND Estado != 'Anulada';

-- Marcar como OK las que no tienen problemas
UPDATE STG_Ventas SET FlagCalidad = 'OK'
WHERE FlagCalidad = 'PENDIENTE';

DECLARE @total_v INT = (SELECT COUNT(*) FROM STG_Ventas);
DECLARE @error_v INT = (SELECT COUNT(*) FROM STG_Ventas WHERE FlagCalidad IN ('RECHAZADO','SOSPECHOSO'));

INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
VALUES ('STG_Ventas', 'Validacion Fechas + Estado + Totales',
        @total_v, @total_v - @error_v, @error_v,
        CAST(@error_v * 100.0 / NULLIF(@total_v, 0) AS DECIMAL(5,2)),
        'Fechas futuras y anteriores a 2020 marcadas; totales negativos rechazados');

PRINT '  ✔ STG_Ventas: ' + CAST(@error_v AS VARCHAR) + ' ventas con problemas';
GO

-- ============================================================
-- 4. VALIDACIÓN DE LÍNEAS DE VENTA EN STG_DETALLEVENTAS
-- ============================================================
PRINT '--- [4/8] Validando STG_DetalleVentas...';

-- Líneas con cantidad <= 0
UPDATE STG_DetalleVentas
SET FlagCalidad = 'RECHAZADO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'Cantidad <= 0'
WHERE Cantidad <= 0;

-- Líneas con precio o costo <= 0
UPDATE STG_DetalleVentas
SET FlagCalidad = 'RECHAZADO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'PrecioUnitario o CostoUnitario <= 0'
WHERE PrecioUnitario <= 0 OR CostoUnitario <= 0;

-- Líneas huérfanas (sin venta en STG_Ventas)
UPDATE dv
SET dv.FlagCalidad = 'RECHAZADO',
    dv.ObsCalidad  = ISNULL(dv.ObsCalidad + ' | ', '') + 'VentaID sin cabecera en STG_Ventas'
FROM STG_DetalleVentas dv
LEFT JOIN STG_Ventas v ON dv.VentaID = v.VentaID
WHERE v.VentaID IS NULL;

-- Líneas huérfanas (sin producto en STG_Productos)
UPDATE dv
SET dv.FlagCalidad = 'RECHAZADO',
    dv.ObsCalidad  = ISNULL(dv.ObsCalidad + ' | ', '') + 'ProductoID sin referencia en STG_Productos'
FROM STG_DetalleVentas dv
LEFT JOIN STG_Productos p ON dv.ProductoID = p.ProductoID
WHERE p.ProductoID IS NULL;

-- Marcar las buenas como OK
UPDATE STG_DetalleVentas SET FlagCalidad = 'OK'
WHERE FlagCalidad = 'PENDIENTE';

DECLARE @total_dv INT = (SELECT COUNT(*) FROM STG_DetalleVentas);
DECLARE @error_dv INT = (SELECT COUNT(*) FROM STG_DetalleVentas WHERE FlagCalidad = 'RECHAZADO');

INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
VALUES ('STG_DetalleVentas', 'Integridad Referencial + Cantidades + Precios',
        @total_dv, @total_dv - @error_dv, @error_dv,
        CAST(@error_dv * 100.0 / NULLIF(@total_dv, 0) AS DECIMAL(5,2)),
        'Líneas huerfanas, cantidades y precios inválidos marcados como RECHAZADO');

PRINT '  ✔ STG_DetalleVentas: ' + CAST(@error_dv AS VARCHAR) + ' líneas rechazadas';
GO

-- ============================================================
-- 5. DETECCIÓN DE DUPLICADOS EN STG_VENTAS
-- ============================================================
PRINT '--- [5/8] Detectando duplicados en STG_Ventas...';

WITH CTE_Dup AS (
    SELECT VentaID,
           ROW_NUMBER() OVER (
               PARTITION BY NumeroFactura
               ORDER BY VentaID
           ) AS rn
    FROM STG_Ventas
)
UPDATE sv
SET sv.EsDuplicado = 1,
    sv.ObsCalidad  = ISNULL(sv.ObsCalidad + ' | ', '') + 'Número de factura duplicado'
FROM STG_Ventas sv
JOIN CTE_Dup c ON sv.VentaID = c.VentaID
WHERE c.rn > 1;

DECLARE @dup_v INT = (SELECT COUNT(*) FROM STG_Ventas WHERE EsDuplicado = 1);
INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
VALUES ('STG_Ventas', 'Deteccion Duplicados NumeroFactura',
        (SELECT COUNT(*) FROM STG_Ventas), (SELECT COUNT(*) FROM STG_Ventas WHERE EsDuplicado = 0),
        @dup_v,
        CAST(@dup_v * 100.0 / NULLIF((SELECT COUNT(*) FROM STG_Ventas), 0) AS DECIMAL(5,2)),
        'Duplicados por NumeroFactura: solo se carga el primer registro');

PRINT '  ✔ Duplicados en STG_Ventas: ' + CAST(@dup_v AS VARCHAR);
GO

-- ============================================================
-- 6. VALIDACIÓN DE INVENTARIO
-- ============================================================
PRINT '--- [6/8] Validando STG_Inventario...';

-- StockFinal negativo (error de datos)
UPDATE STG_Inventario
SET FlagCalidad = 'SOSPECHOSO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'StockFinal negativo'
WHERE StockFinal < 0;

-- Registros sin producto en staging
UPDATE si
SET si.FlagCalidad = 'RECHAZADO',
    si.ObsCalidad  = ISNULL(si.ObsCalidad + ' | ', '') + 'ProductoID sin referencia'
FROM STG_Inventario si
LEFT JOIN STG_Productos p ON si.ProductoID = p.ProductoID
WHERE p.ProductoID IS NULL;

UPDATE STG_Inventario SET FlagCalidad = 'OK' WHERE FlagCalidad = 'PENDIENTE';

DECLARE @total_inv INT = (SELECT COUNT(*) FROM STG_Inventario);
DECLARE @error_inv INT = (SELECT COUNT(*) FROM STG_Inventario WHERE FlagCalidad != 'OK');

INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
VALUES ('STG_Inventario', 'Validacion Stock Negativo + Integridad Referencial',
        @total_inv, @total_inv - @error_inv, @error_inv,
        CAST(@error_inv * 100.0 / NULLIF(@total_inv, 0) AS DECIMAL(5,2)),
        'Stock negativo marcado como SOSPECHOSO; productos sin referencia como RECHAZADO');

PRINT '  ✔ STG_Inventario: ' + CAST(@error_inv AS VARCHAR) + ' registros con problemas';
GO

-- ============================================================
-- 7. VALIDACIÓN DE METAS EXTERNAS (CSV)
-- ============================================================
PRINT '--- [7/8] Validando STG_MetasExternas...';

-- Metas con valor <= 0
UPDATE STG_MetasExternas
SET FlagCalidad = 'RECHAZADO',
    ObsCalidad  = 'ValorMeta <= 0'
WHERE ValorMeta <= 0 OR ValorMeta IS NULL;

-- Metas con mes fuera de rango
UPDATE STG_MetasExternas
SET FlagCalidad = 'RECHAZADO',
    ObsCalidad  = ISNULL(ObsCalidad + ' | ', '') + 'Mes fuera de rango (1-12)'
WHERE Mes < 1 OR Mes > 12 OR Mes IS NULL;

-- Marcar como OK las válidas
UPDATE STG_MetasExternas SET FlagCalidad = 'OK' WHERE FlagCalidad = 'PENDIENTE';

DECLARE @total_me INT = (SELECT COUNT(*) FROM STG_MetasExternas);
DECLARE @error_me INT = (SELECT COUNT(*) FROM STG_MetasExternas WHERE FlagCalidad = 'RECHAZADO');

INSERT INTO QA_Reporte (TablaOrigen, TipoValidacion, TotalRegistros, RegistrosOK, RegistrosError, PctError, Detalle)
VALUES ('STG_MetasExternas', 'Validacion ValorMeta y Mes',
        @total_me, @total_me - @error_me, @error_me,
        CAST(@error_me * 100.0 / NULLIF(@total_me, 0) AS DECIMAL(5,2)),
        'Metas con valor <= 0 o mes inválido rechazadas');

PRINT '  ✔ STG_MetasExternas validado';
GO

-- ============================================================
-- 8. MARCAR COMO OK LOS REGISTROS SIN PROBLEMAS
-- ============================================================
UPDATE STG_Clientes    SET FlagCalidad = 'OK' WHERE FlagCalidad = 'PENDIENTE';
UPDATE STG_Productos   SET FlagCalidad = 'OK' WHERE FlagCalidad = 'PENDIENTE';
UPDATE STG_Metas       SET FlagCalidad = 'OK' WHERE FlagCalidad = 'PENDIENTE';
UPDATE STG_Devoluciones SET FlagCalidad = 'OK' WHERE FlagCalidad = 'PENDIENTE';
UPDATE STG_Compras     SET FlagCalidad = 'OK' WHERE FlagCalidad = 'PENDIENTE';
GO

-- ============================================================
-- RESUMEN FINAL DEL QA
-- ============================================================
PRINT '';
PRINT '=== REPORTE DE CALIDAD DE DATOS ===';
SELECT
    TablaOrigen,
    TipoValidacion,
    TotalRegistros,
    RegistrosOK,
    RegistrosError,
    PctError AS ErrorPct,
    Detalle
FROM QA_Reporte
ORDER BY FechaEjecucion;

PRINT '=== Validaciones de calidad completadas: ' + CAST(GETDATE() AS VARCHAR) + ' ===';
