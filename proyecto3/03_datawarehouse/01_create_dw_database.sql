-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Personas 2 y 3: Sebastian Duran / Juan Simon Ospina
-- Script: 01_create_dw_database.sql
-- Descripción: Crea la base de datos del Data Warehouse (RetailDW)
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'RetailDW')
BEGIN
    ALTER DATABASE RetailDW SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RetailDW;
    PRINT 'Base de datos RetailDW eliminada para re-creación.';
END
GO

CREATE DATABASE RetailDW
    ON PRIMARY (
        NAME = RetailDW_data,
        FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\RetailDW.mdf',
        SIZE = 1024MB,
        MAXSIZE = UNLIMITED,
        FILEGROWTH = 256MB
    )
    LOG ON (
        NAME = RetailDW_log,
        FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\DATA\RetailDW_log.ldf',
        SIZE = 128MB,
        MAXSIZE = 4GB,
        FILEGROWTH = 128MB
    );
GO

ALTER DATABASE RetailDW SET RECOVERY SIMPLE;
GO

PRINT '✔ Base de datos RetailDW creada exitosamente.';
