-- ============================================================
-- PROYECTO 3 - BI para análisis integral de ventas, inventario y rentabilidad
-- Base de Datos Avanzadas SI3009 (2026-1) - Universidad EAFIT
-- Personas 2 y 3: Sebastian Duran / Juan Simon Ospina
-- Script: 01_create_dw_database.sql
-- Descripción: Crea la base de datos del Data Warehouse (RetailDW)
-- ============================================================

USE master;
GO

-- La eliminación previa de RetailDW se maneja de forma segura desde el script de automatización Python
CREATE DATABASE RetailDW;
GO

ALTER DATABASE RetailDW SET RECOVERY SIMPLE;
GO

PRINT '✔ Base de datos RetailDW creada exitosamente.';
