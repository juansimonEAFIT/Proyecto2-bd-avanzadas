-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Script: 04_generate_data_restante.sql
-- Descripción: Genera los datos sintéticos restantes que fallaron
-- en la ejecución original (Devoluciones y Metas Comerciales).
-- ============================================================

USE RetailOLTP;
GO

SET NOCOUNT ON;
PRINT 'Iniciando generación de datos restantes (Devoluciones y Metas)...';
PRINT CAST(GETDATE() AS VARCHAR);
GO

-- ============================================================
-- 13. DEVOLUCIONES (~500 devoluciones)
-- ============================================================
DECLARE @dev INT = 1;
DECLARE @venta_rand INT;
DECLARE @det_rand INT;
DECLARE @prod INT;
DECLARE @cant INT;
DECLARE @total_l DECIMAL(18,2);
DECLARE @tienda INT;
DECLARE @cliente INT;
DECLARE @fecha_venta DATETIME;
DECLARE @motivos TABLE (m VARCHAR(200));
INSERT INTO @motivos VALUES
('Producto defectuoso'),('Talla incorrecta'),('Color diferente al mostrado'),
('Daño en el empaque'),('Producto incompleto'),('Error en el pedido'),
('No cumple las expectativas'),('Duplicado accidental');

WHILE @dev <= 500
BEGIN
    -- Tomar una venta aleatoria completada
    SELECT TOP 1 @venta_rand = v.VentaID, @det_rand = dv.DetalleID,
           @prod = dv.ProductoID, @cant = dv.Cantidad,
           @total_l = dv.TotalLinea, @tienda = v.TiendaID, @cliente = v.ClienteID,
           @fecha_venta = v.FechaVenta
    FROM Ventas v
    JOIN DetalleVentas dv ON v.VentaID = dv.VentaID
    WHERE v.Estado = 'Completada'
    ORDER BY NEWID();

    DECLARE @motivo_rand VARCHAR(200);
    SELECT TOP 1 @motivo_rand = m FROM @motivos ORDER BY NEWID();

    INSERT INTO Devoluciones (VentaID, DetalleID, ClienteID, TiendaID, ProductoID,
                              FechaDevolucion, MotivoDevolucion, CantidadDevuelta, ValorDevuelto)
    VALUES (@venta_rand, @det_rand, @cliente, @tienda, @prod,
            DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30 + 1, @fecha_venta),
            @motivo_rand,
            1 + ABS(CHECKSUM(NEWID())) % @cant,
            ROUND(@total_l * (0.5 + (ABS(CHECKSUM(NEWID())) % 51) * 0.01), 2));

    SET @dev = @dev + 1;
END
GO

PRINT '✔ Devoluciones insertadas: 500';

-- ============================================================
-- 14. METAS COMERCIALES (12 meses × 10 tiendas × 8 categorías = 960 registros)
-- ============================================================
DECLARE @anio_m INT;
DECLARE @mes_m  INT;
DECLARE @tda_m  INT;
DECLARE @cat_m  INT;
DECLARE @meta_v DECIMAL(18,2);

SET @anio_m = 2023;
WHILE @anio_m <= 2025
BEGIN
    SET @mes_m = 1;
    WHILE @mes_m <= 12
    BEGIN
        SET @tda_m = 1;
        WHILE @tda_m <= 10
        BEGIN
            SET @cat_m = 1;
            WHILE @cat_m <= 8
            BEGIN
                SET @meta_v = ROUND(
                    (50000000 + ABS(CHECKSUM(NEWID())) % 150000001) *
                    (1 + CASE WHEN @mes_m IN (11,12) THEN 1 ELSE 0 END * 0.30),  -- boost navideño
                    -4
                );

                BEGIN TRY
                    INSERT INTO MetasComerciales (Anio, Mes, TiendaID, CategoriaID, ValorMeta)
                    VALUES (@anio_m, @mes_m, @tda_m, @cat_m, @meta_v);
                END TRY
                BEGIN CATCH
                    -- Ignorar duplicados
                END CATCH

                SET @cat_m = @cat_m + 1;
            END
            SET @tda_m = @tda_m + 1;
        END
        SET @mes_m = @mes_m + 1;
    END
    SET @anio_m = @anio_m + 1;
END
GO

PRINT '✔ MetasComerciales insertadas';

-- ============================================================
-- VERIFICACIÓN FINAL DE VOLÚMENES
-- ============================================================
PRINT '';
PRINT '=== RESUMEN DE DATOS GENERADOS ===';
SELECT 'Ciudades'          AS Tabla, COUNT(*) AS Total FROM Ciudades
UNION ALL SELECT 'Categorias',       COUNT(*) FROM Categorias
UNION ALL SELECT 'Proveedores',      COUNT(*) FROM Proveedores
UNION ALL SELECT 'Productos',        COUNT(*) FROM Productos
UNION ALL SELECT 'Clientes',         COUNT(*) FROM Clientes
UNION ALL SELECT 'Tiendas',          COUNT(*) FROM Tiendas
UNION ALL SELECT 'CanalVenta',       COUNT(*) FROM CanalVenta
UNION ALL SELECT 'Campanas',         COUNT(*) FROM Campanas
UNION ALL SELECT 'Vendedores',       COUNT(*) FROM Vendedores
UNION ALL SELECT 'Ventas',           COUNT(*) FROM Ventas
UNION ALL SELECT 'DetalleVentas',    COUNT(*) FROM DetalleVentas
UNION ALL SELECT 'InventarioDiario', COUNT(*) FROM InventarioDiario
UNION ALL SELECT 'Compras',          COUNT(*) FROM Compras
UNION ALL SELECT 'DetalleCompras',   COUNT(*) FROM DetalleCompras
UNION ALL SELECT 'Devoluciones',     COUNT(*) FROM Devoluciones
UNION ALL SELECT 'MetasComerciales', COUNT(*) FROM MetasComerciales
ORDER BY Tabla;

PRINT '=== Generación de datos completada: ' + CAST(GETDATE() AS VARCHAR) + ' ===';
