-- ============================================================
-- ETL: CargarDimGeografia
-- ============================================================
USE RetailDW;
GO
CREATE OR ALTER PROCEDURE CargarDimGeografia AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimGeografia', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM BI_Staging.dbo.STG_Clientes WHERE CiudadNombre <> 'DESCONOCIDA');

        MERGE DimGeografia AS tgt
        USING (
            SELECT DISTINCT
                UPPER(LTRIM(RTRIM(CiudadNombre))) AS NombreCiudad,
                UPPER(LTRIM(RTRIM(Departamento)))  AS Departamento,
                UPPER(LTRIM(RTRIM(Region)))         AS Region
            FROM BI_Staging.dbo.STG_Clientes
            WHERE CiudadNombre <> 'DESCONOCIDA'
            UNION
            SELECT DISTINCT
                UPPER(LTRIM(RTRIM(Ciudad))),
                UPPER(LTRIM(RTRIM(Departamento))),
                'ANDINA'
            FROM BI_Staging.dbo.STG_Compras
        ) AS src
        ON tgt.NombreCiudad = src.NombreCiudad AND tgt.Departamento = src.Departamento
        WHEN NOT MATCHED THEN
            INSERT (NombreCiudad, Departamento, Region)
            VALUES (src.NombreCiudad, src.Departamento, src.Region);

        SET @cargados = @@ROWCOUNT;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, 0, NULL;
        PRINT '✔ CargarDimGeografia: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimGeografia;
GO

-- ============================================================
-- ETL: CargarDimCliente
-- ============================================================
CREATE OR ALTER PROCEDURE CargarDimCliente AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0, @rechazados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimCliente', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM BI_Staging.dbo.STG_Clientes WHERE FlagCalidad IN ('OK','PENDIENTE'));

        -- Cerrar versiones SCD2 que han cambiado
        UPDATE dw
        SET FechaFinSCD     = CAST(GETDATE() AS DATE),
            EsVersionActual  = 0
        FROM DimCliente dw
        JOIN BI_Staging.dbo.STG_Clientes stg ON dw.ClienteID = stg.ClienteID
        WHERE dw.EsVersionActual = 1
          AND (dw.Segmento <> stg.Segmento OR dw.Ciudad <> ISNULL(stg.CiudadNombre,''));

        -- Insertar nuevas versiones y nuevos clientes
        INSERT INTO DimCliente (
            ClienteID, Documento, TipoDocumento, NombreCliente, Email, Telefono,
            Ciudad, Departamento, Region, Segmento,
            RangoEdad, Activo, FechaInicioSCD, EsVersionActual
        )
        SELECT
            s.ClienteID,
            s.Documento,
            s.TipoDocumento,
            s.NombreCliente,
            s.Email,
            s.Telefono,
            s.CiudadNombre,
            s.Departamento,
            s.Region,
            s.Segmento,
            CASE
                WHEN s.FechaNacimiento IS NULL THEN 'Sin datos'
                WHEN DATEDIFF(YEAR, s.FechaNacimiento, GETDATE()) < 25 THEN '18-24'
                WHEN DATEDIFF(YEAR, s.FechaNacimiento, GETDATE()) < 35 THEN '25-34'
                WHEN DATEDIFF(YEAR, s.FechaNacimiento, GETDATE()) < 45 THEN '35-44'
                WHEN DATEDIFF(YEAR, s.FechaNacimiento, GETDATE()) < 55 THEN '45-54'
                ELSE '55+'
            END,
            s.Activo,
            CAST(GETDATE() AS DATE),
            1
        FROM BI_Staging.dbo.STG_Clientes s
        WHERE s.FlagCalidad IN ('OK','PENDIENTE')
          AND s.EsDuplicado = 0
          AND NOT EXISTS (
              SELECT 1 FROM DimCliente d
              WHERE d.ClienteID = s.ClienteID AND d.EsVersionActual = 1
          );

        SET @cargados = @@ROWCOUNT;
        SET @rechazados = @leidos - @cargados;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @rechazados, NULL;
        PRINT '✔ CargarDimCliente: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimCliente;
GO

-- ============================================================
-- ETL: CargarDimProducto
-- ============================================================
CREATE OR ALTER PROCEDURE CargarDimProducto AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimProducto', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM BI_Staging.dbo.STG_Productos WHERE FlagCalidad = 'OK');

        INSERT INTO DimProducto (
            ProductoID, CodigoSKU, NombreProducto, Categoria, CategoriaParent,
            NombreProveedor, PrecioLista, CostoStandard, MargenStandard,
            UnidadMedida, GrupoPrecio, Activo, FechaInicioSCD, EsVersionActual
        )
        SELECT
            s.ProductoID,
            s.CodigoSKU,
            s.NombreProducto,
            s.NombreCategoria,
            s.CategoriaParent,
            s.NombreProveedor,
            s.PrecioUnitario,
            s.CostoUnitario,
            ISNULL(s.MargenPct, 0),
            s.UnidadMedida,
            CASE
                WHEN s.PrecioUnitario < 50000  THEN 'ECONÓMICO'
                WHEN s.PrecioUnitario < 200000 THEN 'MID'
                ELSE 'PREMIUM'
            END,
            s.Activo,
            CAST(GETDATE() AS DATE),
            1
        FROM BI_Staging.dbo.STG_Productos s
        WHERE s.FlagCalidad = 'OK'
          AND NOT EXISTS (SELECT 1 FROM DimProducto d WHERE d.ProductoID = s.ProductoID AND d.EsVersionActual = 1);

        SET @cargados = @@ROWCOUNT;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @leidos - @cargados, NULL;
        PRINT '✔ CargarDimProducto: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimProducto;
GO

-- ============================================================
-- ETL: CargarDimTienda
-- ============================================================
CREATE OR ALTER PROCEDURE CargarDimTienda AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimTienda', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM RetailOLTP.dbo.Tiendas);

        INSERT INTO DimTienda (
            TiendaID, CodigoTienda, NombreTienda, Ciudad, Departamento, Region,
            Direccion, AreaM2, CategoriaTamanio, FechaApertura, AnosOperacion, Activo
        )
        SELECT
            t.TiendaID,
            t.CodigoTienda,
            t.NombreTienda,
            c.NombreCiudad,
            c.Departamento,
            c.Region,
            t.Direccion,
            t.AreaM2,
            CASE
                WHEN ISNULL(t.AreaM2,0) < 800  THEN 'PEQUEÑA'
                WHEN ISNULL(t.AreaM2,0) < 1200 THEN 'MEDIANA'
                ELSE 'GRANDE'
            END,
            t.FechaApertura,
            DATEDIFF(YEAR, t.FechaApertura, GETDATE()),
            t.Activo
        FROM RetailOLTP.dbo.Tiendas t
        JOIN RetailOLTP.dbo.Ciudades c ON t.CiudadID = c.CiudadID
        WHERE NOT EXISTS (SELECT 1 FROM DimTienda d WHERE d.TiendaID = t.TiendaID);

        SET @cargados = @@ROWCOUNT;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @leidos - @cargados, NULL;
        PRINT '✔ CargarDimTienda: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimTienda;
GO

-- ============================================================
-- ETL: CargarDimVendedor
-- ============================================================
CREATE OR ALTER PROCEDURE CargarDimVendedor AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimVendedor', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM RetailOLTP.dbo.Vendedores);

        INSERT INTO DimVendedor (
            VendedorID, Documento, NombreVendedor, TiendaAsignada, CanalAsignado,
            AnosExperiencia, Activo, FechaIngreso
        )
        SELECT
            v.VendedorID,
            v.Documento,
            v.NombreVendedor,
            t.NombreTienda,
            ISNULL(cv.NombreCanal, 'Presencial'),
            DATEDIFF(YEAR, v.FechaIngreso, GETDATE()),
            v.Activo,
            v.FechaIngreso
        FROM RetailOLTP.dbo.Vendedores v
        JOIN RetailOLTP.dbo.Tiendas    t  ON v.TiendaID = t.TiendaID
        LEFT JOIN RetailOLTP.dbo.CanalVenta cv ON v.CanalID = cv.CanalID
        WHERE NOT EXISTS (SELECT 1 FROM DimVendedor d WHERE d.VendedorID = v.VendedorID);

        SET @cargados = @@ROWCOUNT;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @leidos - @cargados, NULL;
        PRINT '✔ CargarDimVendedor: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimVendedor;
GO

-- ============================================================
-- ETL: CargarDimProveedor
-- ============================================================
CREATE OR ALTER PROCEDURE CargarDimProveedor AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimProveedor', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM RetailOLTP.dbo.Proveedores);

        INSERT INTO DimProveedor (ProveedorID, NombreProveedor, NIT, Ciudad, Departamento, Activo)
        SELECT p.ProveedorID, p.NombreProveedor, p.NIT, p.Ciudad, p.Departamento, p.Activo
        FROM RetailOLTP.dbo.Proveedores p
        WHERE NOT EXISTS (SELECT 1 FROM DimProveedor d WHERE d.ProveedorID = p.ProveedorID);

        SET @cargados = @@ROWCOUNT;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @leidos - @cargados, NULL;
        PRINT '✔ CargarDimProveedor: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimProveedor;
GO

-- ============================================================
-- ETL: CargarDimCanalVenta
-- ============================================================
CREATE OR ALTER PROCEDURE CargarDimCanalVenta AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimCanalVenta', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM RetailOLTP.dbo.CanalVenta);

        INSERT INTO DimCanalVenta (CanalID, NombreCanal, TipoCanal, Descripcion, Activo)
        SELECT
            c.CanalID,
            c.NombreCanal,
            CASE c.NombreCanal
                WHEN 'Presencial' THEN 'FISICO'
                WHEN 'Online'     THEN 'DIGITAL'
                WHEN 'App Móvil'  THEN 'DIGITAL'
                WHEN 'Telefónico' THEN 'HIBRIDO'
                ELSE 'OTRO'
            END,
            c.Descripcion,
            c.Activo
        FROM RetailOLTP.dbo.CanalVenta c
        WHERE NOT EXISTS (SELECT 1 FROM DimCanalVenta d WHERE d.CanalID = c.CanalID);

        SET @cargados = @@ROWCOUNT;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @leidos - @cargados, NULL;
        PRINT '✔ CargarDimCanalVenta: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimCanalVenta;
GO

-- ============================================================
-- ETL: CargarDimPromocion
-- ============================================================
CREATE OR ALTER PROCEDURE CargarDimPromocion AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @leidos INT, @cargados INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimPromocion', @LogID OUTPUT;
    BEGIN TRY
        SET @leidos = (SELECT COUNT(*) FROM RetailOLTP.dbo.Campanas);

        INSERT INTO DimPromocion (
            CampanaID, NombreCampana, TipoCampana, FechaInicio, FechaFin,
            DuracionDias, DescuentoPct, EsPromocion
        )
        SELECT
            c.CampanaID,
            c.NombreCampana,
            c.TipoCampana,
            c.FechaInicio,
            c.FechaFin,
            DATEDIFF(DAY, c.FechaInicio, c.FechaFin) + 1,
            c.DescuentoPct,
            1
        FROM RetailOLTP.dbo.Campanas c
        WHERE NOT EXISTS (SELECT 1 FROM DimPromocion d WHERE d.CampanaID = c.CampanaID);

        SET @cargados = @@ROWCOUNT;
        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @leidos, @cargados, @leidos - @cargados, NULL;
        PRINT '✔ CargarDimPromocion: ' + CAST(@cargados AS VARCHAR) + ' registros';
    END TRY
    BEGIN CATCH
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, ERROR_MESSAGE(); THROW;
    END CATCH
END;
GO
EXEC CargarDimPromocion;
GO
