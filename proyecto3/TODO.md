# TODO — Proyecto 3: RetailBI

**Bases de Datos Avanzadas - SI3009 (2026-1) — Universidad EAFIT**

> **Arquitectura final:** SQL Server en **AWS RDS** (acceso remoto por endpoint publico) + Dashboard publicado en **Power BI Service (Azure)**.
> Las tareas son secuenciales: Persona 2 depende de Persona 1, Persona 3 de Persona 2, y Persona 4 de Persona 3.

---

# PARTE 1: CHECKLISTS

---

## ALEJANDRO POSADA — Persona 1: Infraestructura AWS RDS + OLTP

**1.1 Crear la instancia de SQL Server en AWS RDS**
- [x] Crear o acceder a la cuenta AWS (console.aws.amazon.com)
- [x] Ir a RDS → Create database con los siguientes parametros:
  - Engine: Microsoft SQL Server
  - Edition: SQL Server Express (gratuito con Free Tier) o SQL Server Web
  - DB instance identifier: `retailbi-sqlserver`
  - Master username: `retail_admin`
  - Master password: definir una contrasena segura y anotarla
  - DB instance class: `db.t3.micro` (Free Tier eligible)
  - Storage: 20 GiB gp2
  - Public access: **Yes** (para que todos puedan conectarse por SSMS)
  - VPC Security Group: crear uno nuevo o usar default
- [x] Esperar a que el estado cambie a **Available** (aprox. 10 min)
- [x] Anotar el **Endpoint** de la instancia (formato: `retailbi-sqlserver.xxxx.us-east-1.rds.amazonaws.com`)
- [x] Agregar regla de entrada al Security Group: puerto 1433, TCP, source 0.0.0.0/0
- [x] Verificar conexion exitosa desde SSMS local usando el endpoint:1433
- [x] Registrar el endpoint en el README.md del proyecto

**1.2 Instalar SSMS localmente y verificar conexion**
- [x] Descargar e instalar SSMS desde https://aka.ms/ssmsfullsetup (si no lo tiene instalado)
- [x] Conectarse a la instancia RDS:
  - Server name: `[ENDPOINT_RDS],1433`
  - Authentication: SQL Server Authentication
  - Login: `retail_admin`
  - Password: la definida en 1.1
- [x] Verificar conexion exitosa
- [x] Compartir endpoint, usuario y contrasena con el resto del equipo

**1.3 Crear la Base de Datos OLTP y sus Tablas**
- [x] Ejecutar 01_oltp/01_create_database.sql
- [x] Ejecutar 01_oltp/02_create_tables.sql
- [x] Verificar que las 16 tablas fueron creadas
- [x] Confirmar que las FK, CHECK y NOT NULL estan aplicadas

**1.4 Generar Datos Sinteticos**
- [x] Ejecutar 01_oltp/03_generate_data.sql (puede tardar 10-20 minutos)
- [x] Verificar que se generaron minimo 1.000 clientes
- [x] Verificar que se generaron minimo 200 productos
- [x] Verificar 10 tiendas y 20 vendedores
- [x] Verificar minimo 50.000 ventas y 150.000 lineas de detalle
- [x] Verificar 365 registros de inventario diario
- [x] Verificar 12 meses de metas comerciales
- [x] Confirmar integridad referencial (sin huerfanos)

**1.5 Cargar Archivos Externos CSV via Script Python**
- [x] Verificar que los archivos `metas_mensuales.csv` e `inventario_fisico.csv` estan en la carpeta `05_external_sources/` del repositorio
- [x] Configurar el archivo `.env` con las credenciales de RDS (ver `.env.example`)
- [x] Ejecutar el script Python para cargar los CSV a las tablas de staging externas:
  ```bash
  cd 08_scripts
  python load_csvs.py
  ```
  (o el metodo equivalente disponible en el proyecto)
- [x] Verificar que los datos de los CSV quedaron cargados en RDS
- [x] Notificar a Sebastian Duran (Persona 2) que el OLTP esta listo

---

## SEBASTIAN DURAN — Persona 2: Staging + ETL Dimensiones

> Prerequisito: Persona 1 debe haber terminado y compartido: endpoint RDS, usuario `retail_admin` y contrasena.

**2.1 Crear la Base de Datos de Staging**
- [ ] Conectarse al RDS desde SSMS:
  - Server name: `[ENDPOINT_RDS],1433`
  - Authentication: SQL Server Authentication
  - Login: `retail_admin`
- [ ] Ejecutar 02_staging/01_create_staging.sql
- [ ] Verificar que la base de datos BI_Staging fue creada
- [ ] Confirmar que las 11 tablas de staging existen (incluida QA_Reporte)

**2.2 Cargar Datos del OLTP al Staging**
- [ ] Ejecutar 02_staging/02_load_staging.sql
- [ ] Verificar que los datos OLTP se copiaron al Staging (INSERT INTO ... SELECT)
- [ ] Verificar que los datos de los CSV externos estan en STG_MetasExternas y STG_InventarioFisico
- [ ] Comparar conteos: Staging vs OLTP

**2.3 Aplicar Transformaciones y Validaciones de Calidad**
- [ ] Ejecutar 02_staging/03_quality_checks.sql
- [ ] Revisar la tabla QA_Reporte en busca de problemas
- [ ] Verificar limpieza de nulos en campos criticos
- [ ] Verificar estandarizacion de ciudades y regiones
- [ ] Verificar eliminacion de duplicados
- [ ] Documentar hallazgos en 07_docs/evidencias_validacion.md

**2.4 Crear la Estructura del Data Warehouse**
- [ ] Ejecutar 03_datawarehouse/01_create_dw_database.sql
- [ ] Ejecutar 03_datawarehouse/02_create_dimensions.sql
- [ ] Ejecutar 03_datawarehouse/03_create_facts.sql
- [ ] Ejecutar 03_datawarehouse/04_etl_log.sql
- [ ] Verificar que existen 9 dimensiones y 4 tablas de hechos
- [ ] Verificar que la tabla ETL_Log fue creada

**2.5 Cargar Dimensiones al Data Warehouse**
- [ ] Ejecutar 04_etl/01_CargarDimFecha.sql
- [ ] Ejecutar los stored procedures del archivo 04_etl/02_CargarDimensiones.sql
- [ ] Verificar conteos en cada dimension
- [ ] Revisar ETL_Log para confirmar ausencia de errores
- [ ] Notificar a Persona 3 (Juan Simon) que las dimensiones estan listas

---

## JUAN SIMON OSPINA — Persona 3: ETL Hechos + Validacion DW

> Prerequisito: Personas 1 y 2 deben haber terminado. El DW debe tener dimensiones cargadas.

**3.1 Cargar Tablas de Hechos**
- [ ] Verificar que las dimensiones estan cargadas antes de comenzar
- [ ] Ejecutar 04_etl/10_CargarFactVentas.sql
- [ ] Ejecutar 04_etl/11_CargarFactInventario.sql
- [ ] Ejecutar 04_etl/12_CargarFactMetas.sql
- [ ] Ejecutar 04_etl/13_CargarFactDevoluciones.sql
- [ ] Verificar conteos en cada tabla de hechos
- [ ] Verificar que no hay surrogate keys sin resolver (valor -1)

**3.2 Verificar y Analizar el ETL_Log**
- [ ] Revisar todos los registros del ETL_Log
- [ ] Confirmar que no hay procesos con Estado = ERROR
- [ ] Calcular tasa de exito (registros cargados / leidos)
- [ ] Identificar y documentar registros rechazados
- [ ] Calcular tiempos de ejecucion de cada proceso

**3.3 Ejecutar el Orquestador Maestro ETL (Prueba End-to-End)**
- [ ] Limpiar (TRUNCATE) todas las tablas del DW
- [ ] Ejecutar 04_etl/00_ETL_Master.sql desde cero
- [ ] Confirmar que el pipeline corre sin errores de inicio a fin
- [ ] Verificar que el ETL_Log registra todos los pasos
- [ ] Comparar conteos finales: OLTP vs DW

**3.4 Ejecutar Validaciones de Calidad del DW**
- [ ] Ejecutar 04_etl/14_ValidarCalidadDatos.sql
- [ ] Verificar que no hay NULLs en medidas criticas de FactVentas
- [ ] Verificar integridad referencial hechos → dimensiones
- [ ] Verificar rangos de fechas en DimFecha
- [ ] Guardar capturas de pantalla de las validaciones como evidencias

**3.5 Consultas Analiticas de Prueba del DW**
- [ ] Ejecutar consulta de ventas por tienda y mes
- [ ] Ejecutar consulta de top 10 productos por margen
- [ ] Ejecutar consulta de cumplimiento de metas
- [ ] Ejecutar consulta de rotacion de inventario
- [ ] Notificar a Persona 4 (Daniel) que el DW esta listo

---

## DANIEL ARCILA — Persona 4: Power BI + Informe Tecnico

> Prerequisito: Personas 1, 2 y 3 deben haber terminado. El DW debe estar completamente cargado y validado.

**4.1 Conectar Power BI Desktop al Data Warehouse en RDS**
- [ ] Instalar Power BI Desktop desde https://powerbi.microsoft.com/desktop/
- [ ] Conectarse al RDS desde Power BI (Get Data → SQL Server):
  - Server: `[ENDPOINT_RDS],1433`
  - Database: `RetailDW`
  - Data Connectivity mode: Import
- [ ] Importar todas las tablas del DW (9 Dims + 4 Facts)
- [ ] Verificar y corregir las relaciones en la vista Model
- [ ] Configurar DimFecha como Date Table
- [ ] Guardar el archivo como 06_powerbi/RetailBI.pbix

**4.2 Crear las Medidas DAX (minimo 15)**
- [ ] Crear tabla _Medidas (tabla de medidas vacia)
- [ ] Implementar 6 medidas base (ventas, costo, utilidad, margen, cantidad, ticket)
- [ ] Implementar 4 medidas de tiempo (anio anterior, crecimiento, YTD, promedio movil)
- [ ] Implementar 3 medidas de metas (total meta, cumplimiento %, brecha)
- [ ] Implementar 2 medidas de inventario (promedio, rotacion)
- [ ] Implementar 3 medidas de ranking y participacion
- [ ] Verificar que todas las medidas retornan valores correctos

**4.3 Construir las 6 Paginas del Dashboard**
- [ ] Crear Pagina 1: Dashboard Ejecutivo (KPIs)
- [ ] Crear Pagina 2: Analisis de Ventas
- [ ] Crear Pagina 3: Inventario
- [ ] Crear Pagina 4: Rentabilidad
- [ ] Crear Pagina 5: Cumplimiento de Metas
- [ ] Crear Pagina 6: Exploracion OLAP (drill-down)
- [ ] Aplicar tema visual consistente en todas las paginas
- [ ] Agregar slicers de filtro en cada pagina

**4.4 Publicar en Power BI Service (Azure)**
- [ ] Ir a https://app.powerbi.com e iniciar sesion con cuenta universitaria
- [ ] Activar trial gratuito de Power BI Pro (60 dias) si no se tiene licencia
- [ ] Publicar el .pbix desde Power BI Desktop → Home → Publish
- [ ] En Power BI Service: configurar credenciales del data source (endpoint RDS, retail_admin, contrasena)
  - El RDS es publico → Power BI Service se conecta directamente, sin necesidad de Gateway
- [ ] Obtener URL publica: File → Embed report → Publish to web (public)
- [ ] Compartir el dashboard con el correo del profesor
- [ ] Registrar la URL publica en el README.md del proyecto

**4.5 Informe Tecnico y Video de Demostracion**
- [ ] Redactar el informe tecnico con todas las secciones requeridas
- [ ] Incluir diagramas ER del OLTP y del modelo dimensional
- [ ] Incluir seccion de justificacion del modelo dimensional
- [ ] Incluir seccion obligatoria de Etica y Uso de IA
- [ ] Exportar informe a PDF
- [ ] Grabar video de demostracion (10-15 minutos)
- [ ] Subir video a YouTube o Microsoft Stream
- [ ] Preparar respuestas para la sustentacion

---

# PARTE 2: PASO A PASO

---

## ALEJANDRO POSADA — Persona 1

### 1.1 Crear la instancia de SQL Server en AWS RDS

1. Ir a https://console.aws.amazon.com e iniciar sesion con la cuenta AWS del equipo.

2. En el buscador superior escribir **RDS** y seleccionarlo. Hacer clic en **Create database**.

3. Completar los campos:

   | Campo | Valor |
   |---|---|
   | Creation method | Standard create |
   | Engine type | Microsoft SQL Server |
   | Database management type | Amazon RDS |
   | Edition | **SQL Server Express Edition** (incluida en Free Tier) |
   | Engine version | SQL Server 2022 (ultima disponible) |
   | Templates | **Free tier** |
   | DB instance identifier | `retailbi-sqlserver` |
   | Master username | `retail_admin` |
   | Master password | definir contrasena segura y anotarla |
   | DB instance class | `db.t3.micro` |
   | Storage type | gp2 |
   | Allocated storage | 20 GiB |
   | Enable storage autoscaling | desmarcar (para controlar costos) |
   | Public access | **Yes** |
   | VPC security group | Create new → nombre: `retailbi-sg` |
   | Availability zone | No preference |
   | Database port | 1433 |

   > **Nota sobre Free Tier:** SQL Server Express en db.t3.micro es gratuito durante 12 meses (750 horas/mes). Tiene limite de 10 GB por base de datos, suficiente para el volumen del proyecto (~150K filas de ventas ≈ 200-400 MB).

4. Clic en **Create database**. Esperar aprox. 10 minutos hasta que el estado sea **Available**.

5. Abrir el Security Group `retailbi-sg`:
   - Ir a VPC → Security Groups → seleccionar `retailbi-sg`
   - Inbound rules → Edit inbound rules → Add rule:
     - Type: Custom TCP
     - Port range: `1433`
     - Source: `0.0.0.0/0` (acceso publico para todo el equipo)
   - Clic en Save rules

6. Copiar el **Endpoint** de la instancia (se ve en RDS → Databases → `retailbi-sqlserver` → Connectivity & security). Tiene el formato:
   ```
   retailbi-sqlserver.xxxxxxxxxxxx.us-east-1.rds.amazonaws.com
   ```
   Registrarlo en el README.md del proyecto.

---

### 1.2 Conectarse desde SSMS y verificar la instancia

1. Descargar e instalar SSMS desde https://aka.ms/ssmsfullsetup si no lo tiene.

2. Abrir SSMS → Connect to Server:
   - Server type: Database Engine
   - Server name: `[ENDPOINT_RDS],1433`
   - Authentication: **SQL Server Authentication**
   - Login: `retail_admin`
   - Password: la definida en 1.1
   - Clic en **Connect**

3. Si la conexion falla, verificar:
   - Que el Security Group tiene la regla de entrada para el puerto 1433
   - Que el parametro **Public access** de la instancia es **Yes** (si no, modificarlo en Modify → Connectivity)
   - Que el firewall local no bloquea el puerto 1433 saliente

4. Una vez conectado, verificar que se puede ejecutar una query simple:
   ```sql
   SELECT @@VERSION;
   SELECT @@SERVERNAME;
   ```

5. Compartir con el equipo: endpoint, usuario `retail_admin` y contrasena.

---

### 1.3 Crear la Base de Datos OLTP y sus Tablas

1. Abrir SSMS y conectarse con `retail_admin` al endpoint RDS.

2. Abrir una nueva ventana de query (File > New Query). Pegar el contenido del archivo `01_oltp/01_create_database.sql` y ejecutar con F5. Resultado esperado: `Command(s) completed successfully`.

3. Verificar que aparece la base de datos `RetailOLTP` en el panel de la izquierda.

4. Abrir una nueva ventana de query. Pegar el contenido de `01_oltp/02_create_tables.sql` y ejecutar.

5. Verificar las tablas creadas ejecutando:
   ```sql
   USE RetailOLTP;
   SELECT TABLE_NAME, TABLE_TYPE
   FROM INFORMATION_SCHEMA.TABLES
   ORDER BY TABLE_NAME;
   ```
   Deben aparecer 16 tablas: Campanas, CanalVenta, Categorias, Ciudades, Clientes, Compras, DetalleCompras, DetalleVentas, Devoluciones, InventarioDiario, MetasComerciales, Productos, Proveedores, Tiendas, Vendedores, Ventas.

6. Verificar constraints ejecutando:
   ```sql
   SELECT tc.TABLE_NAME, tc.CONSTRAINT_NAME, tc.CONSTRAINT_TYPE
   FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
   ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE;
   ```

---

### 1.4 Generar Datos Sinteticos

1. En SSMS con la base de datos `RetailOLTP` activa, abrir el archivo `01_oltp/03_generate_data.sql` y ejecutarlo. El script usa bucles WHILE y la funcion RAND() para generar datos sinteticos. Puede tardar entre 10 y 20 minutos. No cerrar SSMS.

2. Al finalizar, verificar los volumenes generados:
   ```sql
   USE RetailOLTP;
   SELECT 'Ciudades'          AS Tabla, COUNT(*) AS Total FROM Ciudades
   UNION ALL SELECT 'Categorias',       COUNT(*) FROM Categorias
   UNION ALL SELECT 'Proveedores',      COUNT(*) FROM Proveedores
   UNION ALL SELECT 'Productos',        COUNT(*) FROM Productos
   UNION ALL SELECT 'Clientes',         COUNT(*) FROM Clientes
   UNION ALL SELECT 'Tiendas',          COUNT(*) FROM Tiendas
   UNION ALL SELECT 'Vendedores',       COUNT(*) FROM Vendedores
   UNION ALL SELECT 'Ventas',           COUNT(*) FROM Ventas
   UNION ALL SELECT 'DetalleVentas',    COUNT(*) FROM DetalleVentas
   UNION ALL SELECT 'InventarioDiario', COUNT(*) FROM InventarioDiario
   UNION ALL SELECT 'MetasComerciales', COUNT(*) FROM MetasComerciales;
   ```

3. Verificar que no hay huerfanos:
   ```sql
   SELECT COUNT(*) AS HuerfanosDetalle
   FROM DetalleVentas dv
   LEFT JOIN Ventas v ON dv.VentaID = v.VentaID
   WHERE v.VentaID IS NULL;
   ```
   Debe retornar 0.

4. Notificar a Sebastian Duran (Persona 2). Compartir: endpoint RDS, usuario `retail_admin` y contrasena.

---

### 1.5 Cargar Archivos Externos CSV via Script Python

> **Por que no BULK INSERT:** AWS RDS no permite acceso al sistema de archivos del servidor. BULK INSERT requiere que el archivo este en la maquina donde corre SQL Server. En RDS esto no es posible. La solucion es usar el script Python del proyecto para leer los CSV localmente e insertar los datos via conexion ODBC.

1. Asegurarse de tener Python instalado y el archivo `.env` configurado con las credenciales RDS (ver `.env.example`):
   ```
   DB_SERVER=[ENDPOINT_RDS],1433
   DB_USER=retail_admin
   DB_PASSWORD=[contrasena]
   DB_NAME=RetailOLTP
   ```

2. Instalar dependencias si es necesario (desde la carpeta `08_scripts`):
   ```bash
   cd 08_scripts
   pip install -r requirements.txt
   ```

3. Ejecutar el script para cargar los CSV:
   ```bash
   cd 08_scripts
   python load_csvs.py
   ```
   O, si el script no tiene soporte directo de CSV, usar **SSMS → Import Flat File**:
   - Clic derecho en la base de datos `BI_Staging` → Tasks → **Import Flat File...**
   - Seleccionar `metas_mensuales.csv` → seguir el asistente
   - Repetir con `inventario_fisico.csv`

4. Verificar que los datos quedaron cargados:
   ```sql
   USE BI_Staging;
   SELECT COUNT(*) FROM STG_MetasExternas;
   SELECT COUNT(*) FROM STG_InventarioFisico;
   ```

---

## SEBASTIAN DURAN — Persona 2

### 2.1 Crear la Base de Datos de Staging

1. Abrir SSMS. Conectarse al RDS:
   - Server name: `[ENDPOINT_RDS],1433`
   - Authentication: SQL Server Authentication
   - Login: `retail_admin`
   - Password: `[contrasena de Persona 1]`

2. Abrir una nueva ventana de query. Pegar el contenido de `02_staging/01_create_staging.sql` y ejecutar.

3. Verificar que la base de datos `BI_Staging` fue creada y que contiene las tablas:
   ```sql
   USE BI_Staging;
   SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES ORDER BY TABLE_NAME;
   ```
   Deben aparecer: QA_Reporte, STG_Clientes, STG_Compras, STG_DetalleVentas, STG_Devoluciones, STG_Inventario, STG_InventarioFisico, STG_Metas, STG_MetasExternas, STG_Productos, STG_Ventas.

---

### 2.2 Cargar Datos del OLTP al Staging

1. Ejecutar el archivo `02_staging/02_load_staging.sql`. Este script hace TRUNCATE de todas las tablas de staging y copia los datos de RetailOLTP a BI_Staging con INSERT INTO ... SELECT.

   > **Nota:** La parte de BULK INSERT de los CSV externos ya fue ejecutada por Persona 1 en el paso 1.5. Los datos de los CSV ya deben estar en `STG_MetasExternas` y `STG_InventarioFisico`.

2. Verificar los conteos post-carga:
   ```sql
   USE BI_Staging;
   SELECT 'STG_Ventas'          AS Tabla, COUNT(*) AS Total FROM STG_Ventas
   UNION ALL SELECT 'STG_DetalleVentas', COUNT(*) FROM STG_DetalleVentas
   UNION ALL SELECT 'STG_Clientes',      COUNT(*) FROM STG_Clientes
   UNION ALL SELECT 'STG_Productos',     COUNT(*) FROM STG_Productos
   UNION ALL SELECT 'STG_Inventario',    COUNT(*) FROM STG_Inventario
   UNION ALL SELECT 'STG_Metas',         COUNT(*) FROM STG_Metas
   UNION ALL SELECT 'STG_MetasExternas', COUNT(*) FROM STG_MetasExternas;
   ```
   Los conteos deben coincidir con los del OLTP.

---

### 2.3 Aplicar Transformaciones y Validaciones de Calidad

1. Ejecutar `02_staging/03_quality_checks.sql`. Este script aplica limpieza de nulos, estandarizacion de ciudades y departamentos, normalizacion de nombres de categorias, deteccion de duplicados, validacion de fechas y verificacion de integridad referencial.

2. Revisar el reporte de calidad:
   ```sql
   USE BI_Staging;
   SELECT * FROM QA_Reporte ORDER BY FechaEjecucion DESC;
   ```

3. Revisar registros con problemas:
   ```sql
   SELECT * FROM STG_Ventas   WHERE FlagCalidad IN ('RECHAZADO','SOSPECHOSO');
   SELECT * FROM STG_Clientes WHERE ObsCalidad IS NOT NULL;
   ```

4. Documentar en `07_docs/` los hallazgos: total de registros procesados por tabla, porcentaje con problemas, tipos de problemas encontrados y acciones tomadas.

---

### 2.4 Crear la Estructura del Data Warehouse

1. Ejecutar los scripts en este orden exacto:
   - `03_datawarehouse/01_create_dw_database.sql` (crea RetailDW)
   - `03_datawarehouse/02_create_dimensions.sql` (crea las 9 dimensiones)
   - `03_datawarehouse/03_create_facts.sql` (crea las 4 tablas de hechos)
   - `03_datawarehouse/04_etl_log.sql` (crea ETL_Log y stored procedures helper)

2. Verificar la estructura:
   ```sql
   USE RetailDW;
   SELECT TABLE_NAME
   FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_NAME LIKE 'Dim%' OR TABLE_NAME LIKE 'Fact%' OR TABLE_NAME = 'ETL_Log'
   ORDER BY TABLE_NAME;
   ```
   Deben aparecer: DimCanalVenta, DimCliente, DimFecha, DimGeografia, DimProducto, DimPromocion, DimProveedor, DimTienda, DimVendedor, ETL_Log, FactDevoluciones, FactInventarioDiario, FactMetasComerciales, FactVentas.

---

### 2.5 Cargar Dimensiones al Data Warehouse

1. Ejecutar los archivos de ETL de dimensiones en orden:
   - `04_etl/01_CargarDimFecha.sql`
   - `04_etl/02_CargarDimensiones.sql` (crea y ejecuta los stored procedures para las demas dimensiones)

2. Verificar conteos post-carga:
   ```sql
   USE RetailDW;
   SELECT 'DimFecha'      AS Dimension, COUNT(*) AS Registros FROM DimFecha
   UNION ALL SELECT 'DimCliente',    COUNT(*) FROM DimCliente
   UNION ALL SELECT 'DimProducto',   COUNT(*) FROM DimProducto
   UNION ALL SELECT 'DimTienda',     COUNT(*) FROM DimTienda
   UNION ALL SELECT 'DimVendedor',   COUNT(*) FROM DimVendedor
   UNION ALL SELECT 'DimProveedor',  COUNT(*) FROM DimProveedor
   UNION ALL SELECT 'DimCanalVenta', COUNT(*) FROM DimCanalVenta
   UNION ALL SELECT 'DimPromocion',  COUNT(*) FROM DimPromocion
   UNION ALL SELECT 'DimGeografia',  COUNT(*) FROM DimGeografia;
   ```
   Esperado: DimFecha 1095+ filas, DimCliente aprox 1000, DimProducto 200, DimTienda 10, DimVendedor 20.

3. Revisar el ETL_Log:
   ```sql
   USE RetailDW;
   SELECT NombreProceso, Estado, RegistrosCargados, MensajeError
   FROM ETL_Log
   ORDER BY FechaInicio DESC;
   ```
   Todos los procesos deben tener Estado = COMPLETADO.

4. Enviar confirmacion a Juan Simon Ospina (Persona 3) indicando que las dimensiones estan cargadas.

---

## JUAN SIMON OSPINA — Persona 3

### 3.1 Cargar Tablas de Hechos

1. Verificar que las dimensiones tienen datos antes de comenzar:
   ```sql
   USE RetailDW;
   SELECT COUNT(*) FROM DimCliente;
   SELECT COUNT(*) FROM DimProducto;
   SELECT COUNT(*) FROM DimFecha;
   ```
   Todos deben retornar un valor mayor a cero.

2. Ejecutar los archivos ETL de hechos en este orden:
   - `04_etl/10_CargarFactVentas.sql` (resuelve 7 surrogate keys, carga aprox 150K registros)
   - `04_etl/11_CargarFactInventario.sql` (carga inventario diario)
   - `04_etl/12_CargarFactMetas.sql` (combina metas del OLTP y del CSV externo)
   - `04_etl/13_CargarFactDevoluciones.sql` (carga devoluciones)

3. Verificar conteos:
   ```sql
   USE RetailDW;
   SELECT 'FactVentas'             AS Tabla, COUNT(*) AS Total FROM FactVentas
   UNION ALL SELECT 'FactInventarioDiario',  COUNT(*) FROM FactInventarioDiario
   UNION ALL SELECT 'FactMetasComerciales',  COUNT(*) FROM FactMetasComerciales
   UNION ALL SELECT 'FactDevoluciones',      COUNT(*) FROM FactDevoluciones;
   ```
   Esperado: FactVentas aprox 150.000, FactInventarioDiario aprox 109.500, FactMetasComerciales aprox 960.

4. Verificar surrogate keys sin resolver (deben ser 0):
   ```sql
   USE RetailDW;
   SELECT 'Sin Cliente'  AS Problema, COUNT(*) FROM FactVentas WHERE ClienteKey  = -1
   UNION ALL SELECT 'Sin Producto',  COUNT(*) FROM FactVentas WHERE ProductoKey = -1
   UNION ALL SELECT 'Sin Tienda',    COUNT(*) FROM FactVentas WHERE TiendaKey   = -1
   UNION ALL SELECT 'Sin Fecha',     COUNT(*) FROM FactVentas WHERE FechaKey    = -1;
   ```

---

### 3.2 Verificar y Analizar el ETL_Log

1. Consultar el log completo del ETL:
   ```sql
   USE RetailDW;
   SELECT
       NombreProceso,
       FechaInicio,
       FechaFin,
       DATEDIFF(SECOND, FechaInicio, FechaFin) AS DuracionSegundos,
       Estado,
       RegistrosLeidos,
       RegistrosCargados,
       RegistrosRechazados,
       CAST(RegistrosCargados * 100.0 / NULLIF(RegistrosLeidos,0) AS DECIMAL(5,2)) AS TasaExitoPct,
       MensajeError
   FROM ETL_Log
   ORDER BY FechaInicio;
   ```

2. Si hay procesos con Estado = ERROR, leer el campo MensajeError para identificar la causa. Causas comunes: claves huerfanas, violaciones de tipo de dato, nulos en campos NOT NULL. Corregir en el script ETL correspondiente y re-ejecutar solo ese proceso.

3. Documentar en `07_docs/` los resultados: tabla con resultados del ETL_Log, total de registros rechazados y motivos, tiempo total del pipeline.

---

### 3.3 Ejecutar el Orquestador Maestro ETL (Prueba End-to-End)

1. Limpiar el DW para una prueba limpia desde cero:
   ```sql
   USE RetailDW;
   TRUNCATE TABLE FactVentas;
   TRUNCATE TABLE FactInventarioDiario;
   TRUNCATE TABLE FactMetasComerciales;
   TRUNCATE TABLE FactDevoluciones;
   DELETE FROM DimCliente;    DBCC CHECKIDENT ('DimCliente',    RESEED, 0);
   DELETE FROM DimProducto;   DBCC CHECKIDENT ('DimProducto',   RESEED, 0);
   DELETE FROM DimTienda;     DBCC CHECKIDENT ('DimTienda',     RESEED, 0);
   DELETE FROM DimVendedor;   DBCC CHECKIDENT ('DimVendedor',   RESEED, 0);
   DELETE FROM DimProveedor;  DBCC CHECKIDENT ('DimProveedor',  RESEED, 0);
   DELETE FROM DimCanalVenta; DBCC CHECKIDENT ('DimCanalVenta', RESEED, 0);
   DELETE FROM DimPromocion;  DBCC CHECKIDENT ('DimPromocion',  RESEED, 0);
   DELETE FROM DimGeografia;  DBCC CHECKIDENT ('DimGeografia',  RESEED, 0);
   DELETE FROM DimFecha;
   DELETE FROM ETL_Log;
   ```

2. Ejecutar el orquestador maestro:
   ```sql
   USE RetailDW;
   EXEC ETL_Master;
   ```
   Esperar entre 10 y 25 minutos hasta que finalice.

3. Verificar el resumen del log al finalizar:
   ```sql
   SELECT NombreProceso, Estado, RegistrosCargados,
          DATEDIFF(SECOND, FechaInicio, FechaFin) AS Seg
   FROM ETL_Log ORDER BY FechaInicio;
   ```

4. Comparar totales OLTP vs DW:
   ```sql
   SELECT
       (SELECT COUNT(*)   FROM RetailOLTP.dbo.DetalleVentas) AS LineasOLTP,
       (SELECT COUNT(*)   FROM RetailDW.dbo.FactVentas)      AS LineasDW,
       (SELECT SUM(TotalLinea) FROM RetailOLTP.dbo.DetalleVentas) AS MontoOLTP,
       (SELECT SUM(ValorVenta) FROM RetailDW.dbo.FactVentas)      AS MontoDW;
   ```
   Los valores deben ser iguales o con diferencia menor al porcentaje de registros rechazados.

---

### 3.4 Ejecutar Validaciones de Calidad del DW

1. Ejecutar `04_etl/14_ValidarCalidadDatos.sql`. El script genera un reporte de: NULLs en columnas de hechos, valores negativos incorrectos, claves foraneas sin match en dimensiones, fechas fuera de rango, y comparacion de totales OLTP vs DW.

2. Para cada resultado, tomar una captura de pantalla de SSMS y guardarla como evidencia.

3. Notificar a Daniel Arcila (Persona 4) que el Data Warehouse esta completo y validado. Compartir: endpoint RDS, nombre de la base `RetailDW`, usuario `retail_admin` y contrasena.

---

### 3.5 Consultas Analiticas de Prueba del DW

1. Ventas por tienda y mes:
   ```sql
   USE RetailDW;
   SELECT
       t.NombreTienda, f.Anio, f.NombreMes, f.MesNum,
       SUM(fv.ValorVenta) AS TotalVentas,
       SUM(fv.CostoTotal) AS TotalCosto,
       SUM(fv.ValorVenta - fv.CostoTotal) AS MargenBruto
   FROM FactVentas fv
   JOIN DimTienda t ON fv.TiendaKey = t.TiendaKey
   JOIN DimFecha  f ON fv.FechaKey  = f.FechaKey
   GROUP BY t.NombreTienda, f.Anio, f.NombreMes, f.MesNum
   ORDER BY t.NombreTienda, f.Anio, f.MesNum;
   ```

2. Top 10 productos por margen:
   ```sql
   USE RetailDW;
   SELECT TOP 10
       p.NombreProducto, p.Categoria,
       SUM(fv.ValorVenta) AS Ventas,
       SUM(fv.CostoTotal) AS Costo,
       CAST(SUM(fv.ValorVenta - fv.CostoTotal) * 100.0
            / NULLIF(SUM(fv.ValorVenta),0) AS DECIMAL(5,2)) AS MargenPct
   FROM FactVentas fv
   JOIN DimProducto p ON fv.ProductoKey = p.ProductoKey
   GROUP BY p.NombreProducto, p.Categoria
   ORDER BY MargenPct DESC;
   ```

3. Guardar los resultados para el informe tecnico.

---

## DANIEL ARCILA — Persona 4

### 4.1 Conectar Power BI Desktop al Data Warehouse en RDS

1. Descargar Power BI Desktop desde https://powerbi.microsoft.com/desktop/ e instalarlo.

2. Abrir Power BI Desktop. Ir a **Get Data** → **SQL Server**. Completar la conexion:
   - Server: `[ENDPOINT_RDS],1433`
   - Database: `RetailDW`
   - Data Connectivity mode: **Import** (no DirectQuery)
   - Clic en OK e ingresar credenciales de `retail_admin`

   > **Ventaja de RDS publico:** No se necesita Power BI Gateway para publicar en Power BI Service, ya que el endpoint de RDS es publico y accesible desde internet.

3. En el Navigator, seleccionar todas las tablas del DW: DimFecha, DimGeografia, DimCliente, DimProducto, DimTienda, DimVendedor, DimProveedor, DimCanalVenta, DimPromocion, FactVentas, FactInventarioDiario, FactMetasComerciales, FactDevoluciones. Clic en Load.

4. Ir a la vista Model (icono de grafo en la barra lateral). Verificar que existen relaciones entre cada tabla de hechos y sus dimensiones. Si faltan, crearlas manualmente arrastrando el campo de una tabla a otra (por ejemplo: FactVentas[FechaKey] hacia DimFecha[FechaKey]).

5. Configurar DimFecha como Date Table: seleccionar la tabla DimFecha, ir a la pestana Table Tools y hacer clic en **Mark as date table**. Seleccionar la columna Fecha.

6. Guardar el archivo como `06_powerbi/RetailBI.pbix`.

---

### 4.2 Crear las Medidas DAX (minimo 15)

1. Crear tabla de medidas: ir a Modeling, clic en New Table, escribir: `_Medidas = ROW("x", 1)`. Esto crea una tabla vacia para organizar todas las medidas.

2. Para cada medida, hacer clic derecho sobre `_Medidas`, seleccionar **New measure**, y escribir el codigo DAX. Las medidas completas con su codigo se encuentran en el archivo `06_powerbi/medidas_dax.md`.

3. Crear en este orden:
   - Medidas base: Total Ventas, Total Costo, Utilidad Bruta, Margen Bruto %, Cantidad Vendida, Ticket Promedio
   - Medidas de tiempo: Ventas Anio Anterior, Crecimiento Ventas %, Ventas YTD, Promedio Movil 3M
   - Medidas de metas: Total Meta, Cumplimiento Meta %, Brecha Meta
   - Medidas de inventario: Inventario Promedio, Rotacion Inventario
   - Medidas de ranking: Ranking Producto Ventas, Ranking Tienda Ventas, Participacion Ventas %

4. Para verificar cada medida, arrastrarla a una visual de tipo Card y confirmar que muestra un valor razonable (no BLANK ni error).

---

### 4.3 Construir las 6 Paginas del Dashboard

1. Para cada nueva pagina, hacer clic derecho en la barra de paginas (abajo) y seleccionar New page.

2. **Pagina 1 - Dashboard Ejecutivo:** agregar 4 tarjetas KPI (Total Ventas, Utilidad Bruta, Margen Bruto %, Cumplimiento Meta %), un grafico de lineas con ventas mensuales del anio actual vs anio anterior, un grafico de barras horizontales con top 5 tiendas, otro con top 5 productos, un Gauge de cumplimiento de meta global, y slicers de Anio y Region.

3. **Pagina 2 - Analisis de Ventas:** agregar grafico de area con tendencia mensual, grafico de barras apiladas por categoria y tienda, tabla de vendedores con ranking, grafico de dona por canal, y slicers de Periodo, Tienda, Categoria, Canal.

4. **Pagina 3 - Inventario:** agregar 3 tarjetas (Inventario Promedio, Rotacion Inventario, Stock total), grafico de barras con top 10 productos de menor stock, grafico de lineas con evolucion semanal del inventario, matriz Tienda x Producto, y slicers de Tienda, Categoria y rango de fechas.

5. **Pagina 4 - Rentabilidad:** agregar grafico de barras agrupadas Ingresos vs Costos por categoria, scatter plot Margen % vs Volumen por producto, tabla de rentabilidad por tienda, treemap de participacion por categoria, y slicers de Periodo, Categoria, Tienda.

6. **Pagina 5 - Cumplimiento de Metas:** agregar grafico de barras de ventas reales vs meta por mes, una matrix con tiendas en filas, meses en columnas y Cumplimiento Meta % como valor (aplicar formato condicional), tabla con brecha por tienda, y slicers de Anio, Tienda, Categoria.

7. **Pagina 6 - Exploracion OLAP:** agregar una matrix con drill-down Anio > Trimestre > Mes, un grafico con drill-through hacia la pagina de ventas, y slicers de Canal y Vendedor.

8. Aplicar tema visual consistente en todas las paginas (View > Themes). Colores sugeridos: azul oscuro `#1B4F8A` como color primario, verde `#27AE60` como color secundario.

---

### 4.4 Publicar en Power BI Service (Azure)

1. Ir a https://app.powerbi.com e iniciar sesion con la cuenta universitaria EAFIT. Si no se tiene licencia Pro, activar el trial gratuito de 60 dias desde el menu de cuenta.

2. En Power BI Desktop, ir a **Home** → clic en **Publish**. Seleccionar o crear el workspace `Proyecto3-RetailBI`. Esperar a que la publicacion finalice.

3. En Power BI Service, ir al workspace → **Datasets** → tres puntos junto a `RetailDW` → **Settings** → **Data source credentials** → Edit credentials:
   - Authentication method: Basic
   - User name: `retail_admin`
   - Password: `[contrasena]`
   - Privacy level: Organizational
   - Clic en **Sign in**

   > Como el RDS tiene endpoint publico, Power BI Service se conecta directamente sin necesidad de instalar un Gateway local.

4. Para obtener una URL publica del reporte: abrir el reporte publicado → **File** → **Embed report** → **Publish to web (public)**. Copiar la URL generada.

5. Para compartir con el profesor: abrir el reporte → clic en **Share** → ingresar el correo del profesor → enviar.

6. Registrar la URL publica en el README.md del proyecto.

---

### 4.5 Informe Tecnico y Video de Demostracion

1. Redactar el informe tecnico en Word o Google Docs con las siguientes secciones:
   - Portada: nombres, codigo del curso, fecha, universidad
   - Introduccion: caso de negocio y objetivos
   - Arquitectura: diagrama general del pipeline BI (SQL Server en AWS RDS + Power BI en Azure)
   - Modelo OLTP: diagrama ER y justificacion de normalizacion 3FN
   - Modelo Dimensional: diagrama del DW, justificacion de granularidad, tabla de medidas aditivas vs semi-aditivas
   - Staging y ETL: transformaciones aplicadas y hallazgos de calidad de datos
   - Power BI: modelo semantico, medidas DAX destacadas y capturas del dashboard
   - Resultados e Insights: minimo 3 conclusiones del analisis de datos
   - Etica y Uso de IA: especificar que partes se hicieron con IA, porcentaje estimado y que entendimiento se adquirio (seccion obligatoria del enunciado)
   - Conclusiones y Retos: dificultades encontradas (incluir la problematica con Azure VM y la decision de usar AWS RDS) y como se resolvieron

2. Exportar el informe a PDF.

3. Grabar el video de demostracion (entre 10 y 15 minutos) con la siguiente estructura:
   - 0:00-2:00: Mostrar la instancia RDS en AWS Console (estado Available, endpoint, security group)
   - 2:00-4:00: Mostrar el OLTP con datos en SSMS conectado al endpoint RDS (tablas y conteos)
   - 4:00-6:00: Mostrar el proceso ETL y la tabla ETL_Log en SSMS
   - 6:00-12:00: Navegar por las 6 paginas del dashboard en Power BI Service (app.powerbi.com)
   - 12:00-15:00: Explicar decisiones de diseno y retos encontrados

4. Subir el video a YouTube (opcion no listado) o Microsoft Stream y obtener el enlace.

5. Preparar respuestas para la sustentacion oral. Preguntas probables:
   - Cual es la granularidad de FactVentas y por que se eligio por linea de venta?
   - Por que el inventario no debe sumarse a traves del tiempo?
   - Que medidas son semi-aditivas y como se tratan en DAX?
   - Explica la diferencia entre el modelo OLTP y el modelo OLAP construido
   - Que dimensiones podrian implementar SCD tipo 2 y como se haria?
   - Explica la medida Crecimiento Ventas % paso a paso
   - Que es context transition en DAX y donde aparece en el modelo?

---

*Universidad EAFIT — Ingenieria de Sistemas — 2026-1*
