-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 10_CargarFactVentas.sql
-- Descripción: Carga FactVentas desde el Staging resolviendo
--              todas las surrogate keys de las dimensiones.
-- Granularidad: Una fila por línea de venta (DetalleVentas)
-- ============================================================

USE RetailDW;
GO

CREATE OR ALTER PROCEDURE CargarFactVentas
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID      INT;
    DECLARE @leidos     INT = 0;
    DECLARE @cargados   INT = 0;
    DECLARE @rechazados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarFactVentas', @LogID OUTPUT;

    BEGIN TRY
        -- Contar registros fuente (líneas válidas, sin duplicados de cabecera)
        SET @leidos = (
            SELECT COUNT(*)
            FROM BI_Staging.dbo.STG_DetalleVentas dv
            JOIN BI_Staging.dbo.STG_Ventas v ON dv.VentaID = v.VentaID
            WHERE dv.FlagCalidad = 'OK'
              AND v.EsDuplicado  = 0
        );

        -- --------------------------------------------------------
        -- INSERT principal: resuelve surrogate keys con COALESCE(-1)
        -- --------------------------------------------------------
        INSERT INTO FactVentas (
            FechaKey, ClienteKey, ProductoKey, TiendaKey, VendedorKey, CanalKey, PromocionKey,
            VentaID, DetalleID, NumeroFactura, EstadoVenta, FechaVenta,
            Cantidad, PrecioUnitario, ValorBruto, Descuento, ValorVenta, CostoTotal, MargenBruto
        )
        SELECT
            -- FechaKey: YYYYMMDD
            COALESCE(
                (SELECT FechaKey FROM DimFecha
                 WHERE Fecha = CAST(v.FechaVenta AS DATE)),
                -1
            ),

            -- ClienteKey
            COALESCE(
                (SELECT TOP 1 ClienteKey FROM DimCliente
                 WHERE ClienteID = v.ClienteID AND EsVersionActual = 1),
                -1
            ),

            -- ProductoKey
            COALESCE(
                (SELECT TOP 1 ProductoKey FROM DimProducto
                 WHERE ProductoID = dv.ProductoID AND EsVersionActual = 1),
                -1
            ),

            -- TiendaKey
            COALESCE(
                (SELECT TOP 1 TiendaKey FROM DimTienda
                 WHERE TiendaID = v.TiendaID),
                -1
            ),

            -- VendedorKey
            COALESCE(
                (SELECT TOP 1 VendedorKey FROM DimVendedor
                 WHERE VendedorID = v.VendedorID),
                -1
            ),

            -- CanalKey
            COALESCE(
                (SELECT TOP 1 CanalKey FROM DimCanalVenta
                 WHERE CanalID = v.CanalID),
                -1
            ),

            -- PromocionKey (NULL campaña → -1 = SIN CAMPAÑA)
            COALESCE(
                (SELECT TOP 1 PromocionKey FROM DimPromocion
                 WHERE CampanaID = v.CampanaID),
                -1
            ),

            -- Claves naturales y atributos
            dv.VentaID,
            dv.DetalleID,
            v.NumeroFactura,
            v.Estado,
            CAST(v.FechaVenta AS DATE),

            -- Medidas
            dv.Cantidad,
            dv.PrecioUnitario,
            ROUND(dv.Cantidad * dv.PrecioUnitario, 2),                          -- ValorBruto
            ROUND(dv.Cantidad * dv.PrecioUnitario * dv.DescuentoPct / 100.0, 2), -- Descuento
            dv.TotalLinea,                                                        -- ValorVenta
            dv.CostoTotal,
            dv.MargenLinea

        FROM BI_Staging.dbo.STG_DetalleVentas dv
        JOIN BI_Staging.dbo.STG_Ventas         v  ON dv.VentaID = v.VentaID
        WHERE dv.FlagCalidad = 'OK'
          AND v.EsDuplicado  = 0
          -- Evitar re-cargar ventas ya existentes
          AND NOT EXISTS (
              SELECT 1 FROM FactVentas fv WHERE fv.DetalleID = dv.DetalleID
          );

        SET @cargados   = @@ROWCOUNT;
        SET @rechazados = @leidos - @cargados;

        -- --------------------------------------------------------
        -- Verificar cuántos registros quedaron con surrogate key -1
        -- --------------------------------------------------------
        DECLARE @sin_fecha    INT = (SELECT COUNT(*) FROM FactVentas WHERE FechaKey    = -1);
        DECLARE @sin_cliente  INT = (SELECT COUNT(*) FROM FactVentas WHERE ClienteKey  = -1);
        DECLARE @sin_producto INT = (SELECT COUNT(*) FROM FactVentas WHERE ProductoKey = -1);
        DECLARE @sin_tienda   INT = (SELECT COUNT(*) FROM FactVentas WHERE TiendaKey   = -1);

        DECLARE @warning VARCHAR(500) = NULL;
        IF (@sin_fecha + @sin_cliente + @sin_producto + @sin_tienda) > 0
            SET @warning = 'Keys -1: Fecha=' + CAST(@sin_fecha AS VARCHAR) +
                           ', Cliente=' + CAST(@sin_cliente AS VARCHAR) +
                           ', Producto=' + CAST(@sin_producto AS VARCHAR) +
                           ', Tienda=' + CAST(@sin_tienda AS VARCHAR);

        EXEC sp_ETL_Log_Finalizar
            @LogID, 'COMPLETADO', @leidos, @cargados, @rechazados, @warning;

        PRINT '✔ CargarFactVentas completado';
        PRINT '  Leídos:     ' + CAST(@leidos AS VARCHAR);
        PRINT '  Cargados:   ' + CAST(@cargados AS VARCHAR);
        PRINT '  Rechazados: ' + CAST(@rechazados AS VARCHAR);
        IF @warning IS NOT NULL PRINT '  ⚠ ' + @warning;

    END TRY
    BEGIN CATCH
        DECLARE @errMsg VARCHAR(MAX) = ERROR_MESSAGE();
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', @leidos, @cargados, @rechazados, @errMsg;
        THROW;
    END CATCH
END;
GO

EXEC CargarFactVentas;
GO
