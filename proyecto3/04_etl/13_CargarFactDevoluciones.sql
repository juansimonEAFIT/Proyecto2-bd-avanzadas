-- ============================================================
-- PROYECTO 3 - BI análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 13_CargarFactDevoluciones.sql
-- Granularidad: una devolución por fila

USE RetailDW;
GO

CREATE OR ALTER PROCEDURE CargarFactDevoluciones
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT = 0, @cargados INT = 0, @rechazados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarFactDevoluciones', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM BI_Staging.dbo.STG_Devoluciones WHERE FlagCalidad = 'OK');

        INSERT INTO FactDevoluciones (
            FechaKey, ClienteKey, ProductoKey, TiendaKey,
            DevolucionID, VentaID, FechaDevolucion, MotivoDevolucion,
            CantidadDevuelta, ValorDevuelto
        )
        SELECT
            COALESCE(
                (SELECT FechaKey FROM DimFecha
                 WHERE Fecha = CAST(d.FechaDevolucion AS DATE)), -1),
            COALESCE(
                (SELECT TOP 1 ClienteKey FROM DimCliente
                 WHERE ClienteID = d.ClienteID AND EsVersionActual = 1), -1),
            COALESCE(
                (SELECT TOP 1 ProductoKey FROM DimProducto
                 WHERE ProductoID = d.ProductoID AND EsVersionActual = 1), -1),
            COALESCE(
                (SELECT TOP 1 TiendaKey FROM DimTienda WHERE TiendaID = d.TiendaID), -1),
            d.DevolucionID,
            d.VentaID,
            CAST(d.FechaDevolucion AS DATE),
            d.MotivoDevolucion,
            d.CantidadDevuelta,
            d.ValorDevuelto
        FROM BI_Staging.dbo.STG_Devoluciones d
        WHERE d.FlagCalidad = 'OK'
          AND NOT EXISTS (
              SELECT 1 FROM FactDevoluciones fd WHERE fd.DevolucionID = d.DevolucionID
          );

        SET @cargados = @@ROWCOUNT;
        SET @rechazados = @leidos - @cargados;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @rechazados, NULL;
        PRINT '✔ CargarFactDevoluciones: ' + CAST(@cargados AS VARCHAR) + ' registros cargados';
    END TRY
    BEGIN CATCH
        DECLARE @errMsg VARCHAR(MAX) = ERROR_MESSAGE();
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', @leidos, @cargados, @rechazados, @errMsg;
        THROW;
    END CATCH
END;
GO

EXEC CargarFactDevoluciones;
GO
