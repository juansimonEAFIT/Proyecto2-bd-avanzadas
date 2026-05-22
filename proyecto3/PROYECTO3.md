```
Proyecto 3
```
**Título: BI para análisis integral de ventas, inventario y rentabilidad**

**1. Descripción del caso de negocio**
Una empresa minorista con varias sedes en Colombia desea construir una solución
completa de Business Intelligence para analizar su operación comercial.
Actualmente tiene datos transaccionales en una base de datos relacional (OLTP),
archivos planos históricos y hojas Excel usadas por las sedes para registrar
información complementaria.

La gerencia quiere tomar decisiones sobre:

ventas, rentabilidad, inventario, desempeño de productos, comportamiento de
clientes, cumplimiento de metas comerciales y desempeño regional.

El proyecto debe implementarse en:

```
SQL Server + Power BI en Nube Azure
Los alumnos crearan una VM con SQL Server Free como la experiencia
realizada en el laboratorio de clase, al final del proyecto y como parte de la
documentación el grupo entregará al profesor la dir ip, usuario y clave para
ingresar al servidor. El tablero de PowerBI debe ser publicado en la nube de
powerbi y entregar la URL al profesor.
```
**2. Objetivo general**

Diseñar, implementar y documentar una solución BI completa que incluya:

1. Base de datos operacional OLTP en SQL Server.
2. Zona staging para integración de datos. Validaciones de calidad de datos.
3. Base de datos Data Warehouse dimensional.
4. Procesos ETL en T-SQL.
5. Modelo semántico en Power BI.
6. Dashboard ejecutivo, analítico y operativo.
7. Análisis avanzado con medidas DAX.


```
Proyecto 3
```
**3. Modelo de datos**

Los estudiantes deberán construir y ampliar una base operacional con mínimo las
siguientes entidades:

**Módulo comercial OLTP**

Tablas mínimas:

- Clientes
- Productos
- Categorías
- Proveedores
- Tiendas o sedes
- Vendedores
- Ventas
- DetalleVentas
- InventarioDiario
- Compras
- DetalleCompras
- Devoluciones
- MetasComerciales

Además, deberán integrar al menos **dos fuentes externas** :

1. Archivo CSV o Excel de metas mensuales por tienda/categoría.
2. Archivo CSV o Excel de inventario físico o ajustes manuales.

Pueden agregar:

- campañas comerciales,
- descuentos,
- canal de venta,
- segmentación de clientes,
- costos logísticos,
- presupuesto mensual.

A cada una de estas entidades, deberán definir los atributos típicos en estos
sistemas.


```
Proyecto 3
```
**4. Requisitos técnicos**

**4.1 Base de datos OLTP**

Debe estar normalizada hasta 3FN.

Debe incluir:

- claves primarias,
- claves foráneas,
- restricciones CHECK,
- restricciones NOT NULL,
- datos suficientes para análisis. Debera generar aleatoriamente y mediante
    scripts sql gran cantidad de datos
Volumen mínimo sugerido:
- 1.000 clientes
- 200 productos
- 10 tiendas
- 20 vendedores
- 50.000 ventas
- 150.000 líneas de venta
- 365 días de inventario
- 12 meses de metas
Los datos pueden ser sintéticos, pero deben ser realistas.

**4.2 base de datos de Staging**

Crear una base o esquema llamado, por ejemplo:

BI_Staging

Debe contener tablas temporales o intermedias para:

- ventas
- productos
- clientes
- inventario
- metas
- devoluciones
- compras


```
Proyecto 3
```
En staging se deben aplicar transformaciones como:

- limpieza de nulos,
- estandarización de ciudades/regiones,
- normalización de nombres de categorías,
- conversión de fechas,
- detección de duplicados,
- cálculo de campos derivados,
- validación de códigos inexistentes.

Nota: la gestión de datos en staging no se evidenció en la lab de clase, ya que el ETL
directamente extraía datos del OLTP y los insertaba al DW con mínimas
transformaciones. La BD de staging es utilizada como punto intermedio para realizar
la T del ELT.

**4.3 Data Warehouse**

Diseñar un modelo dimensional en estrella o copo de nieve. Debe tener mínimo:

**Dimensiones**

- DimFecha
- DimCliente
- DimProducto
- DimTienda
- DimVendedor
- DimProveedor
- DimCanalVenta
- DimPromocion o DimCampaña
- DimGeografia
**Hechos**

Mínimo estas tablas de hechos:

1. FactVentas
    o granularidad: una línea de venta por producto, cliente, tienda, vendedor
       y fecha.
2. FactInventarioDiario
    o granularidad: inventario diario por producto y tienda.
3. FactMetasComerciales
    o granularidad: meta mensual por tienda, categoría y vendedor o canal.


```
Proyecto 3
```
De alta valoración:

4. FactDevoluciones, granularidad?
5. FactCompras, granularidad?
6. FactRentabilidad, granularidad?
**5. Justificación al modelo dimensional**

Deben explicar en el informe:

1. ¿Cuál es la granularidad de cada tabla de hechos?
2. ¿Qué medidas son aditivas, semi-aditivas y no aditivas?
3. ¿Qué problemas de resumibilidad aparecen?
4. ¿Por qué inventario no debe sumarse directamente a través del tiempo?
5. ¿Qué dimensiones tienen jerarquías?
6. ¿Qué dimensiones podrían manejar Slowly Changing Dimensions tipo 2?
7. ¿Qué diferencia hay entre la base OLTP y el modelo OLAP construido?
Esto permite al estudiante, ser consciente del alcance e impacto de un modelo
dimensional enmarcado en las diferentes decisiones que se toman a lo largo del
proceso.
**6. ETL en SQL Server**

Los ETL debe ser implementados en T-SQL mediante scripts o procedimientos
almacenados.

Debe incluir:

CargarDimFecha
CargarDimCliente
CargarDimProducto
CargarFactVentas
CargarFactInventario
CargarFactMetas
ValidarCalidadDatos

Cada proceso debe:

- truncar o actualizar staging,
- cargar dimensiones,
- resolver claves sustitutas,


```
Proyecto 3
```
- cargar hechos,
- registrar errores,
- generar bitácora de ejecución.
Debe existir una tabla:

ETL_Log

con:

- nombre del proceso,
- fecha de inicio,
- fecha fin,
- estado,
- número de registros leídos,
- número de registros cargados,
- número de registros rechazados,
- mensaje de error.
**7. Visualización - Power BI**

El modelo en Power BI debe conectarse al Data Warehouse en SQL Server.

Debe incluir:

**Páginas del dashboard**

1. **Dashboard ejecutivo** (KPI)
    o ventas totales,
    o utilidad,
    o margen,
    o cumplimiento de metas,
    o variación mensual,
    o top tiendas,
    o top productos.
2. **Análisis de ventas**
    o ventas por fecha,
    o categoría,
    o tienda,
    o vendedor,
    o cliente,
    o canal.


```
Proyecto 3
```
3. **Inventario**
    o stock actual,
    o rotación,
    o productos con bajo inventario,
    o inventario promedio,
    o días de inventario disponible.
4. **Rentabilidad**
    o ingresos,
    o costos,
    o margen bruto,
    o margen por producto,
    o margen por tienda.
5. **Cumplimiento de metas**
    o ventas reales vs meta,
    o porcentaje de cumplimiento,
    o brecha frente a meta,
    o semáforo de desempeño.
6. **Página de exploración OLAP**
    o drill-down por año, trimestre, mes y día,
    o slice por región,
    o dice por categoría y canal,
    o roll-up por tienda o región.
**8. Medidas DAX mínimas**

Deben crear mínimo 15 medidas DAX, incluyendo:

Total Ventas = SUM(FactVentas[ValorVenta])

Total Costo = SUM(FactVentas[CostoTotal])

Utilidad Bruta = [Total Ventas] - [Total Costo]

Margen Bruto % = DIVIDE([Utilidad Bruta], [Total Ventas])

Ventas Año Anterior =
CALCULATE([Total Ventas], SAMEPERIODLASTYEAR(DimFecha[Fecha]))


```
Proyecto 3
```
Crecimiento Ventas % =
DIVIDE([Total Ventas] - [Ventas Año Anterior], [Ventas Año Anterior])

Cumplimiento Meta % =
DIVIDE([Total Ventas], SUM(FactMetasComerciales[ValorMeta]))

Brecha Meta =
[Total Ventas] - SUM(FactMetasComerciales[ValorMeta])

También deben incluir:

- ranking de productos,
- ranking de tiendas,
- promedio móvil de ventas,
- participación porcentual,
- ticket promedio,
- inventario promedio,
- rotación de inventario.
**9. Entregables**

Cada equipo debe entregar:

1. Servidor con SQL server y Power BI desplegado en Azure
2. Tablero PowerBI publicado en la nube pública de PowerBI
3. Archivos fuente en github:
    1. Script SQL completo de creación OLTP.
    2. Script SQL completo de creación del Data Warehouse.
    3. Scripts ETL o procedimientos almacenados.
    4. Archivos CSV/Excel usados como fuentes externas.
    5. Archivo .pbix de Power BI.
    6. Diccionario de datos.
    7. Diagrama del modelo dimensional.
    8. Evidencias de validación de datos.
    9. Otros que considere o genere.
4. Informe técnico en PDF. (DEBE CONTENER UNA SECCIÓN EXPLICITA SOBRE
    ETICA y USO DE IA EN EL PROYECTO, debe especificar que partes realizaron
    con IA, que porcentaje del proyecto fue realizado por IA, ver numeral 12 abajo)
5. Video corto de demostración, entre 10 y 15 mins. Explicando los retos de
    diseño. Implementación y Demostrativo de los productos finales (SQL Server y
    Tableros PowerBI)


```
Proyecto 3
```
**10. Criterios de evaluación**
    **Criterio Peso**

```
Diseño OLTP correcto y realista 10%
```
```
Diseño dimensional: hechos, dimensiones, granularidad 20%
```
```
ETL en SQL Server con staging, limpieza y logs 20%
```
```
Calidad del modelo Power BI 15%
```
```
Medidas DAX y análisis avanzado 15%
```
```
Dashboard, storytelling y visualización 10%
```
```
Informe técnico y justificación conceptual 10%
```
**11. Nivel de dificultad**

Este proyecto no debe limitarse a ser un tema operativo y de uso intensivo de chatgpt
o similar, debe sustentar las decisiones de arquitectura BI, modelado dimensional,
integración de fuentes, preparación de datos, ETL, manejo de DAX no triviales y análisis
gerencial.
Aunque los estudiantes usen ChatGPT como apoyo, deberán justificar el diseño,
defender la granularidad, explicar problemas de agregación y demostrar que el modelo
responde preguntas reales de negocio.


```
Proyecto 3
```
**12. USO DE IA**

Este proyecto puede ser apoyado con IA, siempre y cuando los estudiantes obtengan
el conocimiento entregado por la IA y pueda ser utilizado para realizar proyectos de
mayor complejidad.

Dentro de los aspectos que puede ser apoyado por IA está:

**A. Generación de scripts SQL**
Muy fácilmente apoyado por IA
ejemplo:

- creación de tablas
- claves foráneas
- dimensiones
- hechos
- procedimientos ETL
- inserts sintéticos
- consultas SQL
- medidas DAX básicas

**B. Diseño inicial del modelo estrella**
puede hacerlo razonablemente bien.
ejemplo:

- identificar dimensiones
- proponer hechos
- crear un star schema
- generar surrogate keys
- crear DimFecha

**C. Dashboard básico Power BI**
ayuda mucho en:

- sugerir visualizaciones,
- medidas DAX,
- KPIs,
- filtros,
- drill-down,
- segmentadores.


```
Proyecto 3
```
**D. Generación de datos sintéticos**

- scripts SQL
- scripts Python
- datos CSVs.

Que aspecto debería ser más parte del estudiante con menos apoyo de IA

**A. Definir correctamente la granularidad de las dimensiones**

Ejemplos:

- ¿FactVentas debe ser por factura o por línea?
- ¿Inventario diario o mensual?
- ¿Meta por vendedor o por tienda?
- ¿Qué pasa si mezclan granularidades?

ChatGPT puede sugerir algo, pero los estudiantes deben entender:

- explosión de cardinalidad,
- duplicación,
- agregaciones incorrectas,
- problemas de resumibilidad.

**B. Resolver problemas reales operativos de ETL**

La IA genera ETLs “ideales”, pero en proyectos puede aparecer:

- claves faltantes
- datos inconsistentes
- duplicados
- nulos
- formatos diferentes
- errores de carga
- claves huérfanas
- tipos incompatibles


```
Proyecto 3
```
**C. Construir un modelo BI coherente**

**D. DAX avanzado**

Ejemplos:

- context transition
- FILTER complejos
- ALL vs ALLEXCEPT
- SAMEPERIODLASTYEAR
- USERELATIONSHIP
- medidas semi-aditivas
- acumulados
- inventario promedio
- time intelligence real

**E. Calidad visual y storytelling**

**F. Integración completa end-to-end**

Que	por	ahora	no	puede	hacer	la	IA y	en	cabeza	de	los	estudiantes:

**A.	Creación	real	del	ambiente	de	la	VM	en	Azure	+	instalación	de	powerBI
B.	Ejecución	de	los	scripts dentro	del	OLTP,	ETL y	DW
C.	Desarrollo	real	de	los	tableros
D.	Revisión	y	coherencia	Iinal	del	informe
E.	Entendimiento	completo	end-to-end	del	proyecto
F.	SUSTENTACIÓN	DEL	PROYECTO
G.	Manejo	de	situaciones	imprevistas,	nuevas	funcionalidades,	cambios, etc.
H.	Entendiemiento	a	profundidad	de	la	arquitectura	y	del	código	fuente**

**Código	de	ética	del	profesor:**

**Este	enunciado	fue	apoyado	por	IA,	sin	embargo	el	profesor	invirtió	más	de	 5	
horas en	preparación,	realizando	correctamente	este	enunciado.**


