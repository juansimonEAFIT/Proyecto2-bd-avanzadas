# Evidencias de Validación - Fase 2 

Este documento contiene los resultados obtenidos tras la ejecución del pipeline de Staging y la creación/carga de las dimensiones del Data Warehouse.

## 1. Reporte de Calidad de Datos (BI_Staging.dbo.QA_Reporte)

| Tabla Origen | Tipo de Validación | Total Reg. | Reg. OK | Reg. Error | % Error | Detalle |
|---|---|---|---|---|---|---|
| STG_Clientes | Limpieza Nulos + Estandarizacion | 1000 | 1000 | 0 | 0.00% | Email/Telefono/Ciudad nulos corregidos; campos estandarizados a UPPER |
| STG_Productos | Normalizacion Categorias + Validacion Precios | 200 | 200 | 0 | 0.00% | Categorias normalizadas; productos con margen negativo marcados como RECHAZADO |
| STG_Ventas | Validacion Fechas + Estado + Totales | 50000 | 50000 | 0 | 0.00% | Fechas futuras y anteriores a 2020 marcadas; totales negativos rechazados |
| STG_DetalleVentas | Integridad Referencial + Cantidades + Precios | 174878 | 174878 | 0 | 0.00% | Líneas huerfanas, cantidades y precios inválidos marcados como RECHAZADO |
| STG_Ventas | Deteccion Duplicados NumeroFactura | 50000 | 50000 | 0 | 0.00% | Duplicados por NumeroFactura: solo se carga el primer registro |
| STG_Inventario | Validacion Stock Negativo + Integridad Referencial | 109500 | 109500 | 0 | 0.00% | Stock negativo marcado como SOSPECHOSO; productos sin referencia como RECHAZADO |
| STG_MetasExternas | Validacion ValorMeta y Mes | 85 | 85 | 0 | 0.00% | Metas con valor <= 0 o mes inválido rechazadas |


## 2. Conteos de Dimensiones en el Data Warehouse (RetailDW)

| Dimensión | Total de Registros |
|---|---|
| DimFecha | 1,461 |
| DimCliente | 1,001 |
| DimProducto | 201 |
| DimTienda | 11 |
| DimVendedor | 21 |
| DimProveedor | 21 |
| DimCanalVenta | 6 |
| DimPromocion | 13 |
| DimGeografia | 20 |


## 3. Registro de Ejecución del ETL (RetailDW.dbo.ETL_Log)

| Nombre del Proceso | Estado | Reg. Leídos | Reg. Cargados | Reg. Rechazados | Duración (seg) | Mensaje de Error |
|---|---|---|---|---|---|---|
| CargarDimFecha | COMPLETADO | 1,461 | 1,461 | 0 | 2s | Ninguno |
| CargarDimGeografia | COMPLETADO | 1,000 | 19 | 0 | 0s | Ninguno |
| CargarDimCliente | COMPLETADO | 1,000 | 1,000 | 0 | 0s | Ninguno |
| CargarDimProducto | COMPLETADO | 200 | 200 | 0 | 0s | Ninguno |
| CargarDimTienda | COMPLETADO | 10 | 10 | 0 | 0s | Ninguno |
| CargarDimVendedor | COMPLETADO | 20 | 20 | 0 | 0s | Ninguno |
| CargarDimProveedor | COMPLETADO | 20 | 20 | 0 | 0s | Ninguno |
| CargarDimCanalVenta | COMPLETADO | 5 | 5 | 0 | 0s | Ninguno |
| CargarDimPromocion | COMPLETADO | 12 | 12 | 0 | 0s | Ninguno |

