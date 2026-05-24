-- ============================================================
-- ETL: CargarDimFecha
-- Carga el calendario completo desde 2023-01-01 hasta 2026-12-31
-- ============================================================
USE RetailDW;
GO

CREATE OR ALTER PROCEDURE CargarDimFecha
    @FechaInicio DATE = '2023-01-01',
    @FechaFin    DATE = '2026-12-31'
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @LogID INT, @cnt INT = 0;

    EXEC sp_ETL_Log_Iniciar 'CargarDimFecha', @LogID OUTPUT;

    BEGIN TRY
        DECLARE @f DATE = @FechaInicio;

        WHILE @f <= @FechaFin
        BEGIN
            DECLARE @key INT = YEAR(@f) * 10000 + MONTH(@f) * 100 + DAY(@f);

            IF NOT EXISTS (SELECT 1 FROM DimFecha WHERE FechaKey = @key)
            BEGIN
                INSERT INTO DimFecha (
                    FechaKey, Fecha, Anio, Trimestre, NombreTrimestre,
                    MesNum, NombreMes, AbrevMes, Semana,
                    DiaMes, DiaSemanaNum, NombreDia, AbrevDia,
                    EsFinDeSemana, AnioMes, AnioTrimestre
                )
                VALUES (
                    @key,
                    @f,
                    YEAR(@f),
                    DATEPART(QUARTER, @f),
                    'Q' + CAST(DATEPART(QUARTER, @f) AS VARCHAR(10)),
                    MONTH(@f),
                    CASE MONTH(@f)
                        WHEN 1 THEN 'Enero'     WHEN 2 THEN 'Febrero'
                        WHEN 3 THEN 'Marzo'     WHEN 4 THEN 'Abril'
                        WHEN 5 THEN 'Mayo'      WHEN 6 THEN 'Junio'
                        WHEN 7 THEN 'Julio'     WHEN 8 THEN 'Agosto'
                        WHEN 9 THEN 'Septiembre' WHEN 10 THEN 'Octubre'
                        WHEN 11 THEN 'Noviembre' ELSE 'Diciembre'
                    END,
                    CASE MONTH(@f)
                        WHEN 1 THEN 'Ene' WHEN 2 THEN 'Feb' WHEN 3 THEN 'Mar'
                        WHEN 4 THEN 'Abr' WHEN 5 THEN 'May' WHEN 6 THEN 'Jun'
                        WHEN 7 THEN 'Jul' WHEN 8 THEN 'Ago' WHEN 9 THEN 'Sep'
                        WHEN 10 THEN 'Oct' WHEN 11 THEN 'Nov' ELSE 'Dic' END,
                    DATEPART(WEEK, @f),
                    DAY(@f),
                    DATEPART(WEEKDAY, @f),
                    CASE DATEPART(WEEKDAY, @f)
                        WHEN 1 THEN 'Domingo'   WHEN 2 THEN 'Lunes'
                        WHEN 3 THEN 'Martes'    WHEN 4 THEN 'Miercoles'
                        WHEN 5 THEN 'Jueves'    WHEN 6 THEN 'Viernes'
                        ELSE 'Sabado'
                    END,
                    CASE DATEPART(WEEKDAY, @f)
                        WHEN 1 THEN 'Dom' WHEN 2 THEN 'Lun' WHEN 3 THEN 'Mar'
                        WHEN 4 THEN 'Mie' WHEN 5 THEN 'Jue' WHEN 6 THEN 'Vie'
                        ELSE 'Sab' END,
                    CASE WHEN DATEPART(WEEKDAY, @f) IN (1, 7) THEN 1 ELSE 0 END,
                    YEAR(@f) * 100 + MONTH(@f),
                    CAST(YEAR(@f) AS VARCHAR(10)) + '-Q' + CAST(DATEPART(QUARTER, @f) AS VARCHAR(10))
                );
                SET @cnt = @cnt + 1;
            END

            SET @f = DATEADD(DAY, 1, @f);
        END

        -- Marcar feriados colombianos más importantes
        UPDATE DimFecha SET EsFeriado = 1, NombreFeriado = 'Ano Nuevo'
        WHERE MesNum = 1 AND DiaMes = 1;
        UPDATE DimFecha SET EsFeriado = 1, NombreFeriado = 'Dia del Trabajo'
        WHERE MesNum = 5 AND DiaMes = 1;
        UPDATE DimFecha SET EsFeriado = 1, NombreFeriado = 'Grito de Independencia'
        WHERE MesNum = 7 AND DiaMes = 20;
        UPDATE DimFecha SET EsFeriado = 1, NombreFeriado = 'Dia de la Independencia'
        WHERE MesNum = 8 AND DiaMes = 7;
        UPDATE DimFecha SET EsFeriado = 1, NombreFeriado = 'Dia de la Raza'
        WHERE MesNum = 10 AND DiaMes = 12;
        UPDATE DimFecha SET EsFeriado = 1, NombreFeriado = 'Navidad'
        WHERE MesNum = 12 AND DiaMes = 25;

        EXEC sp_ETL_Log_Finalizar @LogID, 'COMPLETADO', @cnt, @cnt, 0, NULL;
        PRINT '[OK] CargarDimFecha completado: ' + CAST(@cnt AS VARCHAR(10)) + ' dias cargados';
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage VARCHAR(MAX) = ERROR_MESSAGE();
        EXEC sp_ETL_Log_Finalizar @LogID, 'ERROR', 0, 0, 0, @ErrorMessage;
        THROW;
    END CATCH
END;
GO

EXEC CargarDimFecha;
GO
