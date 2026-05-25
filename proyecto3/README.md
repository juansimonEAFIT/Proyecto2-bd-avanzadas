# Proyecto 3 — BI para Análisis Integral de Ventas, Inventario y Rentabilidad

**Bases de Datos Avanzadas - SI3009 (2026-1)**  
**Ingeniería de Sistemas — Universidad EAFIT**

---

## Integrantes

| # | Nombre | Responsabilidad Principal |
|---|--------|--------------------------|
| 1 | **Alejandro Posada** | Infraestructura Azure + Base OLTP |
| 2 | **Sebastian Duran** | Staging + ETL Dimensiones |
| 3 | **Juan Simon Ospina** | Data Warehouse + ETL Hechos |
| 4 | **Daniel Arcila** | Power BI + Informe Técnico |

---

## Descripción del Proyecto

Solución completa de **Business Intelligence** para una empresa minorista con múltiples sedes en Colombia. El proyecto implementa un pipeline end-to-end desde datos transaccionales OLTP hasta dashboards ejecutivos en Power BI, desplegado en Azure.

### La gerencia puede tomar decisiones sobre:
- Ventas y rentabilidad
- Inventario y rotación de productos
- Desempeño de vendedores y tiendas
- Cumplimiento de metas comerciales
- Comportamiento de clientes por segmento

---

## Arquitectura General

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS RDS (SQL Server)                     │
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────────┐   │
│  │  RetailOLTP  │───▶│  BI_Staging  │───▶│    RetailDW      │   │
│  │  (13 tablas) │    │ (+ CSV/Excel)│    │ (9 Dims + 4 Facts│   │
│  └──────────────┘    └──────────────┘    └──────────────────┘   │
│         ▲                   ▲                       │           │
│   Scripts OLTP         Scripts ETL             ETL_Log          │
└─────────────────────────────────────────────────────────────────┘
                                                      │
                                                      ▼
                                          ┌──────────────────────┐
                                          │  Power BI Service    │
                                          │  (6 páginas de       │
                                          │   dashboard)         │
                                          └──────────────────────┘
```

---

## Estructura del Repositorio

```
proyecto3/
├── README.md                         ← Este archivo
├── TODO.md                           ← Tareas distribuidas por persona
├── PROYECTO3.md                      ← Enunciado original del profesor
│
├── 01_oltp/                          ← Base de datos transaccional
│   ├── 01_create_database.sql           ← Crear BD RetailOLTP
│   ├── 02_create_tables.sql             ← 13+ tablas OLTP normalizadas
│   ├── 03_generate_data.sql             ← Datos sintéticos (50K ventas)
│   └── 04_generate_data_restante.sql    ← Completar generación de datos
│
├── 02_staging/                       ← Zona de integración intermedia
│   ├── 01_create_staging.sql            ← Crear BD BI_Staging
│   ├── 02_load_staging.sql              ← Cargar OLTP → Staging + CSV
│   └── 03_quality_checks.sql           ← Limpieza y validaciones
│
├── 03_datawarehouse/                 ← Modelo dimensional (estrella)
│   ├── 01_create_dw_database.sql        ← Crear BD RetailDW
│   ├── 02_create_dimensions.sql         ← 9 dimensiones
│   ├── 03_create_facts.sql              ← 4 tablas de hechos
│   └── 04_etl_log.sql                  ← Tabla ETL_Log
│
├── 04_etl/                           ← Procedimientos ETL en T-SQL
│   ├── 00_ETL_Master.sql                ← Orquestador principal
│   ├── 01_CargarDimFecha.sql            ← ETL de la dimensión Fecha
│   ├── 02_CargarDimensiones.sql         ← ETL consolidado de todas las dimensiones (Cliente, Producto, etc.)
│   ├── 10_CargarFactVentas.sql
│   ├── 11_CargarFactInventario.sql
│   ├── 12_CargarFactMetas.sql
│   ├── 13_CargarFactDevoluciones.sql
│   └── 14_ValidarCalidadDatos.sql
│
├── 05_external_sources/              ← Fuentes externas (CSV/Excel)
│   ├── metas_mensuales.csv              ← Metas por tienda/categoría
│   ├── inventario_fisico.csv            ← Ajustes manuales inventario
│   └── README_import.md                 ← Instrucciones de importación
│
├── 06_powerbi/                       ← Archivos Power BI
│   ├── RetailBI.pbix                    ← [Agregar tras construir]
│   ├── medidas_dax.md                   ← Todas las medidas DAX
│   └── README_powerbi.md               ← Instrucciones de conexión
│
└── 07_docs/                          ← Documentación técnica
    ├── diccionario_datos.md             ← Diccionario de todas las tablas
    ├── modelo_dimensional.md            ← Diagrama y descripción del DW
    └── justificacion_modelo.md         ← Respuestas a preguntas del profesor
│
└── 08_scripts/                       ← Scripts de apoyo y utilidades
    ├── load_csvs.py                     ← Carga de CSV a BD
    ├── .env                             ← Credenciales
    └── requirements.txt                 ← Dependencias Python
```

---

## Prerrequisitos

| Herramienta | Versión | Uso |
|-------------|---------|-----|
| AWS Account | — | Hosting de la BD en RDS |
| SQL Server | Express (RDS) | Motor de base de datos |
| SSMS | 19+ | Administración SQL |
| Power BI Desktop | Última | Desarrollo del dashboard |
| Power BI Pro / Trial | — | Publicación en la nube |

---

## Instrucciones de Ejecución

### Paso 1 — Configurar la instancia SQL Server en AWS RDS *(Persona 1)*

Ver **TODO.md → Persona 1** para instrucciones detalladas.

### Paso 2 — Crear y poblar el OLTP *(Persona 1)*

```sql
-- Ejecutar en SSMS en este orden:
-- 1. Crear la base de datos
\01_oltp\01_create_database.sql

-- 2. Crear las tablas
\01_oltp\02_create_tables.sql

-- 3. Generar datos sintéticos (puede tardar 10-20 min)
\01_oltp\03_generate_data.sql
\01_oltp\04_generate_data_restante.sql
```

### Paso 2.5 — Cargar Archivos Externos CSV *(Persona 1)*
```bash
cd 08_scripts
python load_csvs.py
```

### Paso 3 — Configurar Staging *(Persona 2)*

```sql
\02_staging\01_create_staging.sql
\02_staging\02_load_staging.sql
\02_staging\03_quality_checks.sql
```

### Paso 4 — Crear el Data Warehouse *(Personas 2 y 3)*

```sql
\03_datawarehouse\01_create_dw_database.sql
\03_datawarehouse\02_create_dimensions.sql
\03_datawarehouse\03_create_facts.sql
\03_datawarehouse\04_etl_log.sql
```

### Paso 5 — Ejecutar el ETL completo *(Persona 3)*

```sql
USE RetailDW;
EXEC ETL_Master;   -- Corre todo el pipeline end-to-end
```

### Paso 6 — Conectar Power BI y publicar *(Persona 4)*

Ver **`06_powerbi/README_powerbi.md`** para instrucciones completas.

---

## Acceso al Servidor

| Campo | Valor |
|-------|-------|
| Endpoint AWS RDS | `retailbi-sqlserver-xlarge2.cq05vkzr8bgv.us-east-1.rds.amazonaws.com` |
| Puerto SQL Server | `1433` |
| Usuario SQL | `retail_admin` |
| URL Power BI Dashboard | `https://app.powerbi.com/view?r=eyJrIjoiMjA3NDhjNDktZTBjNi00OTcxLTgwMDgtNTBmYzczOGZlMTBlIiwidCI6Ijk5ZjdiNTVlLTljYmUtNDY3Yi04MTQzLTkxOTc4MjkxOGFmYiIsImMiOjR9` |

---

## Modelo Dimensional — Resumen

### Dimensiones (9)
| Dimensión | Descripción |
|-----------|-------------|
| `DimFecha` | Calendario completo con jerarquías (día/semana/mes/trimestre/año) |
| `DimCliente` | Datos de clientes con segmento |
| `DimProducto` | Productos con categoría y proveedor |
| `DimTienda` | Tiendas con ciudad y región |
| `DimVendedor` | Vendedores por tienda |
| `DimProveedor` | Proveedores de productos |
| `DimCanalVenta` | Canal (presencial, online, telefónico) |
| `DimPromocion` | Campañas y descuentos |
| `DimGeografia` | Ciudades y departamentos de Colombia |

### Tablas de Hechos (4)
| Hecho | Granularidad | Métricas |
|-------|-------------|---------|
| `FactVentas` | Línea de venta (producto×cliente×tienda×fecha) | ValorVenta, CostoTotal, Cantidad, Descuento |
| `FactInventarioDiario` | Día × Producto × Tienda | StockInicial, Entradas, Salidas, StockFinal |
| `FactMetasComerciales` | Mes × Tienda × Categoría | ValorMeta |
| `FactDevoluciones` | Devolución individual | ValorDevuelto, CantidadDevuelta |

---

## Criterios de Evaluación

| Criterio | Peso |
|----------|------|
| Diseño OLTP correcto y realista | 10% |
| Diseño dimensional: hechos, dimensiones, granularidad | 20% |
| ETL en SQL Server con staging, limpieza y logs | 20% |
| Calidad del modelo Power BI | 15% |
| Medidas DAX y análisis avanzado | 15% |
| Dashboard, storytelling y visualización | 10% |
| Informe técnico y justificación conceptual | 10% |

---

## Política de Uso de IA

Este proyecto fue apoyado parcialmente con IA (scripts SQL, estructura inicial de dimensiones, medidas DAX básicas). Todo el código fue revisado, adaptado y ejecutado por los integrantes. El diseño de granularidad, la arquitectura del pipeline y la sustentación son responsabilidad del equipo.

Ver sección de **Ética y Uso de IA** en el informe técnico PDF.

---

*Universidad EAFIT — Ingeniería de Sistemas — 2026-1*
