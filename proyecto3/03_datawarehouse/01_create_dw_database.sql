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

CREATE DATABASE RetailDW;
GO

ALTER DATABASE RetailDW SET RECOVERY SIMPLE;
GO

PRINT '✔ Base de datos RetailDW creada exitosamente.';
