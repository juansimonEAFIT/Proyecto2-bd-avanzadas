-- ============================================================
-- PROYECTO 3 - BI análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 11_CargarFactInventario.sql
-- Granularidad: día × producto × tienda
-- Medidas: StockFinal (SEMI-ADITIVA), Entradas/Salidas (ADITIVAS)
-- ============================================================

USE RetailDW;
GO

CREATE OR ALTER PROCEDURE CargarFactInventarioDiario
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT = 0, @cargados INT = 0, @rechazados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarFactInventarioDiario', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM BI_Staging.dbo.STG_Inventario WHERE FlagCalidad = 'OK');

        INSERT INTO FactInventarioDiario (
            FechaKey, ProductoKey, TiendaKey,
            InventarioID, FechaInventario,
            StockInicial, Entradas, Salidas, Ajustes, StockFinal
        )
        SELECT
            COALESCE(
                (SELECT FechaKey FROM DimFecha WHERE Fecha = si.FechaInventario), -1),
            COALESCE(
                (SELECT TOP 1 ProductoKey FROM DimProducto
                 WHERE ProductoID = si.ProductoID AND EsVersionActual = 1), -1),
            COALESCE(
                (SELECT TOP 1 TiendaKey FROM DimTienda WHERE TiendaID = si.TiendaID), -1),
            si.InventarioID,
            si.FechaInventario,
            si.StockInicial,
            si.Entradas,
            si.Salidas,
            si.Ajustes,
            si.StockFinal
        FROM BI_Staging.dbo.STG_Inventario si
        WHERE si.FlagCalidad = 'OK'
          AND NOT EXISTS (
              SELECT 1 FROM FactInventarioDiario fi WHERE fi.InventarioID = si.InventarioID
          );

        SET @cargados = @@ROWCOUNT;
        SET @rechazados = @leidos - @cargados;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @rechazados, NULL;
        PRINT '✔ CargarFactInventarioDiario: ' + CAST(@cargados AS VARCHAR) + ' registros cargados';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', @leidos, @cargados, @rechazados, ERROR_MESSAGE();
        THROW;
    END CATCH
END;
GO

EXEC CargarFactInventarioDiario;
GO
