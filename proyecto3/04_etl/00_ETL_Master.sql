-- ============================================================
-- PROYECTO 3 - BI análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 00_ETL_Master.sql
-- Descripción: Orquestador principal del pipeline ETL.
--   Ejecuta en orden todos los procesos ETL del Staging al DW.
--   Registra el inicio y fin del pipeline completo en ETL_Log.
-- USO: USE RetailDW; EXEC ETL_Master;
-- ============================================================

USE RetailDW;
GO

CREATE OR ALTER PROCEDURE ETL_Master
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @LogID    INT;
    DECLARE @inicio   DATETIME = GETDATE();
    DECLARE @paso     VARCHAR(100);
    DECLARE @error    VARCHAR(MAX);

    PRINT '=======================================================';
    PRINT ' INICIO PIPELINE ETL — RetailBI';
    PRINT ' Fecha: ' + CAST(@inicio AS VARCHAR);
    PRINT '=======================================================';

    -- Registrar inicio del pipeline maestro
    EXEC sp_ETL_Log_Iniciar 'ETL_Master_Pipeline', @LogID OUTPUT;

    BEGIN TRY

        -- ====================================================
        -- FASE 0: Truncar staging y recargar desde OLTP
        -- ====================================================
        SET @paso = 'FASE 0 - Recarga Staging';
        PRINT CHAR(13) + '--- ' + @paso + ' ---';

        -- Limpiar staging para carga fresca
        TRUNCATE TABLE BI_Staging.dbo.STG_DetalleVentas;
        TRUNCATE TABLE BI_Staging.dbo.STG_Ventas;
        TRUNCATE TABLE BI_Staging.dbo.STG_Clientes;
        TRUNCATE TABLE BI_Staging.dbo.STG_Productos;
        TRUNCATE TABLE BI_Staging.dbo.STG_Inventario;
        TRUNCATE TABLE BI_Staging.dbo.STG_Metas;
        TRUNCATE TABLE BI_Staging.dbo.STG_Devoluciones;
        TRUNCATE TABLE BI_Staging.dbo.STG_Compras;
        PRINT '  ✔ Staging limpiado';

        -- ====================================================
        -- FASE 1: Cargar Dimensiones
        -- ====================================================
        SET @paso = 'FASE 1 - Cargar Dimensiones';
        PRINT CHAR(13) + '--- ' + @paso + ' ---';

        EXEC CargarDimFecha;      PRINT '  ✔ DimFecha';
        EXEC CargarDimGeografia;  PRINT '  ✔ DimGeografia';
        EXEC CargarDimCliente;    PRINT '  ✔ DimCliente';
        EXEC CargarDimProducto;   PRINT '  ✔ DimProducto';
        EXEC CargarDimTienda;     PRINT '  ✔ DimTienda';
        EXEC CargarDimVendedor;   PRINT '  ✔ DimVendedor';
        EXEC CargarDimProveedor;  PRINT '  ✔ DimProveedor';
        EXEC CargarDimCanalVenta; PRINT '  ✔ DimCanalVenta';
        EXEC CargarDimPromocion;  PRINT '  ✔ DimPromocion';

        -- ====================================================
        -- FASE 2: Cargar Tablas de Hechos
        -- ====================================================
        SET @paso = 'FASE 2 - Cargar Hechos';
        PRINT CHAR(13) + '--- ' + @paso + ' ---';

        EXEC CargarFactVentas;              PRINT '  ✔ FactVentas';
        EXEC CargarFactInventarioDiario;    PRINT '  ✔ FactInventarioDiario';
        EXEC CargarFactMetasComerciales;    PRINT '  ✔ FactMetasComerciales';
        EXEC CargarFactDevoluciones;        PRINT '  ✔ FactDevoluciones';

        -- ====================================================
        -- FASE 3: Actualizar estadísticas del DW
        -- ====================================================
        SET @paso = 'FASE 3 - Actualizar estadísticas';
        PRINT CHAR(13) + '--- ' + @paso + ' ---';

        UPDATE STATISTICS FactVentas;
        UPDATE STATISTICS FactInventarioDiario;
        UPDATE STATISTICS FactMetasComerciales;
        UPDATE STATISTICS FactDevoluciones;
        PRINT '  ✔ Estadísticas actualizadas';

        -- ====================================================
        -- Registrar éxito del pipeline
        -- ====================================================
        DECLARE @total_ventas   INT = (SELECT COUNT(*) FROM FactVentas);
        DECLARE @total_inv      INT = (SELECT COUNT(*) FROM FactInventarioDiario);
        DECLARE @total_metas    INT = (SELECT COUNT(*) FROM FactMetasComerciales);
        DECLARE @total_devs     INT = (SELECT COUNT(*) FROM FactDevoluciones);
        DECLARE @total_cargados INT = @total_ventas + @total_inv + @total_metas + @total_devs;

        EXEC sp_ETL_Log_Finalizar
            @LogID, 'COMPLETADO',
            @total_cargados, @total_cargados, 0,
            'FactVentas=' + CAST(@total_ventas AS VARCHAR) +
            ' | FactInv=' + CAST(@total_inv AS VARCHAR) +
            ' | FactMetas=' + CAST(@total_metas AS VARCHAR) +
            ' | FactDevs=' + CAST(@total_devs AS VARCHAR);

        PRINT '';
        PRINT '=======================================================';
        PRINT ' PIPELINE ETL COMPLETADO EXITOSAMENTE';
        PRINT ' Duración: ' + CAST(DATEDIFF(SECOND, @inicio, GETDATE()) AS VARCHAR) + ' segundos';
        PRINT ' FactVentas:          ' + CAST(@total_ventas AS VARCHAR);
        PRINT ' FactInventarioDiario:' + CAST(@total_inv AS VARCHAR);
        PRINT ' FactMetasComerciales:' + CAST(@total_metas AS VARCHAR);
        PRINT ' FactDevoluciones:    ' + CAST(@total_devs AS VARCHAR);
        PRINT '=======================================================';

    END TRY
    BEGIN CATCH
        SET @error = 'ERROR en ' + ISNULL(@paso,'?') + ': ' + ERROR_MESSAGE();

        EXEC sp_ETL_Log_Finalizar
            @LogID, 'ERROR', 0, 0, 0, @error;

        PRINT '';
        PRINT '⛔ ERROR EN EL PIPELINE ETL';
        PRINT @error;

        THROW;
    END CATCH
END;
GO

PRINT '✔ Procedimiento ETL_Master creado. Ejecutar con: EXEC ETL_Master;';
