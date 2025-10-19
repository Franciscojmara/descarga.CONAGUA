
## DESCARGAR DATOS DE TEMPERATURA (MEDIANA, MÁXIMA, MÍNIMA) Y PRECIPITACIÓN DE CONAGUA
##   ** Los datos se descargan como archivos PDF, se transforman en un data frame y se exportan a un archivo CSV.
##   ** Los datos son mensuales y por estado de México.
##   ** CONAGUA denomina estos datos: "Resúmenes Mensuales de Lluvia y Temperatura".
##   ** Recuperados de    
##      https://smn.conagua.gob.mx/es/climatologia/temperaturas-y-lluvias/resumenes-mensuales-de-temperaturas-y-lluvias

## Argumentos
##   ** variable: Cadena de texto. Dato a recuperar: temperatura máxima ("temp.max"), 
##                temperatura mínima ("temp.min"), temperatura mediana ("temp.med"),
##                precipitación ("precip").
##   ** start.date: Fecha. Valor por defecto NULL. Primera fecha a recuperar (disponible solo desde enero de 1985).
##   ** end.date: Fecha. Valor por defecto NULL. Última fecha a recuperar.
##   ** path: Cadena. Ruta del directorio donde se descargarán/almacenarán los datos.
##   ** export.csv: Booleano. TRUE si la función debe exportar los datos descargados en formato CSV.
##   ** keep.pdf: Booleano. TRUE si se deben conservar los archivos PDF descargados. En caso contrario, se eliminan.

conagua.resumen.temp.precip <- function(variable = "temp.max", start.date = NULL,
                                        end.date = NULL, path = NULL, export.csv = TRUE, 
                                        keep.pdf = TRUE) {
  
  # Verificar el tipo de dato a recuperar: temperatura mediana/mínima/máxima o precipitación
  srcd <- switch(variable,
                 "precip" = "PREC", "temp.min" = "TMIN", "temp.med" = "TMED", "temp.max" = "TMAX",
                 stop(
                   cat("Use cualquiera de las siguientes opciones para el argumento `variable`:\n", 
                       paste(c("precip",paste("temp",c("min","med","max"),sep=".")), collapse = ", "),
                       "\n")
                 )
  )
  # Instalar/Cargar el paquete `pdftools`
  if(!require("pdftools", character.only = TRUE)) { 
    install.packages("pdftools", dependencies=TRUE)
  }
  library("pdftools", character.only = TRUE)
  
  # Asignar valores a los argumentos si son nulos
  if(is.null(path)) path <- getwd()
  if(is.null(end.date)) {
    end.date <- format(Sys.Date(), "%Y-%m-%d")
  } else {
    end.date <- as.Date(format(end.date, "%Y-%m-%d"))
  }
  if(is.null(start.date)) {
    selected.years <- c(1985:as.integer(substr(end.date,1,4)))
    year <- selected.years
  } else {
    start.date <- as.Date(format(start.date, "%Y-%m-%d"))
    selected.years <- seq.Date(start.date, end.date, by = "1 month")
    year <- unique(sapply(selected.years,function(x) as.integer(substr(x,1,4)), simplify = TRUE))
  }
  
  # Verificar los años disponibles en CONAGUA
  available.years <- seq(1985, as.integer(substr(endate,1,4)), 1)
  not.available.y <- setdiff(year, available.years)
  if(length(not.available.y) > 0) 
    stop(cat("Año(s):", not.available.y, "no disponible(s) en CONAGUA. Disponible desde 1985/01"))
  
  # Crear ruta para almacenar los datos descargados en formato PDF
  path.pdf <- file.path(path, paste0("CONAGUA-", srcd, "_pdf"))
  if(!file.exists(path.pdf)) dir.create(path.pdf)
  
  # Descargar datos desde CONAGUA y almacenarlos en un nuevo directorio (temporal)
  cat("***** DESCARGANDO DATOS *****\n")
  url0 <- "https://smn.conagua.gob.mx/tools/DATA/Climatolog%C3%ADa/Pron%C3%B3stico%20clim%C3%A1tico/Temperatura%20y%20Lluvia"
  for(yy in year) {
    url   <- file.path(url0, srcd, paste(yy, "pdf", sep = "."))
    fname <- file.path(path.pdf, paste(yy, "pdf", sep = "."))
    tryCatch({
      download.file(url, fname, mode = "wb", quiet = TRUE)
      message(cat("Descargado:", paste0(yy, ".pdf"), "\n"))
    }, error = function(e) {
      message(cat("¡¡ERROR!! -- Falló la descarga de", paste0(yy,".pdf :"),  e$message, "\n"))
      next
    })
  }
  
  # FUNCIÓN: transformar el archivo PDF (descargado de CONAGUA) en un data frame
  conagua.pdf.to.df <- function(pdf) {
    # Abrir PDF
    text <- pdf_text(pdf)
    # Procesar contenido del PDF
    text <- gsub(" +", ",", text) # reemplazar espacios por comas
    text <- strsplit(text, split = "\n")[[1]] # dividir la cadena por filas de la tabla
    text <- gsub("^,", "", text[4:37]) # seleccionar datos de los estados y manejar la “columna” del estado
    text <- gsub("(?<=\\D),(?=\\D)", ".", text, perl = TRUE) # manejar la “columna” del estado
    # Datos como matriz
    dataN <- strsplit(text[[1]], "\\.")[[1]] # obtener nombres de columnas
    dataV <- strsplit(text[-1], ",") # obtener filas de datos
    dataV <- do.call(rbind, dataV)   # unir filas en una matriz
    colnames(dataV) <- dataN[1:ncol(dataV)] # agregar nombres a las columnas
    # Datos como data frame:
    #     (i) Matriz convertida en data frame, eliminar la columna `Anual` (si existe)
    #    (ii) Valores de texto que deberían ser numéricos, convertirlos a numéricos
    #   (iii) Transformar abreviaturas de meses en números de mes
    conagua.df <- as.data.frame(dataV)
    if("Anual" %in% names(conagua.df)) {
      conagua.df <- conagua.df[, -which(names(conagua.df) == "Anual")] 
    }
    conagua.df[,-1] <- lapply(conagua.df[,-1], as.numeric)
    names(conagua.df) <- c(
      "entidad", 
      paste(
        gsub("\\.pdf", "", basename(pdf)),
        sapply(names(conagua.df)[-1], function(x){
          switch(tolower(x),
                 "ene" = "01",
                 "feb" = "02",
                 "mar" = "03",
                 "abr" = "04",
                 "may" = "05",
                 "jun" = "06",
                 "jul" = "07",
                 "ago" = "08",
                 "sep" = "09",
                 "oct" = "10",
                 "nov" = "11",
                 "dic" = "12"
          )
        }, simplify = TRUE),
        sep = "-"
      )
    )
    return(conagua.df)
  }
  
  # Cargar los PDFs descargados de CONAGUA y transformar cada uno en un data frame limpio
  # Almacenar todos los data frames en una lista
  cat("***** TRANSFORMANDO ARCHIVOS PDF EN DATA FRAME *****\n")
  pdfs <- unname(sapply(list.files(path.pdf), function(ff) file.path(path.pdf, ff)))
  conagua.data <- lapply(pdfs, conagua.pdf.to.df)
  names(conagua.data) <- gsub("\\.pdf", "", basename(pdfs))
  
  # Unir los data frames en uno solo
  conagua.data <- Reduce(function(x, y) merge(x, y, by = "entidad"), conagua.data)
  
  # Seleccionar columnas de acuerdo con `start.date` y `end.date`
  selected.dates <- seq(start.date, end.date, by = "1 month")
  selected.dates <- sapply(selected.dates, format, "%Y-%m", simplify = TRUE)
  conagua.data <- conagua.data[, c("entidad", selected.dates)]
  
  # Limpiar directorios, exportar el data frame y devolver los datos
  if(keep.pdf){
    cat("***** ARCHIVOS PDF ORIGINALES ALMACENADOS EN:", normalizePath(path.pdf), "\n")
  } else {
    unlink(path.pdf, recursive = T)
  } 
  if(export.csv) {
    sdate <- gsub("-", "m", names(conagua.data)[2])
    edate <- gsub("-", "m", tail(names(conagua.data),1))
    fname <- paste0("CONAGUA-", srcd, "_", sdate, "-", edate, ".csv")
    fpath <- file.path(path, fname)
    write.csv(conagua.data, fpath, row.names = FALSE, fileEncoding = "UTF-8")
    cat("***** DATOS EXPORTADOS EN FORMATO CSV A:", normalizePath(path), "*****\n")
  }
  cat("======================================================================\n\n")
  cat("***** ¡ÉXITO! *****\n")
  return(conagua.data)
}


#### EJEMPLOS

# stdate     <- as.Date("1997-02-01")
# endate     <- as.Date("2022-04-01")
# path       <- getwd()
# export.csv <- TRUE
# keep.pdf   <- FALSE
# 
# tmed <- conagua.temp.precip("temp.med", stdate, endate, path, export.csv, keep.pdf = TRUE)
# tmin <- conagua.temp.precip("temp.min", year, path, export.csv, keep.pdf)
# tmax <- conagua.temp.precip("temp.max", year, path, export.csv, keep.pdf)
# precip <- conagua.temp.precip("precip", year, path, export.csv, keep.pdf = TRUE)
