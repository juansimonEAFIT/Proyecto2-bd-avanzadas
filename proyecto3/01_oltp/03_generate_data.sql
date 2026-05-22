-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 1: Alejandro Posada
-- Script: 03_generate_data.sql
-- Descripción: Genera datos sintéticos realistas para el OLTP
--   - 10 ciudades / 10 tiendas / 5 categorias / 20 proveedores
--   - 200 productos / 1000 clientes / 20 vendedores
--   - 50.000 ventas / ~150.000 líneas de venta
--   - 365 días de inventario diario / 12 meses de metas
-- ADVERTENCIA: Este script puede tardar 10-20 minutos.
-- ============================================================

USE RetailOLTP;
GO

SET NOCOUNT ON;
PRINT 'Iniciando generación de datos sintéticos...';
PRINT CAST(GETDATE() AS VARCHAR);
GO

-- ============================================================
-- 1. CIUDADES Y REGIONES DE COLOMBIA
-- ============================================================
INSERT INTO Ciudades (NombreCiudad, Departamento, Region, CodigoDane) VALUES
('Medellín',       'Antioquia',        'Andina',    '05001'),
('Bogotá',         'Cundinamarca',     'Andina',    '11001'),
('Cali',           'Valle del Cauca',  'Pacifica',  '76001'),
('Barranquilla',   'Atlántico',        'Caribe',    '08001'),
('Cartagena',      'Bolívar',          'Caribe',    '13001'),
('Bucaramanga',    'Santander',        'Andina',    '68001'),
('Pereira',        'Risaralda',        'Andina',    '66001'),
('Manizales',      'Caldas',           'Andina',    '17001'),
('Cucuta',         'Norte de Santander','Andina',   '54001'),
('Santa Marta',    'Magdalena',        'Caribe',    '47001'),
('Ibagué',         'Tolima',           'Andina',    '73001'),
('Pasto',          'Nariño',           'Andina',    '52001'),
('Villavicencio',  'Meta',             'Orinoquia', '50001'),
('Armenia',        'Quindío',          'Andina',    '63001'),
('Popayán',        'Cauca',            'Pacifica',  '19001');
GO

PRINT '✔ Ciudades insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ============================================================
-- 2. CATEGORÍAS DE PRODUCTOS
-- ============================================================
INSERT INTO Categorias (NombreCategoria, Descripcion, CategoriaParent) VALUES
('Electrónica',        'Dispositivos electrónicos y accesorios', NULL),
('Ropa y Calzado',     'Prendas de vestir y calzado',            NULL),
('Alimentos',          'Productos alimenticios y bebidas',        NULL),
('Hogar y Deco',       'Artículos para el hogar y decoración',   NULL),
('Deportes',           'Artículos deportivos y fitness',          NULL),
('Belleza y Salud',    'Cosméticos, higiene y salud',             NULL),
('Juguetería',         'Juguetes y entretenimiento infantil',     NULL),
('Ferretería',         'Herramientas y construcción',             NULL);

-- Subcategorías
INSERT INTO Categorias (NombreCategoria, Descripcion, CategoriaParent) VALUES
('Smartphones',        'Teléfonos móviles inteligentes',    1),
('Computadores',       'PCs, portátiles y accesorios',      1),
('Televisores',        'TV y equipos audiovisuales',        1),
('Ropa Hombre',        'Prendas de vestir masculinas',      2),
('Ropa Mujer',         'Prendas de vestir femeninas',       2),
('Calzado',            'Zapatos y botas',                   2),
('Lácteos',            'Leche, quesos y derivados',         3),
('Snacks',             'Pasabocas y golosinas',             3),
('Bebidas',            'Bebidas frías y calientes',         3);
GO

PRINT '✔ Categorías insertadas';

-- ============================================================
-- 3. PROVEEDORES
-- ============================================================
DECLARE @i INT = 1;
DECLARE @nombres TABLE (n VARCHAR(100));
INSERT INTO @nombres VALUES
('TechDistrib SAS'),('ModaCol Ltda'),('AlimFresh SA'),('HogarPlus SAS'),
('DeportePro Ltda'),('BellezaTotal SA'),('JuguetesKids SAS'),('FerreTodo Ltda'),
('ElectroParts SA'),('TextilNorte Ltda'),('AlimSur SAS'),('TechColombia SA'),
('ModaActiva Ltda'),('FreshMart SAS'),('HogarDeco SA'),('SportMax Ltda'),
('BioSalud SAS'),('ToyWorld SA'),('HerraCol Ltda'),('DistribNal SA');

INSERT INTO Proveedores (NombreProveedor, NIT, Ciudad, Departamento, Telefono, Email)
SELECT
    n,
    CAST(800000000 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS VARCHAR) + '-' +
    CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 9 AS VARCHAR),
    CASE ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 5
        WHEN 0 THEN 'Medellín'   WHEN 1 THEN 'Bogotá'
        WHEN 2 THEN 'Cali'       WHEN 3 THEN 'Barranquilla'
        ELSE 'Bucaramanga'
    END,
    CASE ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 5
        WHEN 0 THEN 'Antioquia'      WHEN 1 THEN 'Cundinamarca'
        WHEN 2 THEN 'Valle del Cauca' WHEN 3 THEN 'Atlántico'
        ELSE 'Santander'
    END,
    '(60' + CAST(1 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 8 AS VARCHAR) + ') ' +
    CAST(3000000 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) * 17 AS VARCHAR),
    'contacto@' + LOWER(REPLACE(n, ' ', '')) + '.com.co'
FROM @nombres;
GO

PRINT '✔ Proveedores insertados: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ============================================================
-- 4. CANAL DE VENTA
-- ============================================================
INSERT INTO CanalVenta (NombreCanal, Descripcion) VALUES
('Presencial',   'Venta directa en tienda física'),
('Online',       'Venta a través de plataforma web'),
('Telefónico',   'Venta por llamada telefónica'),
('App Móvil',    'Venta a través de aplicación móvil'),
('Mayorista',    'Venta a distribuidores y mayoristas');
GO

PRINT '✔ Canales de venta insertados';

-- ============================================================
-- 5. TIENDAS (10 sedes en Colombia)
-- ============================================================
INSERT INTO Tiendas (CodigoTienda, NombreTienda, CiudadID, Direccion, Telefono, AreaM2, FechaApertura) VALUES
('T001', 'RetailPro Medellín Centro',    1, 'Cl 52 # 47-42, El Centro',         '6042501001', 1200.00, '2018-03-15'),
('T002', 'RetailPro Bogotá Chapinero',   2, 'Cr 13 # 67-35, Chapinero',         '6017201002', 1500.00, '2017-06-01'),
('T003', 'RetailPro Cali Norte',         3, 'Av 6N # 25N-10, Cali Norte',       '6027701003', 900.00,  '2019-01-20'),
('T004', 'RetailPro Barranquilla',       4, 'Cr 54 # 75-23, El Prado',          '6053801004', 1100.00, '2018-09-10'),
('T005', 'RetailPro Cartagena',          5, 'Av Venezuela # 32-15, Manga',       '6056801005', 800.00,  '2020-02-14'),
('T006', 'RetailPro Bucaramanga',        6, 'Cl 35 # 22-41, Cabecera',          '6076801006', 950.00,  '2019-07-05'),
('T007', 'RetailPro Pereira',            7, 'Av Circunvalar # 12-08, Centro',   '6063401007', 700.00,  '2020-11-30'),
('T008', 'RetailPro Medellín Laureles',  1, 'Cr 76 # 33A-05, Laureles',         '6042501008', 1050.00, '2021-03-01'),
('T009', 'RetailPro Bogotá Usaquén',     2, 'Cl 116 # 15-21, Usaquén',          '6017201009', 1350.00, '2021-08-15'),
('T010', 'RetailPro Manizales',          8, 'Cr 23 # 62-07, Centro',            '6086801010', 650.00,  '2022-01-10');
GO

PRINT '✔ Tiendas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ============================================================
-- 6. CAMPAÑAS COMERCIALES
-- ============================================================
INSERT INTO Campanas (NombreCampana, TipoCampana, FechaInicio, FechaFin, DescuentoPct) VALUES
('Temporada Navidad 2023',      'Temporada',    '2023-12-01', '2023-12-31', 15.00),
('Black Friday 2023',           'Descuento',    '2023-11-24', '2023-11-26', 25.00),
('Amor y Amistad 2024',         'Temporada',    '2024-09-10', '2024-09-20', 10.00),
('Liquidación Enero 2024',      'Liquidacion',  '2024-01-02', '2024-01-31', 30.00),
('Día de la Madre 2024',        'Temporada',    '2024-05-08', '2024-05-12', 12.00),
('Regreso a Clases 2024',       'Temporada',    '2024-01-15', '2024-02-15', 8.00),
('Black Friday 2024',           'Descuento',    '2024-11-29', '2024-12-01', 25.00),
('Navidad 2024',                'Temporada',    '2024-12-01', '2024-12-31', 15.00),
('Club Fidelización Q1-2025',   'Fidelizacion', '2025-01-01', '2025-03-31', 5.00),
('Semana Santa 2025',           'Temporada',    '2025-04-14', '2025-04-20', 10.00),
('Día del Padre 2025',          'Temporada',    '2025-06-15', '2025-06-20', 10.00),
('Amor y Amistad 2025',         'Temporada',    '2025-09-10', '2025-09-20', 12.00);
GO

PRINT '✔ Campañas insertadas';

-- ============================================================
-- 7. VENDEDORES (20 vendedores, 2 por tienda)
-- ============================================================
DECLARE @nombres_v TABLE (n VARCHAR(100));
INSERT INTO @nombres_v VALUES
('Carlos Ramírez Gómez'),('Laura Martínez López'),('Andrés Torres Silva'),
('María Pérez Vargas'),('José García Moreno'),('Ana Rodríguez Castro'),
('Daniel Hernández Ruiz'),('Valentina Sánchez Díaz'),('Felipe López Jiménez'),
('Catalina Gómez Reyes'),('Sebastián Castro Molina'),('Juliana Torres Álvarez'),
('Nicolás Vargas Mendoza'),('Isabella Moreno Fernández'),('Alejandro Díaz Ramírez'),
('Mariana Ruiz Herrera'),('David Jiménez Suárez'),('Sofía Álvarez Medina'),
('Miguel Reyes Ortega'),('Paula Mendoza Ibáñez');

INSERT INTO Vendedores (Documento, NombreVendedor, TiendaID, CanalID, FechaIngreso)
SELECT
    CAST(10000000 + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) * 113 AS VARCHAR),
    n,
    CASE
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 2  THEN 1
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 4  THEN 2
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 6  THEN 3
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 8  THEN 4
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 10 THEN 5
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 12 THEN 6
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 14 THEN 7
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 16 THEN 8
        WHEN ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) <= 18 THEN 9
        ELSE 10
    END,
    (ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) % 5) + 1,
    DATEADD(DAY, -(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) * 45 + 100), GETDATE())
FROM @nombres_v;
GO

PRINT '✔ Vendedores insertados: ' + CAST(@@ROWCOUNT AS VARCHAR);

-- ============================================================
-- 8. PRODUCTOS (200 productos)
-- ============================================================
DECLARE @p INT = 1;
DECLARE @cat INT, @prov INT, @precio DECIMAL(18,2), @costo DECIMAL(18,2);

WHILE @p <= 200
BEGIN
    SET @cat   = (@p % 8) + 1;
    SET @prov  = (@p % 20) + 1;
    SET @precio = CAST(10000 + (ABS(CHECKSUM(NEWID())) % 490001) AS DECIMAL(18,2));
    SET @costo  = CAST(@precio * (0.45 + (ABS(CHECKSUM(NEWID())) % 26) * 0.01) AS DECIMAL(18,2));

    INSERT INTO Productos (CodigoSKU, NombreProducto, CategoriaID, ProveedorID,
                           PrecioUnitario, CostoUnitario, UnidadMedida, StockMinimo)
    VALUES (
        'SKU-' + RIGHT('000' + CAST(@p AS VARCHAR), 4),
        'Producto ' + RIGHT('000' + CAST(@p AS VARCHAR), 3) + ' Cat-' + CAST(@cat AS VARCHAR),
        @cat,
        @prov,
        @precio,
        @costo,
        CASE @cat % 3 WHEN 0 THEN 'UND' WHEN 1 THEN 'KG' ELSE 'PAR' END,
        5 + (@p % 20)
    );

    SET @p = @p + 1;
END
GO

PRINT '✔ Productos insertados: 200';

-- ============================================================
-- 9. CLIENTES (1.000 clientes)
-- ============================================================
DECLARE @c INT = 1;
DECLARE @ciudades_ids TABLE (id INT, rn INT IDENTITY(1,1));
INSERT INTO @ciudades_ids (id) SELECT CiudadID FROM Ciudades;

DECLARE @num_ciudades INT = (SELECT COUNT(*) FROM Ciudades);

WHILE @c <= 1000
BEGIN
    DECLARE @ciudad_id INT = (
        SELECT id FROM @ciudades_ids WHERE rn = (@c % @num_ciudades) + 1
    );

    INSERT INTO Clientes (Documento, TipoDocumento, NombreCliente, Email, Telefono,
                          CiudadID, Segmento, FechaNacimiento)
    VALUES (
        CAST(10000000 + @c * 97 AS VARCHAR),
        CASE @c % 4 WHEN 0 THEN 'CC' WHEN 1 THEN 'CE' WHEN 2 THEN 'NIT' ELSE 'CC' END,
        'Cliente ' + RIGHT('0000' + CAST(@c AS VARCHAR), 4) + ' Apellido' + CAST(@c % 50 AS VARCHAR),
        'cliente' + CAST(@c AS VARCHAR) + '@mail.com',
        '3' + RIGHT('000000000' + CAST(ABS(CHECKSUM(NEWID())) % 1000000000 AS VARCHAR), 9),
        @ciudad_id,
        CASE @c % 10
            WHEN 0 THEN 'VIP'
            WHEN 1 THEN 'Premium'
            WHEN 2 THEN 'Premium'
            WHEN 3 THEN 'Regular'
            ELSE 'General'
        END,
        DATEADD(DAY, -(365 * 18 + ABS(CHECKSUM(NEWID())) % (365 * 45)), GETDATE())
    );
    SET @c = @c + 1;
END
GO

PRINT '✔ Clientes insertados: 1000';

-- ============================================================
-- 10. VENTAS Y DETALLE DE VENTAS (50.000 ventas ~ 150.000 líneas)
-- Generadas entre 2023-01-01 y 2025-12-31
-- ============================================================
DECLARE @v        INT = 1;
DECLARE @fecha_v  DATETIME;
DECLARE @cliente  INT;
DECLARE @tienda   INT;
DECLARE @vendedor INT;
DECLARE @canal    INT;
DECLARE @campana  INT;
DECLARE @subtotal DECIMAL(18,2);
DECLARE @descto   DECIMAL(18,2);
DECLARE @total    DECIMAL(18,2);
DECLARE @lineas   INT;
DECLARE @l        INT;
DECLARE @prod     INT;
DECLARE @cant     INT;
DECLARE @precio_l DECIMAL(18,2);
DECLARE @costo_l  DECIMAL(18,2);
DECLARE @desc_pct DECIMAL(5,2);
DECLARE @total_l  DECIMAL(18,2);
DECLARE @ventaID  INT;
DECLARE @dias_rango INT = DATEDIFF(DAY, '2023-01-01', '2025-12-31');

WHILE @v <= 50000
BEGIN
    SET @fecha_v  = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % @dias_rango, '2023-01-01');
    SET @cliente  = (ABS(CHECKSUM(NEWID())) % 1000) + 1;
    SET @tienda   = (ABS(CHECKSUM(NEWID())) % 10) + 1;
    SET @canal    = (ABS(CHECKSUM(NEWID())) % 5) + 1;

    -- Vendedor debe pertenecer a la tienda
    SELECT TOP 1 @vendedor = VendedorID
    FROM Vendedores
    WHERE TiendaID = @tienda
    ORDER BY NEWID();

    IF @vendedor IS NULL SET @vendedor = 1;

    -- Campaña activa en la fecha (50% probabilidad)
    SET @campana = NULL;
    IF ABS(CHECKSUM(NEWID())) % 2 = 0
    BEGIN
        SELECT TOP 1 @campana = CampanaID
        FROM Campanas
        WHERE @fecha_v BETWEEN FechaInicio AND FechaFin AND Activo = 1
        ORDER BY NEWID();
    END

    -- Líneas de venta: entre 1 y 6
    SET @lineas = 1 + ABS(CHECKSUM(NEWID())) % 6;
    SET @subtotal = 0;
    SET @descto   = 0;

    INSERT INTO Ventas (NumeroFactura, ClienteID, TiendaID, VendedorID, CanalID, CampanaID,
                        FechaVenta, Subtotal, TotalDescuento, TotalImpuesto, TotalVenta, Estado)
    VALUES (
        'FAC-' + RIGHT('000000' + CAST(@v AS VARCHAR), 8),
        @cliente, @tienda, @vendedor, @canal, @campana,
        @fecha_v, 0, 0, 0, 0,
        CASE WHEN ABS(CHECKSUM(NEWID())) % 100 < 3 THEN 'Anulada' ELSE 'Completada' END
    );

    SET @ventaID = SCOPE_IDENTITY();

    -- Insertar líneas de detalle
    SET @l = 1;
    WHILE @l <= @lineas
    BEGIN
        SET @prod    = (ABS(CHECKSUM(NEWID())) % 200) + 1;
        SET @cant    = 1 + ABS(CHECKSUM(NEWID())) % 5;

        SELECT @precio_l = PrecioUnitario, @costo_l = CostoUnitario
        FROM Productos WHERE ProductoID = @prod;

        SET @desc_pct = CASE
            WHEN @campana IS NOT NULL THEN
                ISNULL((SELECT DescuentoPct FROM Campanas WHERE CampanaID = @campana), 0)
            ELSE
                CASE WHEN ABS(CHECKSUM(NEWID())) % 10 = 0
                     THEN CAST(ABS(CHECKSUM(NEWID())) % 16 AS DECIMAL(5,2))
                     ELSE 0 END
        END;

        SET @total_l = ROUND(@cant * @precio_l * (1 - @desc_pct / 100.0), 2);

        INSERT INTO DetalleVentas (VentaID, ProductoID, Cantidad, PrecioUnitario,
                                   CostoUnitario, DescuentoPct, TotalLinea)
        VALUES (@ventaID, @prod, @cant, @precio_l, @costo_l, @desc_pct, @total_l);

        SET @subtotal = @subtotal + (@cant * @precio_l);
        SET @descto   = @descto   + (@cant * @precio_l * @desc_pct / 100.0);
        SET @l = @l + 1;
    END

    SET @total = ROUND(@subtotal - @descto, 2);

    UPDATE Ventas
    SET Subtotal = ROUND(@subtotal, 2),
        TotalDescuento = ROUND(@descto, 2),
        TotalImpuesto  = ROUND(@total * 0.19, 2),  -- IVA 19%
        TotalVenta     = ROUND(@total + (@total * 0.19), 2)
    WHERE VentaID = @ventaID;

    -- Progress cada 5000
    IF @v % 5000 = 0
        PRINT '  ... ' + CAST(@v AS VARCHAR) + ' ventas insertadas';

    SET @v = @v + 1;
END
GO

PRINT '✔ Ventas y DetalleVentas insertadas: 50.000 ventas';

-- ============================================================
-- 11. INVENTARIO DIARIO (muestra 30 productos × 10 tiendas × 365 días)
-- Se generan datos para el año 2025 completo
-- ============================================================
DECLARE @fecha_i DATE = '2025-01-01';
DECLARE @fin_i   DATE = '2025-12-31';
DECLARE @prod_i  INT;
DECLARE @tienda_i INT;
DECLARE @stock_ini INT;
DECLARE @entradas  INT;
DECLARE @salidas   INT;
DECLARE @ajustes   INT;
DECLARE @stock_fin INT;

-- Solo 30 productos y 10 tiendas para mantener volumen manejable (30×10×365 = 109.500 filas)
WHILE @fecha_i <= @fin_i
BEGIN
    SET @prod_i = 1;
    WHILE @prod_i <= 30
    BEGIN
        SET @tienda_i = 1;
        WHILE @tienda_i <= 10
        BEGIN
            SET @stock_ini = 50 + ABS(CHECKSUM(NEWID())) % 451;
            SET @entradas  = CASE WHEN ABS(CHECKSUM(NEWID())) % 7 = 0 THEN ABS(CHECKSUM(NEWID())) % 101 ELSE 0 END;
            SET @salidas   = ABS(CHECKSUM(NEWID())) % (CASE WHEN @stock_ini + @entradas > 5 THEN 6 ELSE 1 END);
            SET @ajustes   = CASE WHEN ABS(CHECKSUM(NEWID())) % 30 = 0 THEN (ABS(CHECKSUM(NEWID())) % 21) - 10 ELSE 0 END;
            SET @stock_fin = @stock_ini + @entradas - @salidas + @ajustes;
            IF @stock_fin < 0 SET @stock_fin = 0;

            INSERT INTO InventarioDiario (FechaInventario, ProductoID, TiendaID,
                                          StockInicial, Entradas, Salidas, Ajustes, StockFinal)
            VALUES (@fecha_i, @prod_i, @tienda_i, @stock_ini, @entradas, @salidas, @ajustes, @stock_fin);

            SET @tienda_i = @tienda_i + 1;
        END
        SET @prod_i = @prod_i + 1;
    END
    SET @fecha_i = DATEADD(DAY, 1, @fecha_i);
END
GO

PRINT '✔ InventarioDiario insertado (30 prod × 10 tiendas × 365 días)';

-- ============================================================
-- 12. COMPRAS Y DETALLE DE COMPRAS
-- ============================================================
DECLARE @comp INT = 1;
DECLARE @fecha_c DATE;
DECLARE @prov_c  INT;
DECLARE @tienda_c INT;
DECLARE @total_c DECIMAL(18,2);
DECLARE @compraID INT;
DECLARE @lc INT;
DECLARE @prod_c INT;
DECLARE @cant_c INT;
DECLARE @costo_c DECIMAL(18,2);

WHILE @comp <= 500
BEGIN
    SET @fecha_c  = DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 1095, '2023-01-01');
    SET @prov_c   = (ABS(CHECKSUM(NEWID())) % 20) + 1;
    SET @tienda_c = (ABS(CHECKSUM(NEWID())) % 10) + 1;
    SET @total_c  = 0;

    INSERT INTO Compras (NumeroOrden, ProveedorID, TiendaID, FechaOrden, FechaRecepcion, TotalCompra, Estado)
    VALUES (
        'OC-' + RIGHT('00000' + CAST(@comp AS VARCHAR), 6),
        @prov_c, @tienda_c, @fecha_c,
        DATEADD(DAY, 3 + ABS(CHECKSUM(NEWID())) % 15, @fecha_c),
        0,
        'Recibida'
    );
    SET @compraID = SCOPE_IDENTITY();

    SET @lc = 1;
    WHILE @lc <= 1 + ABS(CHECKSUM(NEWID())) % 8
    BEGIN
        SET @prod_c = (ABS(CHECKSUM(NEWID())) % 200) + 1;
        SET @cant_c = 10 + ABS(CHECKSUM(NEWID())) % 91;
        SELECT @costo_c = CostoUnitario FROM Productos WHERE ProductoID = @prod_c;

        INSERT INTO DetalleCompras (CompraID, ProductoID, CantidadOrdenada, CantidadRecibida,
                                     CostoUnitario, TotalLinea)
        VALUES (@compraID, @prod_c, @cant_c, @cant_c, @costo_c, ROUND(@cant_c * @costo_c, 2));

        SET @total_c = @total_c + ROUND(@cant_c * @costo_c, 2);
        SET @lc = @lc + 1;
    END

    UPDATE Compras SET TotalCompra = @total_c WHERE CompraID = @compraID;
    SET @comp = @comp + 1;
END
GO

PRINT '✔ Compras y DetalleCompras insertadas: 500 órdenes';

-- ============================================================
-- 13. DEVOLUCIONES (~500 devoluciones)
-- ============================================================
DECLARE @dev INT = 1;
DECLARE @venta_rand INT;
DECLARE @det_rand INT;
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
           @total_l = dv.TotalLinea, @tienda = v.TiendaID, @cliente = v.ClienteID
    FROM Ventas v
    JOIN DetalleVentas dv ON v.VentaID = dv.VentaID
    WHERE v.Estado = 'Completada'
    ORDER BY NEWID();

    DECLARE @motivo_rand VARCHAR(200);
    SELECT TOP 1 @motivo_rand = m FROM @motivos ORDER BY NEWID();

    INSERT INTO Devoluciones (VentaID, DetalleID, ClienteID, TiendaID, ProductoID,
                              FechaDevolucion, MotivoDevolucion, CantidadDevuelta, ValorDevuelto)
    VALUES (@venta_rand, @det_rand, @cliente, @tienda, @prod,
            DATEADD(DAY, ABS(CHECKSUM(NEWID())) % 30 + 1,
                (SELECT FechaVenta FROM Ventas WHERE VentaID = @venta_rand)),
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
                    (1 + (@mes_m IN (11,12)) * 0.30),  -- boost navideño
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
