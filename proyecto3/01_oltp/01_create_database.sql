-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Persona 1: Alejandro Posada
-- Script: 01_create_database.sql
-- Descripción: Crea la base de datos OLTP RetailOLTP
-- ============================================================

USE master;
GO

-- Eliminar si existe (para re-ejecución limpia)
IF EXISTS (SELECT name FROM sys.databases WHERE name = 'RetailOLTP')
BEGIN
    ALTER DATABASE RetailOLTP SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE RetailOLTP;
    PRINT 'Base de datos RetailOLTP eliminada.';
END
GO

-- Crear la base de datos
CREATE DATABASE RetailOLTP;
GO

PRINT 'Base de datos RetailOLTP creada exitosamente.';

USE RetailOLTP;
GO

-- Configurar opciones de la base de datos
ALTER DATABASE RetailOLTP SET RECOVERY SIMPLE;          -- Simplifica manejo de logs
ALTER DATABASE RetailOLTP SET READ_COMMITTED_SNAPSHOT ON; -- Mejora concurrencia
GO

PRINT 'Configuración de RetailOLTP completada.';
