# Descarga y procesamiento de datos climáticos de CONAGUA

Este script en **R** permite descargar, limpiar y exportar datos mensuales de **temperatura (máxima, mínima y media)** y **precipitación** publicados por la **Comisión Nacional del Agua (CONAGUA)** de México.

Los datos provienen de los *Resúmenes Mensuales de Lluvia y Temperatura*, disponibles en el sitio oficial del **Servicio Meteorológico Nacional (SMN)**:

[https://smn.conagua.gob.mx/es/climatologia/temperaturas-y-lluvias/resumenes-mensuales-de-temperaturas-y-lluvias](https://smn.conagua.gob.mx/es/climatologia/temperaturas-y-lluvias/resumenes-mensuales-de-temperaturas-y-lluvias)

---

## Funcionalidad principal

La función se puede escribir sin argumentos y descargará todos los datos disponibles:

```r
conagua.temp.precip()
```

### Descripción general

1. Descarga automáticamente los archivos PDF de CONAGUA (uno por año).  
2. Convierte cada PDF en un `data.frame` limpio y unificado.  
3. Filtra los datos según el rango de fechas indicado.  
4. Exporta los resultados a un archivo `.csv`.  
5. (Opcionalmente) conserva o elimina los PDF originales.

---

## Argumentos de la función

| **Argumento** | **Tipo** | **Descripción** |
|----------------|-----------|-----------------|
| `variable` | `character` | Tipo de dato a descargar: `"temp.max"`, `"temp.min"`, `"temp.med"`, `"precip"`. |
| `start.date` | `Date` | Fecha inicial (mínimo enero de 1985). |
| `end.date` | `Date` | Fecha final. |
| `path` | `character` | Carpeta donde se almacenarán los archivos descargados y resultados. |
| `export.csv` | `logical` | Si `TRUE`, exporta los datos a formato CSV. |
| `keep.pdf` | `logical` | Si `TRUE`, conserva los archivos PDF descargados. |

---

## Requisitos

- **R ≥ 4.0**
- Paquete necesario:

```r
install.packages("pdftools")
```

---

## Ejemplo de uso

```r
# Definir fechas y ruta
stdate     <- as.Date("1985-01-01")
endate     <- as.Date("2025-09-01")
path       <- getwd()
export.csv <- TRUE
keep.pdf   <- FALSE

# Descargar y procesar datos de temperatura media
tmed <- conagua.temp.precip("temp.med", stdate, endate, path, export.csv, keep.pdf)
```

El script descargará los datos, los transformará y generará un archivo CSV con el siguiente formato:

```
CONAGUA-TMED_1985m01-2025m09.csv
```

---

## Estructura de salida

- **Carpeta temporal:** `CONAGUA-TMED_pdf/` (solo si `keep.pdf = TRUE`)  
- **Archivo CSV:** contiene los datos por estado y mes.  

**Columnas del CSV:**
- `entidad` → nombre del estado mexicano  
- `AAAA-MM` → valor mensual (°C o mm)

---

## Notas adicionales

- Los datos están disponibles únicamente desde **enero de 1985**.  
- Las descargas dependen de la disponibilidad de los archivos en el portal de CONAGUA.  
- En caso de error de conexión o archivo faltante, el script continúa con el siguiente año disponible.  
- Los nombres de las columnas combinan año y mes con el formato `AAAA-MM`.

---
