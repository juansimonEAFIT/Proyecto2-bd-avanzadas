-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 3: Juan Simon Ospina
-- Script: 04_etl_log.sql
-- Descripción: Crea la tabla ETL_Log para bitácora de ejecución de procesos ETL.
-- ============================================================

USE RetailDW;
GO

IF OBJECT_ID('dbo.ETL_Log', 'U') IS NOT NULL
    DROP TABLE dbo.ETL_Log;
GO

CREATE TABLE ETL_Log (
    LogID               INT IDENTITY(1,1) PRIMARY KEY,
    NombreProceso       VARCHAR(100)  NOT NULL,
    FechaInicio         DATETIME      NOT NULL DEFAULT GETDATE(),
    FechaFin            DATETIME      NULL,
    Estado              VARCHAR(20)   NOT NULL DEFAULT 'EN_PROCESO'
        CHECK (Estado IN ('EN_PROCESO','COMPLETADO','ERROR','ADVERTENCIA')),
    RegistrosLeidos     INT           NOT NULL DEFAULT 0,
    RegistrosCargados   INT           NOT NULL DEFAULT 0,
    RegistrosRechazados INT           NOT NULL DEFAULT 0,
    MensajeError        VARCHAR(MAX)  NULL,
    ServidorEjecucion   VARCHAR(100)  NOT NULL DEFAULT @@SERVERNAME,
    UsuarioEjecucion    VARCHAR(100)  NOT NULL DEFAULT SUSER_SNAME()
);
GO

-- ============================================================
-- Procedimiento helper: Iniciar un proceso ETL en el log
-- ============================================================
CREATE OR ALTER PROCEDURE sp_ETL_Log_Iniciar
    @NombreProceso VARCHAR(100),
    @LogID INT OUTPUT
AS
BEGIN
    INSERT INTO ETL_Log (NombreProceso, FechaInicio, Estado)
    VALUES (@NombreProceso, GETDATE(), 'EN_PROCESO');

    SET @LogID = SCOPE_IDENTITY();
END;
GO

-- ============================================================
-- Procedimiento helper: Finalizar un proceso ETL en el log
-- ============================================================
CREATE OR ALTER PROCEDURE sp_ETL_Log_Finalizar
    @LogID          INT,
    @Estado         VARCHAR(20),
    @Leidos         INT,
    @Cargados       INT,
    @Rechazados     INT,
    @MensajeError   VARCHAR(MAX) = NULL
AS
BEGIN
    UPDATE ETL_Log
    SET FechaFin            = GETDATE(),
        Estado              = @Estado,
        RegistrosLeidos     = @Leidos,
        RegistrosCargados   = @Cargados,
        RegistrosRechazados = @Rechazados,
        MensajeError        = @MensajeError
    WHERE LogID = @LogID;
END;
GO

PRINT '✔ Tabla ETL_Log y procedimientos sp_ETL_Log_Iniciar / sp_ETL_Log_Finalizar creados.';
