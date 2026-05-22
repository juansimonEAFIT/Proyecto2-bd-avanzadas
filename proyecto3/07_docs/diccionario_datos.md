# Diccionario de Datos — RetailBI

**Proyecto 3 — Bases de Datos Avanzadas SI3009 (2026-1)**  
**Universidad EAFIT — Ingeniería de Sistemas**

---

## Base de Datos: `RetailOLTP`

### Tabla: `Ciudades`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| CiudadID | INT IDENTITY | NO | Clave primaria |
| NombreCiudad | VARCHAR(100) | NO | Nombre de la ciudad |
| Departamento | VARCHAR(100) | NO | Departamento de Colombia |
| Region | VARCHAR(50) | NO | Región geográfica (Andina, Caribe, Pacífica, etc.) |
| CodigoDane | VARCHAR(10) | SÍ | Código DANE del municipio |

---

### Tabla: `Categorias`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| CategoriaID | INT IDENTITY | NO | Clave primaria |
| NombreCategoria | VARCHAR(100) | NO | Nombre único de la categoría |
| Descripcion | VARCHAR(255) | SÍ | Descripción de la categoría |
| CategoriaParent | INT | SÍ | FK a sí misma (jerarquía de categorías) |
| Activo | BIT | NO | 1=Activo, 0=Inactivo |

---

### Tabla: `Proveedores`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| ProveedorID | INT IDENTITY | NO | Clave primaria |
| NombreProveedor | VARCHAR(150) | NO | Razón social |
| NIT | VARCHAR(20) | NO | NIT único del proveedor |
| Ciudad | VARCHAR(100) | NO | Ciudad de ubicación |
| Departamento | VARCHAR(100) | NO | Departamento |
| Telefono | VARCHAR(20) | SÍ | Teléfono de contacto |
| Email | VARCHAR(100) | SÍ | Correo de contacto |

---

### Tabla: `Productos`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| ProductoID | INT IDENTITY | NO | Clave primaria |
| CodigoSKU | VARCHAR(50) | NO | Código único del producto |
| NombreProducto | VARCHAR(200) | NO | Nombre del producto |
| CategoriaID | INT | NO | FK → Categorias |
| ProveedorID | INT | NO | FK → Proveedores |
| PrecioUnitario | DECIMAL(18,2) | NO | Precio de venta al público |
| CostoUnitario | DECIMAL(18,2) | NO | Costo de compra (siempre ≤ PrecioUnitario) |
| UnidadMedida | VARCHAR(20) | NO | UND, KG, PAR, etc. |
| StockMinimo | INT | NO | Stock mínimo para alerta de reposición |
| Activo | BIT | NO | 1=Activo |

---

### Tabla: `Clientes`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| ClienteID | INT IDENTITY | NO | Clave primaria |
| Documento | VARCHAR(20) | NO | Número de documento único |
| TipoDocumento | VARCHAR(10) | NO | CC, CE, NIT, TI, PAS |
| NombreCliente | VARCHAR(200) | NO | Nombre completo |
| Email | VARCHAR(100) | SÍ | Correo electrónico |
| Telefono | VARCHAR(20) | SÍ | Teléfono de contacto |
| CiudadID | INT | SÍ | FK → Ciudades |
| Segmento | VARCHAR(20) | NO | VIP, Premium, Regular, General |
| FechaNacimiento | DATE | SÍ | Fecha de nacimiento |
| FechaRegistro | DATETIME | NO | Fecha de registro en el sistema |

---

### Tabla: `Tiendas`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| TiendaID | INT IDENTITY | NO | Clave primaria |
| CodigoTienda | VARCHAR(20) | NO | Código único T001–T010 |
| NombreTienda | VARCHAR(100) | NO | Nombre descriptivo de la sede |
| CiudadID | INT | NO | FK → Ciudades |
| Direccion | VARCHAR(200) | NO | Dirección física |
| Telefono | VARCHAR(20) | SÍ | Teléfono de la tienda |
| AreaM2 | DECIMAL(10,2) | SÍ | Área en metros cuadrados |
| FechaApertura | DATE | NO | Fecha de apertura de la sede |

---

### Tabla: `Vendedores`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| VendedorID | INT IDENTITY | NO | Clave primaria |
| Documento | VARCHAR(20) | NO | Cédula única |
| NombreVendedor | VARCHAR(200) | NO | Nombre completo |
| TiendaID | INT | NO | FK → Tiendas (tienda asignada) |
| CanalID | INT | SÍ | FK → CanalVenta (canal preferido) |
| FechaIngreso | DATE | NO | Fecha de vinculación |
| Activo | BIT | NO | 1=Activo |

---

### Tabla: `Ventas` (cabecera de factura)
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| VentaID | INT IDENTITY | NO | Clave primaria |
| NumeroFactura | VARCHAR(50) | NO | Número único de factura |
| ClienteID | INT | NO | FK → Clientes |
| TiendaID | INT | NO | FK → Tiendas |
| VendedorID | INT | NO | FK → Vendedores |
| CanalID | INT | NO | FK → CanalVenta |
| CampanaID | INT | SÍ | FK → Campanas (NULL si no aplica) |
| FechaVenta | DATETIME | NO | Fecha y hora de la transacción |
| Subtotal | DECIMAL(18,2) | NO | Suma de líneas sin descuento |
| TotalDescuento | DECIMAL(18,2) | NO | Monto total de descuentos |
| TotalImpuesto | DECIMAL(18,2) | NO | IVA (19%) sobre el neto |
| TotalVenta | DECIMAL(18,2) | NO | Monto final cobrado al cliente |
| Estado | VARCHAR(20) | NO | Completada, Anulada, Pendiente |

---

### Tabla: `DetalleVentas` (líneas de factura)
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| DetalleID | INT IDENTITY | NO | Clave primaria |
| VentaID | INT | NO | FK → Ventas |
| ProductoID | INT | NO | FK → Productos |
| Cantidad | INT | NO | Unidades vendidas (> 0) |
| PrecioUnitario | DECIMAL(18,2) | NO | Precio en el momento de la venta |
| CostoUnitario | DECIMAL(18,2) | NO | Costo en el momento de la venta |
| DescuentoPct | DECIMAL(5,2) | NO | % de descuento aplicado (0–100) |
| TotalLinea | DECIMAL(18,2) | NO | Cant × Precio × (1 - Desc%) |

---

### Tabla: `InventarioDiario`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| InventarioID | INT IDENTITY | NO | Clave primaria |
| FechaInventario | DATE | NO | Fecha del snapshot |
| ProductoID | INT | NO | FK → Productos |
| TiendaID | INT | NO | FK → Tiendas |
| StockInicial | INT | NO | Stock al inicio del día |
| Entradas | INT | NO | Unidades recibidas en el día |
| Salidas | INT | NO | Unidades vendidas/transferidas |
| Ajustes | INT | NO | Ajustes manuales (puede ser negativo) |
| StockFinal | INT | NO | StockInicial + Entradas - Salidas + Ajustes |

> ⚠️ **StockFinal es SEMI-ADITIVA**: se puede sumar entre tiendas pero NO entre fechas.

---

### Tabla: `MetasComerciales`
| Campo | Tipo | Nullable | Descripción |
|-------|------|----------|-------------|
| MetaID | INT IDENTITY | NO | Clave primaria |
| Anio | INT | NO | Año de la meta (2020–2030) |
| Mes | INT | NO | Mes de la meta (1–12) |
| TiendaID | INT | NO | FK → Tiendas |
| CategoriaID | INT | SÍ | FK → Categorias (NULL = todas) |
| VendedorID | INT | SÍ | FK → Vendedores (NULL = todos) |
| CanalID | INT | SÍ | FK → CanalVenta (NULL = todos) |
| ValorMeta | DECIMAL(18,2) | NO | Meta en pesos COP |

---

---

## Base de Datos: `RetailDW`

### Tabla: `DimFecha`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| FechaKey | INT PK | Surrogate key = YYYYMMDD |
| Fecha | DATE | Fecha calendario |
| Anio | INT | Año (2023–2026) |
| Trimestre | INT | 1–4 |
| NombreTrimestre | VARCHAR(10) | "Q1", "Q2", "Q3", "Q4" |
| MesNum | INT | 1–12 |
| NombreMes | VARCHAR(20) | "Enero", "Febrero", etc. |
| Semana | INT | Semana ISO del año |
| DiaMes | INT | 1–31 |
| DiaSemanaNum | INT | 1=Domingo … 7=Sábado |
| NombreDia | VARCHAR(20) | "Lunes", "Martes", etc. |
| EsFinDeSemana | BIT | 1 si Sáb/Dom |
| EsFeriado | BIT | 1 si es feriado colombiano |
| NombreFeriado | VARCHAR(100) | Nombre del feriado |
| AnioMes | INT | YYYYMM (para agrupaciones) |
| AnioTrimestre | VARCHAR(10) | "2024-Q3" |

---

### Tabla: `FactVentas`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| FactVentaID | BIGINT PK | Surrogate key autoincremental |
| FechaKey | INT FK | → DimFecha |
| ClienteKey | INT FK | → DimCliente |
| ProductoKey | INT FK | → DimProducto |
| TiendaKey | INT FK | → DimTienda |
| VendedorKey | INT FK | → DimVendedor |
| CanalKey | INT FK | → DimCanalVenta |
| PromocionKey | INT FK | → DimPromocion |
| VentaID | INT | NK (trazabilidad al OLTP) |
| DetalleID | INT | NK (línea específica en OLTP) |
| NumeroFactura | VARCHAR(50) | Atributo degenerado |
| EstadoVenta | VARCHAR(20) | Completada / Anulada |
| FechaVenta | DATE | Fecha para drill-down rápido |
| **Cantidad** | INT | **ADITIVA** |
| **ValorBruto** | DECIMAL(18,2) | **ADITIVA** — Cant × Precio sin desc. |
| **Descuento** | DECIMAL(18,2) | **ADITIVA** — Monto descontado |
| **ValorVenta** | DECIMAL(18,2) | **ADITIVA** — Ingreso neto sin IVA |
| **CostoTotal** | DECIMAL(18,2) | **ADITIVA** — Cant × CostoUnitario |
| **MargenBruto** | DECIMAL(18,2) | **ADITIVA** — ValorVenta - CostoTotal |

---

### Tabla: `FactInventarioDiario`
| Campo | Tipo | Tipo de Medida | Descripción |
|-------|------|---------------|-------------|
| FechaKey | INT FK | — | → DimFecha |
| ProductoKey | INT FK | — | → DimProducto |
| TiendaKey | INT FK | — | → DimTienda |
| **StockInicial** | INT | **ADITIVA** | Sumar entre tiendas OK |
| **Entradas** | INT | **ADITIVA** | Sumar entre tiendas y tiempo OK |
| **Salidas** | INT | **ADITIVA** | Sumar entre tiendas y tiempo OK |
| **Ajustes** | INT | **ADITIVA** | Puede ser negativo |
| **StockFinal** | INT | **SEMI-ADITIVA** | ⚠️ NO sumar entre fechas |

---

### Tabla: `FactMetasComerciales`
| Campo | Tipo | Descripción |
|-------|------|-------------|
| TiendaKey | INT FK | → DimTienda |
| ProductoKey | INT FK | → DimProducto (como proxy de categoría) |
| VendedorKey | INT FK | → DimVendedor |
| CanalKey | INT FK | → DimCanalVenta |
| Anio | INT | Año de la meta |
| Mes | INT | Mes de la meta |
| **ValorMeta** | DECIMAL(18,2) | **ADITIVA** — Meta en COP |

---

*Proyecto 3 — Universidad EAFIT — 2026-1*
