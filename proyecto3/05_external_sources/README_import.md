# Fuentes Externas — Instrucciones de Importación

**Persona responsable:** Sebastian Duran (Persona 2)

---

## Archivos disponibles

| Archivo | Descripción | Filas aprox. | Importa a tabla |
|---------|-------------|-------------|-----------------|
| `metas_mensuales.csv` | Metas por tienda/categoría enviadas por gerencia | ~85 | `STG_MetasExternas` |
| `inventario_fisico.csv` | Conteo físico de inventario vs sistema | ~50 | `STG_InventarioFisico` |

---

## Estructura de los CSV

### `metas_mensuales.csv`
```
Anio, Mes, NombreTienda, NombreCategoria, ValorMeta
```
- `ValorMeta`: en pesos colombianos (COP), sin puntos ni comas

### `inventario_fisico.csv`
```
FechaConteo, CodigoSKU, NombreTienda, StockContado, StockSistema, Diferencia, Observacion
```
- `FechaConteo`: formato `YYYY-MM-DD`
- `Diferencia`: puede ser negativa (faltante) o positiva (sobrante)

---

## Pasos para copiar los archivos a la VM

1. Conectarse a la VM por RDP: `[IP_PUBLICA]:3389`

2. Crear la carpeta de destino si no existe:
   ```
   C:\RetailBI\ExternalData\
   ```

3. Copiar los archivos usando el portapapeles de RDP:
   - En el equipo local: copiar los archivos
   - En la VM: pegar en `C:\RetailBI\ExternalData\`

   **O** subir a OneDrive y descargar desde la VM.

4. Dar permisos de lectura a SQL Server:
   - Clic derecho en `C:\RetailBI\ExternalData\` → Properties → Security → Edit
   - Agregar: `NT SERVICE\MSSQLSERVER` → permisos de lectura

---

## Habilitar importación en SQL Server

Ejecutar **una sola vez** como sysadmin en SSMS:

```sql
-- Habilitar Ad Hoc Distributed Queries
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1; RECONFIGURE;
```

---

## Probar la importación manualmente

```sql
-- Probar lectura del CSV de metas
BULK INSERT BI_Staging.dbo.STG_MetasExternas
FROM 'C:\RetailBI\ExternalData\metas_mensuales.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);

SELECT TOP 5 * FROM BI_Staging.dbo.STG_MetasExternas;

-- Probar lectura del CSV de inventario físico
BULK INSERT BI_Staging.dbo.STG_InventarioFisico
FROM 'C:\RetailBI\ExternalData\inventario_fisico.csv'
WITH (
    FIRSTROW        = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '\n',
    CODEPAGE        = '65001',
    TABLOCK
);

SELECT TOP 5 * FROM BI_Staging.dbo.STG_InventarioFisico;
```

---

## Solución de problemas comunes

| Error | Causa probable | Solución |
|-------|---------------|----------|
| `Cannot bulk load because the file could not be opened` | SQL Server no tiene permisos sobre la carpeta | Agregar permisos a `NT SERVICE\MSSQLSERVER` |
| `Bulk load data conversion error` | Problema de encoding o separadores | Verificar que el CSV use `,` como separador y UTF-8 |
| `Unexpected end of file` | El archivo tiene `\r\n` (Windows) en vez de `\n` | Cambiar `ROWTERMINATOR` a `'\r\n'` |
| `String or binary data would be truncated` | Un campo excede el tamaño de la columna en staging | Revisar el CSV y ampliar el campo si es necesario |

---

*Proyecto 3 — Universidad EAFIT — 2026-1*
