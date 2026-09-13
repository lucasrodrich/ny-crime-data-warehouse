# 📊 Data Warehouse de Análisis Criminal - Estado de New York (1990-2024)

**Universidad Católica de Córdoba - Facultad de Ingeniería**  
**Base de Datos II - Metodología HEFESTO**

---

## 📁 Archivos del Proyecto

### 1️⃣ **Proyecto_Crimes_NY_HEFESTO.md** (Documento principal)
**Descripción:** Informe completo siguiendo la metodología HEFESTO con todos los pasos del diseño del Data Warehouse.

**Contenido:**
- ✅ PASO 1: Análisis de Requerimientos (12 preguntas de negocio)
- ✅ PASO 2: Análisis de los OLTP (indicadores, correspondencias, granularidad)
- ✅ PASO 3: Modelo Lógico del DW (esquema en estrella)
- ✅ PASO 4: Integración de Datos (ETL inicial y actualización)

**Modelo dimensional:**
- 4 Dimensiones: `dim_tiempo`, `dim_geografia`, `dim_agencia`, `dim_categoria`
- 1 Tabla de Hechos: `fact_crimes_ny`
- 2 Tablas auxiliares: `crimes_raw`, `log_procesos_etl`

---

### 2️⃣ **creacion_tablas_crimes_ny.sql**
**Descripción:** Script SQL para crear el esquema completo del Data Warehouse en MySQL.

**Contenido:**
```sql
-- Crea la base de datos: crimes_ny_dw
-- Define 7 tablas con sus relaciones
-- Incluye índices optimizados para consultas OLAP
-- Inserta datos maestros en dim_categoria
```

**Uso:**
```bash
mysql --default-character-set=utf8mb4 -u root -p < creacion_tablas_crimes_ny.sql
```

---

### 3️⃣ **etl_crimes_ny_mysql.py**
**Descripción:** Script Python para el proceso ETL completo (Extract, Transform, Load).

**Características:**
- 📥 Carga del CSV: `Index_Crimes_by_County_and_Agency__Beginning_1990.csv`
- 🧹 Limpieza y validación de datos
- 🔄 Transformación con granularidades temporales múltiples
- 📤 Carga a MySQL con técnica UNPIVOT para categorías
- ✅ Validaciones y logging completo

**Requisitos:**
```bash
pip install pandas numpy sqlalchemy pymysql --break-system-packages
```

**Uso:**
```bash
python etl_crimes_ny_mysql.py
```

**Nota:** Las credenciales de MySQL y la ruta del CSV se configuran por variables de entorno (nunca hardcodeadas en el script) — ver sección "Configurar credenciales" más abajo.

---

### 4️⃣ **vistas_crimes_ny.sql**
**Descripción:** 13 vistas SQL optimizadas para análisis y visualización de datos.

**Vistas incluidas:**

| Vista | Propósito |
|-------|-----------|
| `v_kpi_globales` | KPIs principales del dashboard |
| `v_evolucion_anual` | Serie temporal año por año |
| `v_evolucion_decada` | Análisis por década |
| `v_top_condados` | Ranking de condados por delitos |
| `v_comparativa_nyc_vs_nonyc` | Comparación NYC vs resto |
| `v_detalle_condados` | Detalle completo por condado |
| `v_top_agencias` | Ranking de agencias policiales |
| `v_evolucion_lustro` | Evolución en lustros (5 años) |
| `v_evolucion_bianual_propiedad` | Delitos de propiedad bianual |
| `v_tendencias_condados` | Identificar alza/baja por condado |
| `v_variacion_interanual` | Variación año a año |
| `v_proporcion_por_decada_region` | Proporción violentos/propiedad |
| `v_ranking_delitos_especificos` | Ranking por tipo de delito |

**Uso:**
```bash
mysql --default-character-set=utf8mb4 -u root -p crimes_ny_dw < vistas_crimes_ny.sql
```

---

## 🎯 Preguntas de Negocio que Responde el DW

1. ✅ ¿Cuáles son las diferencias en índices de delitos entre NYC y condados fuera de NYC?
2. ✅ ¿Qué región (NYC/noNYC) presenta mayor crecimiento en delitos violentos?
3. ✅ ¿Cómo se distribuye la proporción de delitos violentos vs delitos de propiedad?
4. ✅ ¿Qué década presenta los mayores índices de criminalidad?
5. ✅ ¿Cuál es la evolución de los delitos violentos en lustros?
6. ✅ ¿Qué tendencia bianual muestran los delitos contra la propiedad?
7. ✅ ¿Qué condados presentan tendencias a la baja o a la alza?
8. ✅ ¿Cuál es la proporción de delitos contra la propiedad por región?
9. ✅ ¿Cómo evoluciona la proporción violento/propiedad por década en NYC vs noNYC?
10. ✅ ¿Cuáles son las agencias policiales con mayor índice de delitos?
11. ✅ ¿Qué tipos de delitos muestran mayor incremento por año?
12. ✅ ¿Cuál es la variación mensual de delitos?

---

## 📊 Estructura del Data Warehouse

### Esquema en Estrella (Star Schema)

```
                    ┌─────────────────┐
                    │ fact_crimes_ny  │
                    │   (Tabla de     │
                    │    Hechos)      │
                    └────────┬────────┘
                             │
            ┌────────────────┼────────────────┬─────────────┐
            │                │                │             │
            ▼                ▼                ▼             ▼
    ┌─────────────┐  ┌─────────────┐  ┌──────────┐  ┌──────────┐
    │ dim_tiempo  │  │dim_geografia│  │dim_agencia│  │dim_cate  │
    │  (35 años)  │  │(62 condados)│  │(843 agenc)│  │goria     │
    └─────────────┘  └─────────────┘  └──────────┘  └──────────┘
```

### Métricas Principales

- **Total de Delitos** (Index Total): 1990-2024
- **Delitos Violentos**: Murder, Rape, Robbery, Aggravated Assault
- **Delitos de Propiedad**: Burglary, Larceny, Motor Vehicle Theft
- **Ratios y Tasas**: Calculados automáticamente

---

## 🚀 Guía de Instalación

### Paso 1: Requisitos previos
```bash
# MySQL 8.0+
# Python 3.8+
# Archivo CSV de datos
```

### Paso 2: Crear base de datos
```bash
mysql --default-character-set=utf8mb4 -u root -p < creacion_tablas_crimes_ny.sql
```

### Paso 3: Instalar dependencias Python
```bash
pip install pandas numpy sqlalchemy pymysql --break-system-packages
```

### Paso 4: Configurar credenciales (variables de entorno)
El script **no** trae ninguna contraseña hardcodeada: lee la configuración de
variables de entorno y, si falta la contraseña, la pide de forma interactiva.

```bash
# Windows PowerShell
$env:CRIMES_NY_DB_HOST     = "localhost"
$env:CRIMES_NY_DB_PORT     = "3306"
$env:CRIMES_NY_DB_USER     = "root"
$env:CRIMES_NY_DB_PASSWORD = "TU_PASSWORD"
$env:CRIMES_NY_DB_NAME     = "crimes_ny_dw"

# Linux / macOS
export CRIMES_NY_DB_HOST=localhost
export CRIMES_NY_DB_PORT=3306
export CRIMES_NY_DB_USER=root
export CRIMES_NY_DB_PASSWORD=TU_PASSWORD
export CRIMES_NY_DB_NAME=crimes_ny_dw
```

Todas las variables tienen default salvo la contraseña (`root`/`localhost`/`3306`/`crimes_ny_dw`).
Si `CRIMES_NY_DB_PASSWORD` no está seteada y la terminal es interactiva, el
script la pide con `getpass` (no queda visible en la consola ni en el historial).

También se puede sobreescribir la ubicación del CSV (por defecto, el que está
junto al script) con `CRIMES_NY_CSV_PATH`.

### Paso 5: Ejecutar ETL
```bash
python etl_crimes_ny_mysql.py
```

### Paso 6: Crear vistas analíticas
```bash
mysql --default-character-set=utf8mb4 -u root -p crimes_ny_dw < vistas_crimes_ny.sql
```

---

## 📈 Ejemplos de Consultas SQL

### Ver KPIs globales
```sql
SELECT * FROM v_kpi_globales;
```

### Top 10 condados con más delitos
```sql
SELECT * FROM v_top_condados LIMIT 10;
```

### Comparativa NYC vs Non-NYC última década
```sql
SELECT * 
FROM v_comparativa_nyc_vs_nonyc 
WHERE año >= 2014;
```

### Condados con tendencia a la baja en delitos violentos
```sql
SELECT * 
FROM v_tendencias_condados 
WHERE tendencia = 'Baja'
ORDER BY variacion_porcentual ASC;
```

### Evolución de homicidios por año
```sql
SELECT año, homicidios, var_pct_homicidios
FROM v_ranking_delitos_especificos
ORDER BY año;
```

---

## 📊 Integración con Power BI

### Conexión a MySQL desde Power BI

1. **Abrir Power BI Desktop**
2. **Obtener datos** → **Base de datos MySQL**
3. **Configurar conexión:**
   - Servidor: `localhost`
   - Base de datos: `crimes_ny_dw`
4. **Seleccionar tablas:**
   - `fact_crimes_ny` (tabla de hechos)
   - `dim_tiempo`, `dim_geografia`, `dim_agencia`, `dim_categoria`
   - Vistas: `v_kpi_globales`, `v_evolucion_anual`, etc.

### Relaciones en Power BI

Power BI detectará automáticamente las relaciones:
- `fact_crimes_ny.time_id` → `dim_tiempo.time_id`
- `fact_crimes_ny.geo_id` → `dim_geografia.geo_id`
- `fact_crimes_ny.agency_id` → `dim_agencia.agency_id`
- `fact_crimes_ny.category_id` → `dim_categoria.category_id`

---

## 📊 Estadísticas del Dataset

| Métrica | Valor |
|---------|-------|
| **Registros originales** | 23,830 |
| **Condados únicos** | 62 |
| **Agencias policiales** | 843 |
| **Rango temporal** | 1990 - 2024 (35 años) |
| **Condados NYC** | 5 (New York, Kings, Queens, Bronx, Richmond) |
| **Condados Non-NYC** | 57 |
| **Registros en fact_crimes_ny** | ~71,490 (con categorías) |

---

## 🎓 Metodología HEFESTO Aplicada

### Paso 1: Análisis de Requerimientos ✅
- Identificación de 12 preguntas clave
- Definición de indicadores y perspectivas
- Modelo conceptual inicial

### Paso 2: Análisis de los OLTP ✅
- Conformación de indicadores con fórmulas
- Establecimiento de correspondencias CSV → DW
- Definición de nivel de granularidad

### Paso 3: Modelo Lógico ✅
- Diseño de esquema en estrella
- Definición de claves primarias y foráneas
- Optimización con índices

### Paso 4: Integración de Datos ✅
- ETL inicial completo
- Estrategia de actualización incremental
- Validaciones y controles de calidad

---

## 🛠️ Tecnologías Utilizadas

- **SGBD:** MySQL 8.0+
- **Lenguaje ETL:** Python 3.8+
- **Librerías:** pandas, numpy, sqlalchemy, pymysql
- **Modelado:** Esquema en Estrella (Star Schema)
- **Metodología:** HEFESTO para Data Warehouse
- **Visualización:** Power BI / Tableau (compatible)

---

## 👥 Equipo de Desarrollo

**Integrantes:**
- Amuchastegui, Matias - 2317591
- Rodriguez Richard, Lucas - 2317609
- Sardoy, Blas - 2318896

**Profesores:**
- Gastón Emilio Severina
- Julio Gutierrez

**Universidad Católica de Córdoba**  
**Facultad de Ingeniería**  
**Base de Datos II**

---

## 📝 Notas Importantes

### Calidad de Datos
- ✅ Eliminación de registros con valores nulos críticos
- ✅ Validación de consistencia (Violent + Property ≈ Index)
- ✅ Normalización de nombres de condados y agencias
- ✅ Cálculo automático de tasas y ratios

### Performance
- ⚡ Índices optimizados en todas las tablas
- ⚡ Vistas materializadas para consultas frecuentes
- ⚡ Estrategia UNPIVOT para normalización eficiente

### Actualización
- 🔄 Carga incremental cada 3 meses
- 🔄 Recalculo automático de crime_tendency
- 🔄 Log completo de todos los procesos ETL

---

## 📧 Soporte

Para consultas sobre el proyecto:
- **Email institucional:** [Consultar con profesores]
- **Documentación:** Ver `Proyecto_Crimes_NY_HEFESTO.md`

---

## 📄 Licencia

Este proyecto es de uso académico para la materia Base de Datos II de la Universidad Católica de Córdoba.

---

**Última actualización:** Noviembre 2025  
**Versión:** 1.0
