-- ============================================================
-- PROYECTO 3 - BI análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 12_CargarFactMetas.sql
-- Granularidad: mes × tienda × categoría (× vendedor opcional)

USE RetailDW;
GO

CREATE OR ALTER PROCEDURE CargarFactMetasComerciales
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT = 0, @cargados INT = 0, @rechazados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarFactMetasComerciales', @LogID OUTPUT;
    BEGIN TRY
        -- Combinar metas del OLTP y metas externas del CSV (con precedencia OLTP)
        SET @leidos = (
            SELECT COUNT(*) FROM BI_Staging.dbo.STG_Metas WHERE FlagCalidad = 'OK'
        ) + (
            SELECT COUNT(*) FROM BI_Staging.dbo.STG_MetasExternas WHERE FlagCalidad = 'OK'
        );

        -- Metas del OLTP
        INSERT INTO FactMetasComerciales (
            TiendaKey, ProductoKey, VendedorKey, CanalKey,
            MetaID, Anio, Mes, ValorMeta
        )
        SELECT
            COALESCE(
                (SELECT TOP 1 TiendaKey FROM DimTienda WHERE TiendaID = m.TiendaID), -1),
            -- ProductoKey representa categoría (tomamos el primer producto de la categoría)
            COALESCE(
                (SELECT TOP 1 ProductoKey FROM DimProducto dp
                 JOIN RetailOLTP.dbo.Productos p ON dp.ProductoID = p.ProductoID
                 WHERE p.CategoriaID = m.CategoriaID AND dp.EsVersionActual = 1), -1),
            COALESCE(
                (SELECT TOP 1 VendedorKey FROM DimVendedor WHERE VendedorID = m.VendedorID), -1),
            COALESCE(
                (SELECT TOP 1 CanalKey FROM DimCanalVenta WHERE CanalID = m.CanalID), -1),
            m.MetaID,
            m.Anio,
            m.Mes,
            m.ValorMeta
        FROM BI_Staging.dbo.STG_Metas m
        WHERE m.FlagCalidad = 'OK'
          AND NOT EXISTS (
              SELECT 1 FROM FactMetasComerciales fm WHERE fm.MetaID = m.MetaID
          );

        SET @cargados = @@ROWCOUNT;

        -- Metas externas CSV (si tienda/categoría coincide con el DW)
        INSERT INTO FactMetasComerciales (
            TiendaKey, ProductoKey, VendedorKey, CanalKey,
            MetaID, Anio, Mes, ValorMeta
        )
        SELECT
            COALESCE(
                (SELECT TOP 1 TiendaKey FROM DimTienda WHERE NombreTienda = me.NombreTienda), -1),
            COALESCE(
                (SELECT TOP 1 ProductoKey FROM DimProducto WHERE Categoria = UPPER(me.NombreCategoria) AND EsVersionActual = 1), -1),
            -1,  -- Sin vendedor específico en metas externas
            -1,  -- Sin canal específico en metas externas
            -1 * ROW_NUMBER() OVER (ORDER BY me.Anio, me.Mes),  -- MetaID sintético negativo
            me.Anio,
            me.Mes,
            me.ValorMeta
        FROM BI_Staging.dbo.STG_MetasExternas me
        WHERE me.FlagCalidad = 'OK'
          -- Solo cargar si no existe ya una meta OLTP para esa tienda/mes
          AND NOT EXISTS (
              SELECT 1 FROM FactMetasComerciales fm
              JOIN DimTienda t ON fm.TiendaKey = t.TiendaKey
              WHERE t.NombreTienda = me.NombreTienda
                AND fm.Anio = me.Anio AND fm.Mes = me.Mes
          );

        SET @cargados = @cargados + @@ROWCOUNT;
        SET @rechazados = @leidos - @cargados;

        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @rechazados, NULL;
        PRINT '✔ CargarFactMetasComerciales: ' + CAST(@cargados AS VARCHAR) + ' registros cargados';
    END TRY
    BEGIN CATCH
        DECLARE @errMsg VARCHAR(MAX) = ERROR_MESSAGE();
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', @leidos, @cargados, @rechazados, @errMsg;
        THROW;
    END CATCH
END;
GO

EXEC CargarFactMetasComerciales;
GO
