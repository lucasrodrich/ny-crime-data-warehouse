# **INFORME BD2 - METODOLOGÍA HEFESTO**
## **Análisis de Delitos en el Estado de New York (1990-2024)**

**Universidad Católica de Córdoba**  
**Facultad de Ingeniería**

**Profesor**:   
Gastón Emilio Severina  
Julio Gutierrez

**Integrantes:**  
Amuchastegui, Matias 2317591  
Rodriguez Richard, Lucas 2317609  
Sardoy, Blas 2318896

---

## **PASO 1) ANÁLISIS DE REQUERIMIENTOS**

### a) Identificar preguntas

1. ¿Cuáles son las diferencias en índices de delitos entre NYC y condados fuera de NYC?
2. ¿Qué región (NYC/noNYC) presenta mayor crecimiento en delitos violentos?
3. ¿Cómo se distribuye la proporción de delitos violentos vs delitos de propiedad entre NYC y noNYC?
4. ¿Qué década presenta los mayores índices de criminalidad?
5. ¿Cuál es la evolución de los delitos violentos en lustros?
6. ¿Qué tendencia bianual muestran los delitos contra la propiedad?
7. ¿Qué condados presentan tendencias a la baja o a la alza en crímenes violentos específicamente?
8. ¿Cuál es la proporción de delitos contra la propiedad por región?
9. ¿Cómo evoluciona la proporción delito violento/propiedad por década en NYC vs noNYC?
10. ¿Cuáles son las agencias policiales con mayor índice de delitos reportados?
11. ¿Qué tipos específicos de delitos (murder, rape, robbery, etc.) muestran mayor incremento por año?

> **Fuera de alcance:** una pregunta original sobre variación mensual de delitos fue descartada — `dim_tiempo` tiene granularidad anual (el campo `Months_Reported` del CSV indica cuántos meses cubre el reporte de cada fila, no el mes en que ocurrió cada delito), así que esa pregunta es irrespondible con esta fuente. El modelo final responde 11 preguntas operativas, no 12.

---

### b) Identificar indicadores y perspectivas

| **Indicadores (hechos)** | **Perspectivas (dimensiones)** |
|:-------------------------|:-------------------------------|
| Total de delitos (Index Total) | Tiempo (Año, Década, Lustro, Bianual) |
| Total delitos violentos | Geografía (Condado, Región NYC/noNYC) |
| Total delitos de propiedad | Agencia Policial |
| Tasa de delitos violentos (%) | Categoría de delito |
| Tasa de delitos de propiedad (%) | - |
| Ratio violencia/propiedad | - |
| Variación porcentual interanual | - |
| Delitos específicos (murder, rape, robbery, etc.) | - |

---

### c) Modelo Conceptual

```
┌─────────────────────────────────────────────────────────────┐
│                    TABLA DE HECHOS                          │
│                  HECHO_DELITOS_NY                           │
├─────────────────────────────────────────────────────────────┤
│ - time_id (FK)                                              │
│ - geo_id (FK)                                               │
│ - agency_id (FK)                                            │
│ - category_id (FK)                                          │
│                                                             │
│ MEDIDAS:                                                    │
│ - total_delitos (Index Total)                               │
│ - total_violentos (Violent Total)                           │
│ - total_propiedad (Property Total)                          │
│ - murder                                                    │
│ - rape                                                      │
│ - robbery                                                   │
│ - aggravated_assault                                        │
│ - burglary                                                  │
│ - larceny                                                   │
│ - motor_vehicle_theft                                       │
│ - months_reported                                           │
│ - ratio_violencia                                           │
│ - tasa_violentos_pct                                        │
│ - tasa_propiedad_pct                                        │
└─────────────────────────────────────────────────────────────┘
           │              │              │              │
           │              │              │              │
           ▼              ▼              ▼              ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ DIM_TIEMPO   │  │ DIM_GEOGRAFIA│  │ DIM_AGENCIA  │  │DIM_CATEGORIA │
├──────────────┤  ├──────────────┤  ├──────────────┤  ├──────────────┤
│- time_id(PK) │  │- geo_id (PK) │  │-agency_id(PK)│  │-category_id  │
│- year        │  │- county_name │  │- agency_name │  │  (PK)        │
│- decada      │  │- region_type │  │- county      │  │- tipo_delito │
│- lustro      │  │- is_nyc      │  │- is_nyc      │  │- categoria   │
│- bianual     │  │- crime_prone │  │- region      │  │- descripcion │
│- trimestre   │  │- latitude    │  │              │  │- componentes │
│- semestre    │  │- longitude   │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘
```

---

## **PASO 2) ANÁLISIS DE LOS OLTP**

### a) Conformar indicadores

#### **Indicador 1: "Total de delitos reportados"**
- **Hechos**: Index Total
- **Función de sumarización**: SUM
- **Aclaración**: Representa la sumatoria de todos los delitos (violentos + propiedad) registrados en un condado/agencia durante un período determinado.

#### **Indicador 2: "Total de delitos violentos"**
- **Hechos**: Violent Total
- **Función de sumarización**: SUM
- **Aclaración**: Suma de delitos violentos (Murder + Rape + Robbery + Aggravated Assault).

#### **Indicador 3: "Total de delitos contra la propiedad"**
- **Hechos**: Property Total
- **Función de sumarización**: SUM
- **Aclaración**: Suma de delitos contra bienes (Burglary + Larceny + Motor Vehicle Theft).

#### **Indicador 4: "Ratio de violencia"**
- **Hechos**: (Violent Total) / (Index Total)
- **Función de sumarización**: AVG
- **Aclaración**: Proporción promedio de delitos violentos respecto al total de delitos en una región.

#### **Indicador 5: "Tasa de delitos violentos (%)"**
- **Hechos**: (Violent Total / Index Total) × 100
- **Función de sumarización**: AVG
- **Aclaración**: Porcentaje de delitos violentos sobre el total.

#### **Indicador 6: "Tasa de delitos de propiedad (%)"**
- **Hechos**: (Property Total / Index Total) × 100
- **Función de sumarización**: AVG
- **Aclaración**: Porcentaje de delitos de propiedad sobre el total.

#### **Indicador 7: "Variación porcentual interanual"**
- **Hechos**: ((Index Total año actual - Index Total año anterior) / Index Total año anterior) × 100
- **Función de sumarización**: AVG
- **Aclaración**: Crecimiento o decrecimiento porcentual de delitos entre años consecutivos.

#### **Indicador 8: "Delitos específicos por tipo"**
- **Hechos**: Murder, Rape, Robbery, Aggravated Assault, Burglary, Larceny, Motor Vehicle Theft
- **Función de sumarización**: SUM
- **Aclaración**: Totales individuales por tipo específico de delito.

---

### b) Establecer correspondencias

| **Elemento del Modelo Conceptual** | **Campo/Tabla en OLTP (CSV)** | **Descripción/Observaciones** |
|:------------------------------------|:------------------------------|:------------------------------|
| **Perspectiva: Tiempo** | Year | Representa el año del registro del delito |
| **Perspectiva: Geografía** | County | Condado donde se reportó el delito |
| **Perspectiva: Geografía - Región** | Region | Clasificación NYC / Non-New York City |
| **Perspectiva: Agencia** | Agency | Nombre de la agencia policial que reporta |
| **Perspectiva: Categoría** | Violent Total, Property Total | Clasificación de tipo de delito |
| **Indicador: Total delitos** | Index Total | Suma total de delitos reportados |
| **Indicador: Total violentos** | Violent Total | Total de delitos violentos |
| **Indicador: Total propiedad** | Property Total | Total de delitos contra la propiedad |
| **Indicador: Delito específico - Murder** | Murder | Homicidios |
| **Indicador: Delito específico - Rape** | Rape | Violaciones |
| **Indicador: Delito específico - Robbery** | Robbery | Robos |
| **Indicador: Delito específico - Aggravated Assault** | Aggravated Assault | Asaltos agravados |
| **Indicador: Delito específico - Burglary** | Burglary | Allanamientos |
| **Indicador: Delito específico - Larceny** | Larceny | Hurtos |
| **Indicador: Delito específico - Motor Vehicle Theft** | Motor Vehicle Theft | Robo de vehículos |
| **Indicador: Meses reportados** | Months Reported | Cantidad de meses con datos |
| **Indicador: Ratio violencia** | Violent Total / Index Total | Proporción calculada |

**Mapeo de correspondencias:**
- `County` → PERSPECTIVA Geografía (con clasificación NYC/Outside_NYC)
- `Year` → PERSPECTIVA Tiempo (múltiples granularidades)
- `Agency` → PERSPECTIVA Agencia Policial
- `Region` → Atributo derivado (NYC / Non-New York City)
- `Violent Total`, `Property Total` → PERSPECTIVA Categoría de Delito
- `Index Total` → INDICADOR Total delitos
- `Murder, Rape, Robbery, Aggravated Assault` → Componentes de Violent Total
- `Burglary, Larceny, Motor Vehicle Theft` → Componentes de Property Total

---

### c) Nivel de granularidad

#### **PERSPECTIVA "TIEMPO":**

**Datos disponibles y su granularidad:**
- **Año** (campo disponible: Year)
- **Década** (derivado: FLOOR(Year/10)×10)
- **Lustro** (derivado: FLOOR(Year/5)×5)
- **Bianual** (derivado: FLOOR(Year/2)×2)
- **Trimestre** (derivado: calculado si se tiene dato de mes)
- **Semestre** (derivado: calculado si se tiene dato de mes)

**Campos seleccionados:** Year (como base para todas las granularidades)

**Rango temporal:** 1990 - 2024 (35 años)

---

#### **PERSPECTIVA "GEOGRAFÍA":**

**Datos disponibles:**
- **County** (campo disponible: County) - 62 condados únicos
- **Region_Type** (campo disponible: Region - "NYC"/"Non-New York City")
- **Is_NYC** (derivado: Boolean basado en condados NYC)
- **Crime_Tendency** (derivado: Violence_Prone/Property_Prone/Mixed_Profile)

**Condados de NYC identificados:**
- New York (Manhattan)
- Kings (Brooklyn)
- Queens
- Bronx
- Richmond (Staten Island)

**Campos seleccionados:** County, Region, Is_NYC

---

#### **PERSPECTIVA "AGENCIA POLICIAL":**

**Datos disponibles:**
- **Agency** (campo disponible: Agency) - 884 valores únicos de (Agency, County): 822 agencias individuales + 62 filas de rollup "County Total" (una por condado, usadas para los agregados geográficos)
- **County** (relación con condado)
- **Region** (NYC o Non-NYC)

**Campos seleccionados:** Agency, County, Region

---

#### **PERSPECTIVA "CATEGORÍA DE DELITO":**

**Datos disponibles:**
- **Violent** (derivado de: Murder + Rape + Robbery + Aggravated Assault)
- **Property** (derivado de: Burglary + Larceny + Motor Vehicle Theft)
- **Tipo_Específico** (campos: Murder, Rape, Robbery, etc.)

**Categorías principales:**
1. Delitos Violentos
2. Delitos contra la Propiedad
3. Total General (Mix)

**Campos seleccionados:** Categoría (Violent/Property/Mixed), Tipo_Específico

---

### **GRANO PROPUESTO:**

**Una fila por:** `{Año, Condado, Agencia, Categoría de Delito}`

**Medidas en esa fila:**
- Total_Delitos (Index Total)
- Total_Violentos (Violent Total)
- Total_Propiedad (Property Total)
- Murder, Rape, Robbery, Aggravated Assault
- Burglary, Larceny, Motor Vehicle Theft
- Months_Reported
- Ratio_Violencia (Violent Total / Index Total)
- Tasa_Violentos_Pct
- Tasa_Propiedad_Pct

**Unicidad de fila:** `{Year, County, Agency, Crime_Category}`

---

### d) Modelo Conceptual ampliado

#### **PERSPECTIVA 1 - TIEMPO:**
- **Year** (campo base: 1990-2024)
- **Década** (FLOOR(Year/10)×10): 1990, 2000, 2010, 2020
- **Lustro** (FLOOR(Year/5)×5): 1990, 1995, 2000, 2005, 2010, 2015, 2020
- **Bianual** (FLOOR(Year/2)×2): 1990, 1992, 1994, ...
- **Trimestre** (derivado si hay mes)
- **Semestre** (derivado si hay mes)

#### **PERSPECTIVA 2 - GEOGRAFÍA:**
- **County** (campo directo del CSV) - 62 condados
- **Region_Type** (NYC / Non-New York City)
- **Is_NYC** (Boolean derivado)
- **Crime_Tendency** (Violence_Prone/Property_Prone/Mixed_Profile)
- **Latitude / Longitude** (agregado externo opcional para mapas)

#### **PERSPECTIVA 3 - AGENCIA POLICIAL:**
- **Agency** (884 filas en dim_agencia: 822 agencias individuales + 62 rollups "County Total")
- **County** (relación con condado)
- **Region** (NYC o Non-NYC)
- **Agency_Type** (City PD, County Sheriff, State Police, etc.)

#### **PERSPECTIVA 4 - CATEGORÍA DE DELITO:**
- **Violent** (Murder + Rape + Robbery + Aggravated Assault)
- **Property** (Burglary + Larceny + Motor Vehicle Theft)
- **Mixed** (combinación total)
- **Tipo_Específico** (8 tipos: Murder, Rape, Robbery, Aggravated Assault, Burglary, Larceny, Motor Vehicle Theft, Index Total)

---

#### **INDICADORES CON FÓRMULAS:**

**INDICADOR 1:** Total Delitos → `SUM(Index Total)`

**INDICADOR 2:** Total Violentos → `SUM(Violent Total)`

**INDICADOR 3:** Total Propiedad → `SUM(Property Total)`

**INDICADOR 4:** Ratio Violencia → `AVG(Violent Total / NULLIF(Index Total, 0))`

**INDICADOR 5:** Tasa Violentos % → `AVG((Violent Total / NULLIF(Index Total, 0)) × 100)`

**INDICADOR 6:** Tasa Propiedad % → `AVG((Property Total / NULLIF(Index Total, 0)) × 100)`

**INDICADOR 7:** Variación % Interanual → `((Index_Total_Año_Actual - Index_Total_Año_Anterior) / NULLIF(Index_Total_Año_Anterior, 0)) × 100`

**INDICADOR 8:** Delitos por Tipo → `SUM(Murder)`, `SUM(Rape)`, `SUM(Robbery)`, etc.

---

## **PASO 3: MODELO LÓGICO DEL DW**

### 1) Tipo de Modelo Lógico del DW:

**Modelo elegido:** **Esquema en Estrella (Star Schema)**

**Justificación:**
- El análisis de delitos se centra en un único conjunto de hechos (delitos reportados)
- Múltiples dimensiones descriptivas claramente definidas (tiempo, geografía, agencia, categoría)
- Simplicidad estructural y alto rendimiento en consultas OLAP
- Facilita el análisis multidimensional con herramientas de BI (Power BI, Tableau)
- Desnormalización controlada mejora performance de consultas analíticas

---

### 2) Diseño del Modelo Lógico

#### **TABLA DE HECHOS: `fact_crimes_ny`**

```sql
CREATE TABLE fact_crimes_ny (
    fact_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    time_id INT NOT NULL,
    geo_id INT NOT NULL,
    agency_id INT NOT NULL,
    category_id INT NOT NULL,
    
    -- Medidas principales
    total_delitos INT DEFAULT 0,
    total_violentos INT DEFAULT 0,
    total_propiedad INT DEFAULT 0,
    
    -- Delitos violentos específicos
    murder INT DEFAULT 0,
    rape INT DEFAULT 0,
    robbery INT DEFAULT 0,
    aggravated_assault INT DEFAULT 0,
    
    -- Delitos de propiedad específicos
    burglary INT DEFAULT 0,
    larceny INT DEFAULT 0,
    motor_vehicle_theft INT DEFAULT 0,
    
    -- Métricas calculadas
    months_reported INT DEFAULT 12,
    ratio_violencia DECIMAL(5,3) DEFAULT 0,
    tasa_violentos_pct DECIMAL(5,2) DEFAULT 0,
    tasa_propiedad_pct DECIMAL(5,2) DEFAULT 0,
    
    -- Control
    fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Foreign Keys
    FOREIGN KEY (time_id) REFERENCES dim_tiempo(time_id),
    FOREIGN KEY (geo_id) REFERENCES dim_geografia(geo_id),
    FOREIGN KEY (agency_id) REFERENCES dim_agencia(agency_id),
    FOREIGN KEY (category_id) REFERENCES dim_categoria(category_id),
    
    -- Índices para optimización
    INDEX idx_time (time_id),
    INDEX idx_geo (geo_id),
    INDEX idx_agency (agency_id),
    INDEX idx_category (category_id),
    INDEX idx_time_geo (time_id, geo_id)
) ENGINE=InnoDB;
```

---

#### **DIMENSIÓN: `dim_tiempo`**

```sql
CREATE TABLE dim_tiempo (
    time_id INT PRIMARY KEY,
    year INT NOT NULL,
    decada INT NOT NULL,
    lustro INT NOT NULL,
    bianual INT NOT NULL,
    trimestre INT,
    semestre INT,
    periodo_decade VARCHAR(20),
    periodo_lustro VARCHAR(20),
    es_decada_90 BOOLEAN DEFAULT FALSE,
    es_decada_00 BOOLEAN DEFAULT FALSE,
    es_decada_10 BOOLEAN DEFAULT FALSE,
    es_decada_20 BOOLEAN DEFAULT FALSE,
    
    INDEX idx_year (year),
    INDEX idx_decada (decada),
    INDEX idx_lustro (lustro)
) ENGINE=InnoDB;
```

---

#### **DIMENSIÓN: `dim_geografia`**

```sql
CREATE TABLE dim_geografia (
    geo_id INT AUTO_INCREMENT PRIMARY KEY,
    county_name VARCHAR(100) NOT NULL UNIQUE,
    region_type VARCHAR(50) NOT NULL, -- 'NYC' o 'Non-New York City'
    is_nyc BOOLEAN DEFAULT FALSE,
    crime_tendency VARCHAR(50), -- 'Violence_Prone', 'Property_Prone', 'Mixed_Profile'
    latitude DECIMAL(10, 7),
    longitude DECIMAL(10, 7),
    population INT, -- Opcional: población del condado
    area_sq_miles DECIMAL(10, 2), -- Opcional: área en millas cuadradas
    
    INDEX idx_region (region_type),
    INDEX idx_is_nyc (is_nyc),
    INDEX idx_county_name (county_name)
) ENGINE=InnoDB;
```

---

#### **DIMENSIÓN: `dim_agencia`**

```sql
CREATE TABLE dim_agencia (
    agency_id INT AUTO_INCREMENT PRIMARY KEY,
    agency_name VARCHAR(200) NOT NULL,
    county VARCHAR(100) NOT NULL,
    region VARCHAR(50) NOT NULL, -- 'NYC' o 'Non-New York City'
    is_nyc BOOLEAN DEFAULT FALSE,
    agency_type VARCHAR(50), -- 'City PD', 'County Sheriff', 'State Police', etc.
    
    UNIQUE KEY unique_agency_county (agency_name, county),
    INDEX idx_county (county),
    INDEX idx_region (region),
    INDEX idx_agency_type (agency_type)
) ENGINE=InnoDB;
```

---

#### **DIMENSIÓN: `dim_categoria`**

```sql
CREATE TABLE dim_categoria (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    tipo_delito VARCHAR(50) NOT NULL UNIQUE, -- 'Violent', 'Property', 'Mixed'
    categoria VARCHAR(100) NOT NULL,
    descripcion TEXT,
    componentes TEXT, -- Lista de delitos que componen la categoría
    
    INDEX idx_tipo (tipo_delito)
) ENGINE=InnoDB;

-- Datos iniciales
INSERT INTO dim_categoria (category_id, tipo_delito, categoria, descripcion, componentes) VALUES
(1, 'Violent', 'Delitos Violentos', 'Delitos que involucran violencia o amenaza contra personas', 'Murder, Rape, Robbery, Aggravated Assault'),
(2, 'Property', 'Delitos contra la Propiedad', 'Delitos que involucran robo o daño a la propiedad', 'Burglary, Larceny, Motor Vehicle Theft'),
(3, 'Mixed', 'Total General', 'Suma de todas las categorías de delito', 'Todos los delitos incluidos');
```

---

#### **TABLA AUXILIAR: `crimes_raw`**

```sql
CREATE TABLE crimes_raw (
    raw_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    county VARCHAR(100),
    agency VARCHAR(200),
    year INT,
    months_reported INT,
    index_total INT,
    violent_total INT,
    murder INT,
    rape INT,
    robbery INT,
    aggravated_assault INT,
    property_total INT,
    burglary INT,
    larceny INT,
    motor_vehicle_theft INT,
    region VARCHAR(50),
    fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    INDEX idx_year (year),
    INDEX idx_county (county),
    INDEX idx_agency (agency)
) ENGINE=InnoDB;
```

---

### 3) Diagrama Entidad-Relación (ER)

```
                    ┌─────────────────────────┐
                    │    fact_crimes_ny       │
                    ├─────────────────────────┤
                    │ * fact_id               │
                    │ * time_id (FK)          │
                    │ * geo_id (FK)           │
                    │ * agency_id (FK)        │
                    │ * category_id (FK)      │
                    │                         │
                    │ - total_delitos         │
                    │ - total_violentos       │
                    │ - total_propiedad       │
                    │ - murder                │
                    │ - rape                  │
                    │ - robbery               │
                    │ - aggravated_assault    │
                    │ - burglary              │
                    │ - larceny               │
                    │ - motor_vehicle_theft   │
                    │ - months_reported       │
                    │ - ratio_violencia       │
                    │ - tasa_violentos_pct    │
                    │ - tasa_propiedad_pct    │
                    │ - fecha_carga           │
                    └─────────────────────────┘
                             │
            ┌────────────────┼────────────────┬────────────────┐
            │                │                │                │
            ▼                ▼                ▼                ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│   dim_tiempo     │ │  dim_geografia   │ │   dim_agencia    │ │  dim_categoria   │
├──────────────────┤ ├──────────────────┤ ├──────────────────┤ ├──────────────────┤
│* time_id (PK)    │ │* geo_id (PK)     │ │* agency_id (PK)  │ │* category_id(PK) │
│- year            │ │- county_name     │ │- agency_name     │ │- tipo_delito     │
│- decada          │ │- region_type     │ │- county          │ │- categoria       │
│- lustro          │ │- is_nyc          │ │- region          │ │- descripcion     │
│- bianual         │ │- crime_tendency  │ │- is_nyc          │ │- componentes     │
│- trimestre       │ │- latitude        │ │- agency_type     │ │                  │
│- semestre        │ │- longitude       │ │                  │ │                  │
│- periodo_decade  │ │- population      │ │                  │ │                  │
│- periodo_lustro  │ │- area_sq_miles   │ │                  │ │                  │
│- es_decada_90    │ │                  │ │                  │ │                  │
│- es_decada_00    │ │                  │ │                  │ │                  │
│- es_decada_10    │ │                  │ │                  │ │                  │
│- es_decada_20    │ │                  │ │                  │ │                  │
└──────────────────┘ └──────────────────┘ └──────────────────┘ └──────────────────┘
```

---

### 4) Justificación de las decisiones de diseño

#### **a) Elección del Esquema en Estrella:**
- **Performance**: Las consultas OLAP son más rápidas al evitar múltiples JOINs complejos
- **Simplicidad**: Fácil de entender y mantener para analistas de negocio
- **Herramientas BI**: Optimizado para Power BI, Tableau y otras herramientas de visualización
- **Desnormalización controlada**: Las dimensiones contienen todos los atributos necesarios sin normalización excesiva

#### **b) Granularidad de la tabla de hechos:**
- **Nivel de detalle**: Una fila por {Año, Condado, Agencia, Categoría}
- **Justificación**: Este nivel permite análisis detallados por agencia mientras mantiene un tamaño manejable de datos
- **Agregaciones**: Se pueden realizar agregaciones a nivel de condado, región o año sin pérdida de información

#### **c) Métricas calculadas en la tabla de hechos:**
- **ratio_violencia**: Precalculado para evitar divisiones en tiempo de consulta
- **tasas_pct**: Facilita comparaciones directas entre regiones/períodos
- **Beneficio**: Mejora performance en consultas frecuentes de KPIs

#### **d) Dimensión de Tiempo:**
- **Múltiples granularidades**: Permite análisis flexible (anual, decenal, lustro, bianual)
- **Atributos booleanos por década**: Facilita filtros rápidos en visualizaciones
- **Periodos descriptivos**: Mejora legibilidad en reportes

#### **e) Dimensión de Geografía:**
- **crime_tendency**: Clasificación calculada post-carga según histórico de cada condado
- **Coordenadas geográficas**: Opcional pero útil para mapas interactivos
- **is_nyc**: Simplifica comparaciones NYC vs resto del estado

#### **f) Dimensión de Agencia:**
- **Relación con condado**: Mantiene trazabilidad jurisdiccional
- **agency_type**: Permite análisis por tipo de organización policial
- **Clave compuesta única**: Previene duplicados agency + county

---

## **PASO 4: INTEGRACIÓN DE DATOS**

Una vez construido el modelo lógico, se debe proceder a poblarlo con datos, utilizando técnicas de limpieza y calidad de datos, procesos ETL, etc. Luego se definirán las reglas y políticas para su respectiva actualización.

---

### 1) Carga inicial

La carga inicial al DW se realiza poblando el modelo de datos construido anteriormente. Se deben llevar a cabo tareas básicas como limpieza de datos, calidad de datos y procesos ETL (Inicio, Variables, Dimensiones, Hechos y Fin).

#### **Proceso ETL Detallado**

##### **PASO 1: Establecer Variables de Control**

Se definen las variables globales que delimitarán el rango temporal a cargar:

```sql
-- Variables de control para carga inicial
SET @Fecha_Desde = '1990-01-01';
SET @Fecha_Hasta = '2024-12-31';
SET @Proceso_ID = CONCAT('CARGA_INICIAL_CRIMES_', NOW());
SET @Usuario = 'ETL_SYSTEM';

-- Log inicio del proceso
CREATE TABLE IF NOT EXISTS log_procesos_etl (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    proceso_id VARCHAR(100),
    tipo_proceso VARCHAR(50),
    estado VARCHAR(50),
    mensaje TEXT,
    registros_procesados INT,
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP,
    duracion_segundos INT
);

INSERT INTO log_procesos_etl (proceso_id, tipo_proceso, estado, fecha_inicio)
VALUES (@Proceso_ID, 'CARGA_INICIAL', 'INICIADO', NOW());
```

---

##### **PASO 2: Carga de Dimensión TIEMPO**

Extracción y transformación de datos temporales desde el CSV:

```sql
-- Crear tabla temporal con años únicos
CREATE TEMPORARY TABLE temp_years AS
SELECT DISTINCT Year
FROM crimes_raw
WHERE Year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta)
ORDER BY Year;

-- Insertar en dimensión tiempo con todas las granularidades
INSERT INTO dim_tiempo (
    time_id, 
    year, 
    decada, 
    lustro, 
    bianual, 
    trimestre, 
    semestre,
    periodo_decade,
    periodo_lustro,
    es_decada_90,
    es_decada_00,
    es_decada_10,
    es_decada_20
)
SELECT 
    Year AS time_id,
    Year AS year,
    FLOOR(Year/10)*10 AS decada,
    FLOOR(Year/5)*5 AS lustro,
    FLOOR(Year/2)*2 AS bianual,
    CEIL(Year/3) AS trimestre,
    CEIL(Year/6) AS semestre,
    CONCAT(FLOOR(Year/10)*10, 's') AS periodo_decade,
    CONCAT(FLOOR(Year/5)*5, '-', FLOOR(Year/5)*5 + 4) AS periodo_lustro,
    CASE WHEN FLOOR(Year/10)*10 = 1990 THEN TRUE ELSE FALSE END AS es_decada_90,
    CASE WHEN FLOOR(Year/10)*10 = 2000 THEN TRUE ELSE FALSE END AS es_decada_00,
    CASE WHEN FLOOR(Year/10)*10 = 2010 THEN TRUE ELSE FALSE END AS es_decada_10,
    CASE WHEN FLOOR(Year/10)*10 = 2020 THEN TRUE ELSE FALSE END AS es_decada_20
FROM temp_years;

-- Verificación
SELECT COUNT(*) AS total_periodos, 
       MIN(year) AS año_inicio, 
       MAX(year) AS año_fin
FROM dim_tiempo;
```

**Resultado esperado:** 35 registros (1990-2024)

---

##### **PASO 3: Carga de Dimensión GEOGRAFÍA**

Transformación con lógica de clasificación NYC/Outside_NYC:

```sql
-- Definir condados de NYC
SET @NYC_Counties = 'New York,Kings,Queens,Bronx,Richmond';

-- Insertar condados únicos en dim_geografia
INSERT INTO dim_geografia (
    county_name, 
    region_type, 
    is_nyc, 
    crime_tendency
)
SELECT DISTINCT
    TRIM(County) AS county_name,
    CASE 
        WHEN FIND_IN_SET(TRIM(County), @NYC_Counties) > 0 
        THEN 'NYC'
        ELSE 'Non-New York City'
    END AS region_type,
    CASE 
        WHEN FIND_IN_SET(TRIM(County), @NYC_Counties) > 0 
        THEN TRUE
        ELSE FALSE
    END AS is_nyc,
    'Pending_Calculation' AS crime_tendency  -- Será calculado posteriormente
FROM crimes_raw
WHERE County IS NOT NULL 
  AND TRIM(County) != '';

-- Verificación
SELECT 
    region_type,
    COUNT(*) AS total_condados
FROM dim_geografia
GROUP BY region_type;
```

**Resultado esperado:** 62 condados (5 NYC, 57 Non-NYC)

---

##### **PASO 4: Carga de Dimensión AGENCIA**

Extracción de todas las agencias únicas:

```sql
-- Insertar agencias únicas
INSERT INTO dim_agencia (
    agency_name, 
    county, 
    region, 
    is_nyc,
    agency_type
)
SELECT DISTINCT
    TRIM(Agency) AS agency_name,
    TRIM(County) AS county,
    Region AS region,
    CASE 
        WHEN Region = 'New York City' THEN TRUE 
        ELSE FALSE 
    END AS is_nyc,
    CASE
        WHEN Agency LIKE '%City PD%' THEN 'City Police'
        WHEN Agency LIKE '%County Sheriff%' OR Agency LIKE '%SO%' THEN 'County Sheriff'
        WHEN Agency LIKE '%State Police%' THEN 'State Police'
        WHEN Agency LIKE '%Village PD%' THEN 'Village Police'
        WHEN Agency LIKE '%Town PD%' THEN 'Town Police'
        ELSE 'Other'
    END AS agency_type
FROM crimes_raw
WHERE Agency IS NOT NULL 
  AND TRIM(Agency) != ''
  AND County IS NOT NULL
ORDER BY county, agency_name;

-- Verificación
SELECT 
    agency_type,
    COUNT(*) AS total_agencias
FROM dim_agencia
GROUP BY agency_type
ORDER BY total_agencias DESC;
```

**Resultado esperado:** 884 agencias únicas (822 individuales + 62 rollups "County Total", uno por condado — ver nota de doble conteo más abajo)

> **Nota sobre doble conteo:** el CSV de origen trae, para cada condado y año, una fila de agencia = "County Total" (el agregado del condado) además de una fila por cada agencia individual que opera ahí. Cualquier vista o consulta que sume `Index Total` sobre todas las filas de `fact_crimes_ny` sin distinguir el rollup cuenta cada delito dos veces (factor de inflación medido ≈1,49x: 29,5 millones "ingenuos" vs. 19,8 millones reales para 1990-2024). Las 13 vistas de `vistas_crimes_ny.sql` filtran `agency_name = 'County Total'` para cualquier agregado geográfico o estatal, y usan exclusivamente las agencias individuales (excluyendo el rollup) en `v_top_agencias`, que rankea agencias.

---

##### **PASO 5: Carga de Dimensión CATEGORÍA DE DELITO**

Datos estáticos predefinidos según clasificación del modelo:

```sql
-- Insertar categorías estáticas
INSERT INTO dim_categoria (category_id, tipo_delito, categoria, descripcion, componentes) 
VALUES
(1, 'Violent', 'Delitos Violentos', 
 'Delitos que involucran violencia o amenaza directa contra personas', 
 'Murder, Rape, Robbery, Aggravated Assault'),
 
(2, 'Property', 'Delitos contra la Propiedad', 
 'Delitos que involucran robo, hurto o daño a la propiedad sin violencia directa', 
 'Burglary, Larceny, Motor Vehicle Theft'),
 
(3, 'Mixed', 'Total General', 
 'Suma de todas las categorías de delito (Index Total)', 
 'Todos los delitos violentos y contra la propiedad');

-- Verificación
SELECT * FROM dim_categoria;
```

---

##### **PASO 6: Carga de Tabla de Hechos**

Proceso de transformación principal con técnica UNPIVOT para normalizar datos:

```sql
-- Insertar hechos con transformación y cálculos
INSERT INTO fact_crimes_ny (
    time_id,
    geo_id,
    agency_id,
    category_id,
    total_delitos,
    total_violentos,
    total_propiedad,
    murder,
    rape,
    robbery,
    aggravated_assault,
    burglary,
    larceny,
    motor_vehicle_theft,
    months_reported,
    ratio_violencia,
    tasa_violentos_pct,
    tasa_propiedad_pct
)
SELECT 
    t.time_id,
    g.geo_id,
    a.agency_id,
    cat.category_id,
    
    -- Medidas según categoría
    CASE cat.tipo_delito
        WHEN 'Violent' THEN cr.violent_total
        WHEN 'Property' THEN cr.property_total
        WHEN 'Mixed' THEN cr.index_total
        ELSE 0
    END AS total_delitos,
    
    cr.violent_total AS total_violentos,
    cr.property_total AS total_propiedad,
    
    -- Delitos específicos
    cr.murder,
    cr.rape,
    cr.robbery,
    cr.aggravated_assault,
    cr.burglary,
    cr.larceny,
    cr.motor_vehicle_theft,
    
    -- Meses reportados
    COALESCE(cr.months_reported, 12) AS months_reported,
    
    -- Cálculos de tasas
    CASE 
        WHEN cr.index_total > 0 
        THEN ROUND(cr.violent_total / cr.index_total, 3)
        ELSE 0 
    END AS ratio_violencia,
    
    CASE 
        WHEN cr.index_total > 0 
        THEN ROUND((cr.violent_total / cr.index_total) * 100, 2)
        ELSE 0 
    END AS tasa_violentos_pct,
    
    CASE 
        WHEN cr.index_total > 0 
        THEN ROUND((cr.property_total / cr.index_total) * 100, 2)
        ELSE 0 
    END AS tasa_propiedad_pct

FROM crimes_raw cr
INNER JOIN dim_tiempo t ON t.year = cr.year
INNER JOIN dim_geografia g ON g.county_name = TRIM(cr.county)
INNER JOIN dim_agencia a ON a.agency_name = TRIM(cr.agency) 
                         AND a.county = TRIM(cr.county)
CROSS JOIN dim_categoria cat
WHERE cr.year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta)
  AND cr.index_total IS NOT NULL
  AND cr.index_total >= 0;

-- Actualizar log
UPDATE log_procesos_etl
SET registros_procesados = (SELECT COUNT(*) FROM fact_crimes_ny),
    estado = 'HECHOS_CARGADOS',
    fecha_fin = NOW()
WHERE proceso_id = @Proceso_ID;
```

---

##### **PASO 7: Cálculo Post-Carga - Crime Tendency por Condado**

Clasificación de tendencia criminal por condado basada en histórico. Los
umbrales (violentos > 15%, propiedad > 90%) están calibrados sobre la
distribución real del dataset (1990-2024, 62 condados): el % de delitos
violentos por condado va de ~5% a ~34% (mediana ~10%, p90 ~14.4%) y el %
de propiedad de ~66% a ~95% (mediana ~90%). Con umbrales más bajos
(violentos > 20%, propiedad > 85%, por debajo de sus medianas) sólo
Bronx/Kings/Queens quedaban como `Violence_Prone` y casi todo el resto
caía en `Property_Prone`, sin poder discriminar. Con los umbrales
actuales (≈p85-p90 de cada distribución) la clasificación queda más
balanceada: ~6 `Violence_Prone`, ~31 `Property_Prone`, ~25 `Mixed_Profile`.

```sql
-- Calcular tendencia criminal por condado
WITH county_stats AS (
    SELECT 
        g.geo_id,
        g.county_name,
        SUM(f.total_violentos) AS total_hist_violentos,
        SUM(f.total_propiedad) AS total_hist_propiedad,
        SUM(f.total_delitos) AS total_hist_delitos,
        ROUND(SUM(f.total_violentos) / NULLIF(SUM(f.total_delitos), 0) * 100, 2) AS pct_violentos,
        ROUND(SUM(f.total_propiedad) / NULLIF(SUM(f.total_delitos), 0) * 100, 2) AS pct_propiedad
    FROM fact_crimes_ny f
    JOIN dim_geografia g ON f.geo_id = g.geo_id
    GROUP BY g.geo_id, g.county_name
)
UPDATE dim_geografia g
JOIN county_stats cs ON g.geo_id = cs.geo_id
SET g.crime_tendency = CASE
    WHEN cs.pct_violentos > 15 THEN 'Violence_Prone'
    WHEN cs.pct_propiedad > 90 THEN 'Property_Prone'
    ELSE 'Mixed_Profile'
END;

-- Verificación
SELECT 
    crime_tendency,
    COUNT(*) AS total_condados
FROM dim_geografia
GROUP BY crime_tendency;
```

---

#### **Controles de Calidad y Limpieza:**

Se implementan las siguientes validaciones durante el proceso ETL:

```sql
-- ============================================================================
-- VALIDACIONES POST-CARGA
-- ============================================================================

-- 1. Verificar totales cargados
SELECT 'Registros en fact_crimes_ny' AS Validacion, 
       COUNT(*) AS Resultado 
FROM fact_crimes_ny;

-- 2. Verificar integridad referencial (hechos sin dimensión tiempo)
SELECT 'Hechos sin dimensión tiempo' AS Validacion, 
       COUNT(*) AS Resultado 
FROM fact_crimes_ny f
LEFT JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE t.time_id IS NULL;

-- 3. Verificar integridad referencial (hechos sin dimensión geografía)
SELECT 'Hechos sin dimensión geografía' AS Validacion, 
       COUNT(*) AS Resultado 
FROM fact_crimes_ny f
LEFT JOIN dim_geografia g ON f.geo_id = g.geo_id
WHERE g.geo_id IS NULL;

-- 4. Verificar integridad referencial (hechos sin dimensión agencia)
SELECT 'Hechos sin dimensión agencia' AS Validacion, 
       COUNT(*) AS Resultado 
FROM fact_crimes_ny f
LEFT JOIN dim_agencia a ON f.agency_id = a.agency_id
WHERE a.agency_id IS NULL;

-- 5. Verificar consistencia de totales (Violent + Property ≈ Index)
SELECT 'Inconsistencias en totales (diferencia > 10)' AS Validacion,
       COUNT(*) AS Resultado
FROM fact_crimes_ny
WHERE ABS((total_violentos + total_propiedad) - total_delitos) > 10;

-- 6. Verificar registros con valores negativos
SELECT 'Registros con valores negativos' AS Validacion,
       COUNT(*) AS Resultado
FROM fact_crimes_ny
WHERE total_delitos < 0 
   OR total_violentos < 0 
   OR total_propiedad < 0;

-- 7. Verificar registros duplicados en hechos
SELECT 'Registros duplicados en hechos' AS Validacion,
       COUNT(*) AS Resultado
FROM (
    SELECT time_id, geo_id, agency_id, category_id, COUNT(*) AS cnt
    FROM fact_crimes_ny
    GROUP BY time_id, geo_id, agency_id, category_id
    HAVING cnt > 1
) AS duplicados;

-- 8. Verificar rangos de tasas (deben estar entre 0 y 100)
SELECT 'Tasas fuera de rango (0-100)' AS Validacion,
       COUNT(*) AS Resultado
FROM fact_crimes_ny
WHERE tasa_violentos_pct < 0 
   OR tasa_violentos_pct > 100
   OR tasa_propiedad_pct < 0
   OR tasa_propiedad_pct > 100;

-- 9. Verificar años fuera de rango esperado
SELECT 'Años fuera de rango (1990-2024)' AS Validacion,
       COUNT(*) AS Resultado
FROM dim_tiempo
WHERE year < 1990 OR year > 2024;

-- 10. Estadísticas generales del DW
SELECT 
    'Estadísticas Generales' AS Reporte,
    (SELECT COUNT(*) FROM dim_tiempo) AS total_periodos,
    (SELECT COUNT(*) FROM dim_geografia) AS total_condados,
    (SELECT COUNT(*) FROM dim_agencia) AS total_agencias,
    (SELECT COUNT(*) FROM dim_categoria) AS total_categorias,
    (SELECT COUNT(*) FROM fact_crimes_ny) AS total_hechos,
    (SELECT SUM(total_delitos) FROM fact_crimes_ny WHERE category_id = 3) AS delitos_totales,
    (SELECT SUM(total_violentos) FROM fact_crimes_ny WHERE category_id = 3) AS delitos_violentos_totales,
    (SELECT SUM(total_propiedad) FROM fact_crimes_ny WHERE category_id = 3) AS delitos_propiedad_totales;
```

---

### 2) Actualización

Una vez finalizada la carga inicial y con el data warehouse operativo, se deben establecer las políticas y estrategias de actualización para mantener la información del DW sincronizada con los datos operacionales.

#### **Proceso ETL de Actualización**

El proceso ETL de actualización es similar al de carga inicial, pero con las siguientes diferencias:

##### **Variables de Control para Actualización:**

```sql
-- Variables de control para actualización incremental
SET @Fecha_Desde = DATE_SUB(CURDATE(), INTERVAL 3 MONTH);
SET @Fecha_Hasta = CURDATE();
SET @Proceso_ID = CONCAT('ACTUALIZACION_CRIMES_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i'));

-- Log inicio del proceso
INSERT INTO log_procesos_etl (proceso_id, tipo_proceso, estado, fecha_inicio)
VALUES (@Proceso_ID, 'ACTUALIZACION', 'INICIADO', NOW());
```

---

##### **Carga Incremental de Dimensiones:**

```sql
-- ============================================================================
-- ACTUALIZACIÓN INCREMENTAL DE DIMENSIÓN TIEMPO
-- ============================================================================

-- Solo insertar años nuevos que no existan
INSERT IGNORE INTO dim_tiempo (
    time_id, 
    year, 
    decada, 
    lustro, 
    bianual, 
    trimestre, 
    semestre,
    periodo_decade,
    periodo_lustro,
    es_decada_90,
    es_decada_00,
    es_decada_10,
    es_decada_20
)
SELECT DISTINCT
    Year AS time_id,
    Year AS year,
    FLOOR(Year/10)*10 AS decada,
    FLOOR(Year/5)*5 AS lustro,
    FLOOR(Year/2)*2 AS bianual,
    CEIL(Year/3) AS trimestre,
    CEIL(Year/6) AS semestre,
    CONCAT(FLOOR(Year/10)*10, 's') AS periodo_decade,
    CONCAT(FLOOR(Year/5)*5, '-', FLOOR(Year/5)*5 + 4) AS periodo_lustro,
    CASE WHEN FLOOR(Year/10)*10 = 1990 THEN TRUE ELSE FALSE END AS es_decada_90,
    CASE WHEN FLOOR(Year/10)*10 = 2000 THEN TRUE ELSE FALSE END AS es_decada_00,
    CASE WHEN FLOOR(Year/10)*10 = 2010 THEN TRUE ELSE FALSE END AS es_decada_10,
    CASE WHEN FLOOR(Year/10)*10 = 2020 THEN TRUE ELSE FALSE END AS es_decada_20
FROM crimes_raw
WHERE Year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta)
  AND Year NOT IN (SELECT year FROM dim_tiempo);

-- ============================================================================
-- ACTUALIZACIÓN INCREMENTAL DE DIMENSIÓN GEOGRAFÍA
-- ============================================================================

-- Solo insertar condados nuevos que no existan
INSERT IGNORE INTO dim_geografia (
    county_name, 
    region_type, 
    is_nyc, 
    crime_tendency
)
SELECT DISTINCT
    TRIM(County) AS county_name,
    CASE 
        WHEN FIND_IN_SET(TRIM(County), @NYC_Counties) > 0 
        THEN 'NYC'
        ELSE 'Non-New York City'
    END AS region_type,
    CASE 
        WHEN FIND_IN_SET(TRIM(County), @NYC_Counties) > 0 
        THEN TRUE
        ELSE FALSE
    END AS is_nyc,
    'Pending_Calculation' AS crime_tendency
FROM crimes_raw
WHERE County IS NOT NULL 
  AND TRIM(County) != ''
  AND TRIM(County) NOT IN (SELECT county_name FROM dim_geografia);

-- ============================================================================
-- ACTUALIZACIÓN INCREMENTAL DE DIMENSIÓN AGENCIA
-- ============================================================================

-- Solo insertar agencias nuevas
INSERT IGNORE INTO dim_agencia (
    agency_name, 
    county, 
    region, 
    is_nyc,
    agency_type
)
SELECT DISTINCT
    TRIM(Agency) AS agency_name,
    TRIM(County) AS county,
    Region AS region,
    CASE WHEN Region = 'New York City' THEN TRUE ELSE FALSE END AS is_nyc,
    CASE
        WHEN Agency LIKE '%City PD%' THEN 'City Police'
        WHEN Agency LIKE '%County Sheriff%' OR Agency LIKE '%SO%' THEN 'County Sheriff'
        WHEN Agency LIKE '%State Police%' THEN 'State Police'
        WHEN Agency LIKE '%Village PD%' THEN 'Village Police'
        WHEN Agency LIKE '%Town PD%' THEN 'Town Police'
        ELSE 'Other'
    END AS agency_type
FROM crimes_raw
WHERE Agency IS NOT NULL 
  AND TRIM(Agency) != ''
  AND County IS NOT NULL
  AND CONCAT(TRIM(Agency), '-', TRIM(County)) NOT IN (
      SELECT CONCAT(agency_name, '-', county) FROM dim_agencia
  );
```

---

##### **Actualización de Tabla de Hechos:**

```sql
-- ============================================================================
-- ACTUALIZACIÓN DE TABLA DE HECHOS (ESTRATEGIA: DELETE + INSERT)
-- ============================================================================

-- PASO 1: Eliminar datos del período a actualizar
DELETE f 
FROM fact_crimes_ny f
INNER JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE t.year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta);

-- PASO 2: Insertar datos actualizados del mismo período
INSERT INTO fact_crimes_ny (
    time_id,
    geo_id,
    agency_id,
    category_id,
    total_delitos,
    total_violentos,
    total_propiedad,
    murder,
    rape,
    robbery,
    aggravated_assault,
    burglary,
    larceny,
    motor_vehicle_theft,
    months_reported,
    ratio_violencia,
    tasa_violentos_pct,
    tasa_propiedad_pct
)
SELECT 
    t.time_id,
    g.geo_id,
    a.agency_id,
    cat.category_id,
    
    -- Medidas según categoría
    CASE cat.tipo_delito
        WHEN 'Violent' THEN cr.violent_total
        WHEN 'Property' THEN cr.property_total
        WHEN 'Mixed' THEN cr.index_total
        ELSE 0
    END AS total_delitos,
    
    cr.violent_total AS total_violentos,
    cr.property_total AS total_propiedad,
    
    -- Delitos específicos
    cr.murder,
    cr.rape,
    cr.robbery,
    cr.aggravated_assault,
    cr.burglary,
    cr.larceny,
    cr.motor_vehicle_theft,
    
    -- Meses reportados
    COALESCE(cr.months_reported, 12) AS months_reported,
    
    -- Cálculos de tasas
    CASE 
        WHEN cr.index_total > 0 
        THEN ROUND(cr.violent_total / cr.index_total, 3)
        ELSE 0 
    END AS ratio_violencia,
    
    CASE 
        WHEN cr.index_total > 0 
        THEN ROUND((cr.violent_total / cr.index_total) * 100, 2)
        ELSE 0 
    END AS tasa_violentos_pct,
    
    CASE 
        WHEN cr.index_total > 0 
        THEN ROUND((cr.property_total / cr.index_total) * 100, 2)
        ELSE 0 
    END AS tasa_propiedad_pct

FROM crimes_raw cr
INNER JOIN dim_tiempo t ON t.year = cr.year
INNER JOIN dim_geografia g ON g.county_name = TRIM(cr.county)
INNER JOIN dim_agencia a ON a.agency_name = TRIM(cr.agency) 
                         AND a.county = TRIM(cr.county)
CROSS JOIN dim_categoria cat
WHERE cr.year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta)
  AND cr.index_total IS NOT NULL
  AND cr.index_total >= 0;

-- PASO 3: Recalcular crime_tendency para condados actualizados
WITH county_stats AS (
    SELECT 
        g.geo_id,
        g.county_name,
        SUM(f.total_violentos) AS total_hist_violentos,
        SUM(f.total_propiedad) AS total_hist_propiedad,
        SUM(f.total_delitos) AS total_hist_delitos,
        ROUND(SUM(f.total_violentos) / NULLIF(SUM(f.total_delitos), 0) * 100, 2) AS pct_violentos,
        ROUND(SUM(f.total_propiedad) / NULLIF(SUM(f.total_delitos), 0) * 100, 2) AS pct_propiedad
    FROM fact_crimes_ny f
    JOIN dim_geografia g ON f.geo_id = g.geo_id
    GROUP BY g.geo_id, g.county_name
)
UPDATE dim_geografia g
JOIN county_stats cs ON g.geo_id = cs.geo_id
SET g.crime_tendency = CASE
    WHEN cs.pct_violentos > 15 THEN 'Violence_Prone'
    WHEN cs.pct_propiedad > 90 THEN 'Property_Prone'
    ELSE 'Mixed_Profile'
END;

-- Actualizar log
UPDATE log_procesos_etl
SET registros_procesados = (
    SELECT COUNT(*) 
    FROM fact_crimes_ny f
    JOIN dim_tiempo t ON f.time_id = t.time_id
    WHERE t.year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta)
),
estado = 'COMPLETADO',
fecha_fin = NOW(),
duracion_segundos = TIMESTAMPDIFF(SECOND, fecha_inicio, NOW())
WHERE proceso_id = @Proceso_ID;
```

---

#### **Controles y Validaciones de Actualización**

```sql
-- ============================================================================
-- VALIDACIONES POST-ACTUALIZACIÓN
-- ============================================================================

-- 1. Verificar registros actualizados
SELECT 
    'Registros actualizados' AS Validacion,
    COUNT(*) AS Resultado,
    MIN(t.year) AS año_desde,
    MAX(t.year) AS año_hasta
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE t.year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta);

-- 2. Verificar integridad referencial
SELECT 'Hechos sin dimensión válida' AS Validacion,
       COUNT(*) AS Resultado
FROM fact_crimes_ny f
LEFT JOIN dim_tiempo t ON f.time_id = t.time_id
LEFT JOIN dim_geografia g ON f.geo_id = g.geo_id
LEFT JOIN dim_agencia a ON f.agency_id = a.agency_id
WHERE t.time_id IS NULL 
   OR g.geo_id IS NULL 
   OR a.agency_id IS NULL;

-- 3. Verificar consistencia de totales
SELECT 'Inconsistencias en totales actualizados' AS Validacion,
       COUNT(*) AS Resultado
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE t.year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta)
  AND ABS((f.total_violentos + f.total_propiedad) - f.total_delitos) > 10;

-- 4. Comparar totales antes y después
SELECT 
    'Comparación de totales' AS Reporte,
    t.year AS Año,
    SUM(f.total_delitos) AS total_delitos,
    SUM(f.total_violentos) AS total_violentos,
    SUM(f.total_propiedad) AS total_propiedad
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE t.year BETWEEN YEAR(@Fecha_Desde) AND YEAR(@Fecha_Hasta)
  AND f.category_id = 3  -- Solo categoría Mixed (Total General)
GROUP BY t.year
ORDER BY t.year;

-- 5. Log de proceso completado
SELECT * 
FROM log_procesos_etl
WHERE proceso_id = @Proceso_ID;
```

---

#### **Políticas de Actualización**

##### **Frecuencia de actualización:**
- **Carga incremental mensual**: Actualizar datos de los últimos 3 meses
- **Carga anual completa**: Al inicio de cada año, validar y recalcular todo el año anterior
- **Carga ad-hoc**: Bajo demanda cuando se detecten correcciones en datos fuente

##### **Ventana de actualización:**
- **Rango flexible**: Los últimos 3 meses permiten capturar correcciones tardías
- **Estrategia DELETE+INSERT**: Garantiza que correcciones sobrescriban datos incorrectos

##### **Mantenimiento:**
- **Índices**: Reconstruir índices trimestralmente para optimizar performance
- **Estadísticas**: Actualizar estadísticas de MySQL después de cada carga mayor
- **Backup**: Realizar backup completo antes de cada actualización mayor

##### **Validación continua:**
- **Alertas automáticas**: Si las validaciones post-carga detectan > 5% de errores
- **Auditoría**: Mantener log_procesos_etl para trazabilidad completa
- **Monitoreo**: Dashboard de calidad de datos con KPIs de integridad

---

## **CONCLUSIÓN**

La aplicación de la **metodología HEFESTO** en el contexto del análisis criminal del Estado de New York ha resultado en un **data warehouse funcional y orientado al negocio** que transforma datos operacionales en información estratégica para la seguridad pública.

### **Logros principales:**

1. **Modelo dimensional robusto**: El esquema en estrella diseñado permite análisis multidimensionales complejos manteniendo simplicidad y alto rendimiento.

2. **Granularidad adecuada**: El nivel de detalle por {Año, Condado, Agencia, Categoría} balancea capacidad analítica con volumen de datos manejable.

3. **Calidad de datos garantizada**: Los procesos ETL implementados incluyen validaciones exhaustivas, controles de integridad y logging completo para auditoría.

4. **Flexibilidad temporal**: Múltiples granularidades de tiempo (década, lustro, bianual) facilitan análisis de tendencias a largo plazo.

5. **Comparabilidad regional**: La clasificación NYC vs Non-NYC permite responder a las preguntas clave sobre diferencias geográficas en criminalidad.

6. **Métricas precalculadas**: Ratios y tasas almacenadas mejoran performance en consultas frecuentes de KPIs.

7. **Actualización incremental**: Estrategia de actualización flexible que permite correcciones sin recargas completas.

### **Respuestas a preguntas de negocio:**

El DW diseñado permite responder efectivamente a las 11 preguntas operativas planteadas en el análisis de requerimientos (la pregunta original sobre variación mensual quedó fuera de alcance — ver nota en el Paso 1):

- ✅ Diferencias NYC vs no-NYC (dim_geografia.region_type)
- ✅ Crecimiento por región (fact + dim_tiempo.decada/lustro)
- ✅ Distribución violentos/propiedad (ratio_violencia, tasas_pct)
- ✅ Década con mayor criminalidad (dim_tiempo.decada + agregaciones)
- ✅ Evolución en lustros (dim_tiempo.lustro)
- ✅ Tendencia bianual de propiedad (dim_tiempo.bianual)
- ✅ Tendencias por condado (dim_geografia + series temporales)
- ✅ Proporción delitos de propiedad (tasa_propiedad_pct)
- ✅ Evolución ratio por década (combinación dim_tiempo + dim_geografia)
- ✅ Ranking de agencias (dim_agencia + agregaciones)
- ✅ Delitos específicos por año (campos murder, rape, robbery, etc.)
- ❌ Variación mensual — fuera de alcance, `dim_tiempo` no tiene granularidad mensual

### **Valor para el negocio:**

- **Toma de decisiones basada en datos**: Funcionarios pueden identificar patrones, priorizar recursos policiales y evaluar políticas públicas.
- **Análisis histórico robusto**: 35 años de datos (1990-2024) permiten identificar tendencias de largo plazo.
- **Comparaciones justas**: Separación NYC/no-NYC considera diferencias demográficas y contextuales.
- **Detección de anomalías**: Clasificación crime_tendency permite identificar condados atípicos.
- **Transparencia y rendición de cuentas**: Datos públicos procesados de manera rigurosa y auditable.

### **Evolución futura:**

El proyecto demuestra cómo una **metodología estructurada** puede guiar exitosamente el desarrollo de soluciones de Business Intelligence incluso en dominios complejos como la criminología. El resultado final es una herramienta que **responde a preguntas actuales y está preparada para evolucionar** con las necesidades futuras del análisis criminal en New York.

**Posibles extensiones:**
- Integración con datos demográficos (población, densidad, ingresos)
- Incorporación de datos geoespaciales para mapas de calor
- Análisis predictivo con machine learning
- Dashboard interactivo en Power BI/Tableau
- APIs para consultas externas
- Integración con sistemas de despacho policial en tiempo real

---

**Fecha de elaboración:** Noviembre 2025  
**Versión del documento:** 1.0  
**Metodología aplicada:** HEFESTO (Hefesto para Data Warehouse)

---
