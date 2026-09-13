-- ============================================================================
-- SCRIPT DE CREACIÓN DE TABLAS - DATA WAREHOUSE CRIMES NY
-- Base de Datos II - Metodología HEFESTO
-- Universidad Católica de Córdoba
-- ============================================================================
-- Descripción: Script para crear el esquema completo del Data Warehouse
--              de análisis de delitos del Estado de New York (1990-2024)
-- Modelo: Esquema en Estrella (Star Schema)
-- SGBD: MySQL 8.0+
-- ============================================================================

-- Crear base de datos
DROP DATABASE IF EXISTS crimes_ny_dw;
CREATE DATABASE crimes_ny_dw CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE crimes_ny_dw;

-- ============================================================================
-- TABLA 1: DIMENSIÓN TIEMPO
-- ============================================================================

CREATE TABLE dim_tiempo (
    time_id INT PRIMARY KEY COMMENT 'PK - Año como identificador único',
    year INT NOT NULL COMMENT 'Año (1990-2024)',
    decada INT NOT NULL COMMENT 'Década (1990, 2000, 2010, 2020)',
    lustro INT NOT NULL COMMENT 'Lustro (1990, 1995, 2000, 2005...)',
    bianual INT NOT NULL COMMENT 'Período bianual (1990, 1992, 1994...)',
    trimestre INT COMMENT 'Trimestre del año (1-4)',
    semestre INT COMMENT 'Semestre del año (1-2)',
    periodo_decade VARCHAR(20) COMMENT 'Descripción de década (ej: "1990s")',
    periodo_lustro VARCHAR(20) COMMENT 'Descripción de lustro (ej: "1990-1994")',
    es_decada_90 BOOLEAN DEFAULT FALSE COMMENT 'Flag para década de los 90',
    es_decada_00 BOOLEAN DEFAULT FALSE COMMENT 'Flag para década del 2000',
    es_decada_10 BOOLEAN DEFAULT FALSE COMMENT 'Flag para década del 2010',
    es_decada_20 BOOLEAN DEFAULT FALSE COMMENT 'Flag para década del 2020',
    
    INDEX idx_year (year),
    INDEX idx_decada (decada),
    INDEX idx_lustro (lustro)
) ENGINE=InnoDB COMMENT='Dimensión temporal con múltiples granularidades';

-- ============================================================================
-- TABLA 2: DIMENSIÓN GEOGRAFÍA
-- ============================================================================

CREATE TABLE dim_geografia (
    geo_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK - Identificador único de geografía',
    county_name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Nombre del condado',
    region_type VARCHAR(50) NOT NULL COMMENT 'Tipo de región: NYC o Non-New York City',
    is_nyc BOOLEAN DEFAULT FALSE COMMENT 'Flag: TRUE si es condado de NYC',
    crime_tendency VARCHAR(50) COMMENT 'Tendencia criminal: Violence_Prone, Property_Prone, Mixed_Profile',
    latitude DECIMAL(10, 7) COMMENT 'Latitud del condado (opcional)',
    longitude DECIMAL(10, 7) COMMENT 'Longitud del condado (opcional)',
    population INT COMMENT 'Población del condado (dato externo opcional)',
    area_sq_miles DECIMAL(10, 2) COMMENT 'Área en millas cuadradas (dato externo opcional)',
    
    INDEX idx_region (region_type),
    INDEX idx_is_nyc (is_nyc),
    INDEX idx_county_name (county_name),
    INDEX idx_crime_tendency (crime_tendency)
) ENGINE=InnoDB COMMENT='Dimensión geográfica con clasificación NYC/noNYC';

-- ============================================================================
-- TABLA 3: DIMENSIÓN AGENCIA POLICIAL
-- ============================================================================

CREATE TABLE dim_agencia (
    agency_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK - Identificador único de agencia',
    agency_name VARCHAR(200) NOT NULL COMMENT 'Nombre de la agencia policial',
    county VARCHAR(100) NOT NULL COMMENT 'Condado al que pertenece',
    region VARCHAR(50) NOT NULL COMMENT 'Región: NYC o Non-New York City',
    is_nyc BOOLEAN DEFAULT FALSE COMMENT 'Flag: TRUE si pertenece a NYC',
    agency_type VARCHAR(50) COMMENT 'Tipo: City Police, County Sheriff, State Police, etc.',
    
    UNIQUE KEY unique_agency_county (agency_name, county),
    INDEX idx_county (county),
    INDEX idx_region (region),
    INDEX idx_agency_type (agency_type),
    INDEX idx_agency_name (agency_name)
) ENGINE=InnoDB COMMENT='Dimensión de agencias policiales';

-- ============================================================================
-- TABLA 4: DIMENSIÓN CATEGORÍA DE DELITO
-- ============================================================================

CREATE TABLE dim_categoria (
    category_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK - Identificador único de categoría',
    tipo_delito VARCHAR(50) NOT NULL UNIQUE COMMENT 'Tipo: Violent, Property, Mixed',
    categoria VARCHAR(100) NOT NULL COMMENT 'Nombre descriptivo de la categoría',
    descripcion TEXT COMMENT 'Descripción detallada de la categoría',
    componentes TEXT COMMENT 'Lista de delitos que componen la categoría',
    
    INDEX idx_tipo (tipo_delito)
) ENGINE=InnoDB COMMENT='Dimensión de categorías de delitos';

-- Insertar datos maestros de categorías
INSERT INTO dim_categoria (category_id, tipo_delito, categoria, descripcion, componentes) VALUES
(1, 'Violent', 'Delitos Violentos', 
 'Delitos que involucran violencia o amenaza directa contra personas', 
 'Murder, Rape, Robbery, Aggravated Assault'),
 
(2, 'Property', 'Delitos contra la Propiedad', 
 'Delitos que involucran robo, hurto o daño a la propiedad sin violencia directa', 
 'Burglary, Larceny, Motor Vehicle Theft'),
 
(3, 'Mixed', 'Total General', 
 'Suma de todas las categorías de delito (Index Total)', 
 'Todos los delitos violentos y contra la propiedad');

-- ============================================================================
-- TABLA 5: TABLA DE HECHOS - DELITOS
-- ============================================================================

CREATE TABLE fact_crimes_ny (
    fact_id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK - Identificador único del hecho',
    time_id INT NOT NULL COMMENT 'FK - Referencia a dim_tiempo',
    geo_id INT NOT NULL COMMENT 'FK - Referencia a dim_geografia',
    agency_id INT NOT NULL COMMENT 'FK - Referencia a dim_agencia',
    category_id INT NOT NULL COMMENT 'FK - Referencia a dim_categoria',
    
    -- MEDIDAS PRINCIPALES
    total_delitos INT DEFAULT 0 COMMENT 'Total de delitos reportados (Index Total)',
    total_violentos INT DEFAULT 0 COMMENT 'Total de delitos violentos',
    total_propiedad INT DEFAULT 0 COMMENT 'Total de delitos contra la propiedad',
    
    -- DELITOS VIOLENTOS ESPECÍFICOS
    murder INT DEFAULT 0 COMMENT 'Homicidios',
    rape INT DEFAULT 0 COMMENT 'Violaciones',
    robbery INT DEFAULT 0 COMMENT 'Robos con violencia',
    aggravated_assault INT DEFAULT 0 COMMENT 'Asaltos agravados',
    
    -- DELITOS DE PROPIEDAD ESPECÍFICOS
    burglary INT DEFAULT 0 COMMENT 'Allanamientos',
    larceny INT DEFAULT 0 COMMENT 'Hurtos',
    motor_vehicle_theft INT DEFAULT 0 COMMENT 'Robo de vehículos motorizados',
    
    -- MÉTRICAS CALCULADAS
    months_reported INT DEFAULT 12 COMMENT 'Cantidad de meses reportados en el año',
    ratio_violencia DECIMAL(5,3) DEFAULT 0 COMMENT 'Ratio: Violentos / Total (0-1)',
    tasa_violentos_pct DECIMAL(5,2) DEFAULT 0 COMMENT 'Porcentaje de delitos violentos',
    tasa_propiedad_pct DECIMAL(5,2) DEFAULT 0 COMMENT 'Porcentaje de delitos de propiedad',
    
    -- CONTROL
    fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de carga del registro',
    
    -- FOREIGN KEYS
    FOREIGN KEY (time_id) REFERENCES dim_tiempo(time_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (geo_id) REFERENCES dim_geografia(geo_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (agency_id) REFERENCES dim_agencia(agency_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (category_id) REFERENCES dim_categoria(category_id) ON DELETE RESTRICT ON UPDATE CASCADE,
    
    -- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
    INDEX idx_time (time_id),
    INDEX idx_geo (geo_id),
    INDEX idx_agency (agency_id),
    INDEX idx_category (category_id),
    INDEX idx_time_geo (time_id, geo_id),
    INDEX idx_time_category (time_id, category_id),
    INDEX idx_geo_category (geo_id, category_id),
    INDEX idx_composite (time_id, geo_id, agency_id, category_id)
) ENGINE=InnoDB COMMENT='Tabla de hechos con medidas de delitos';

-- ============================================================================
-- TABLA 6: TABLA AUXILIAR - DATOS CRUDOS (RAW)
-- ============================================================================

CREATE TABLE crimes_raw (
    raw_id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK - Identificador único del registro raw',
    county VARCHAR(100) COMMENT 'Condado',
    agency VARCHAR(200) COMMENT 'Agencia policial',
    year INT COMMENT 'Año del reporte',
    months_reported INT COMMENT 'Meses reportados',
    index_total INT COMMENT 'Total de delitos (Index Total)',
    violent_total INT COMMENT 'Total de delitos violentos',
    murder INT COMMENT 'Homicidios',
    rape INT COMMENT 'Violaciones',
    robbery INT COMMENT 'Robos',
    aggravated_assault INT COMMENT 'Asaltos agravados',
    property_total INT COMMENT 'Total delitos de propiedad',
    burglary INT COMMENT 'Allanamientos',
    larceny INT COMMENT 'Hurtos',
    motor_vehicle_theft INT COMMENT 'Robo de vehículos',
    region VARCHAR(50) COMMENT 'Región (NYC o Non-NYC)',
    fecha_carga TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT 'Fecha de carga',
    
    INDEX idx_year (year),
    INDEX idx_county (county),
    INDEX idx_agency (agency),
    INDEX idx_region (region)
) ENGINE=InnoDB COMMENT='Tabla auxiliar con datos crudos del CSV';

-- ============================================================================
-- TABLA 7: LOG DE PROCESOS ETL
-- ============================================================================

CREATE TABLE log_procesos_etl (
    log_id INT AUTO_INCREMENT PRIMARY KEY COMMENT 'PK - Identificador único del log',
    proceso_id VARCHAR(100) NOT NULL COMMENT 'Identificador único del proceso ETL',
    tipo_proceso VARCHAR(50) COMMENT 'Tipo: CARGA_INICIAL, ACTUALIZACION, VALIDACION',
    estado VARCHAR(50) COMMENT 'Estado: INICIADO, COMPLETADO, ERROR',
    mensaje TEXT COMMENT 'Mensaje descriptivo o de error',
    registros_procesados INT COMMENT 'Cantidad de registros procesados',
    fecha_inicio TIMESTAMP NULL COMMENT 'Fecha y hora de inicio del proceso',
    fecha_fin TIMESTAMP NULL COMMENT 'Fecha y hora de fin del proceso',
    duracion_segundos INT COMMENT 'Duración del proceso en segundos',
    
    INDEX idx_proceso_id (proceso_id),
    INDEX idx_tipo_proceso (tipo_proceso),
    INDEX idx_estado (estado),
    INDEX idx_fecha_inicio (fecha_inicio)
) ENGINE=InnoDB COMMENT='Log de auditoría de procesos ETL';

-- ============================================================================
-- VERIFICACIÓN DE CREACIÓN DE TABLAS
-- ============================================================================

SHOW TABLES;

SELECT 
    TABLE_NAME AS Tabla,
    TABLE_TYPE AS Tipo,
    ENGINE AS Motor,
    TABLE_ROWS AS Filas_Aprox,
    ROUND(((DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024), 2) AS 'Tamaño_MB',
    TABLE_COLLATION AS Colacion,
    TABLE_COMMENT AS Comentario
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'crimes_ny_dw'
ORDER BY TABLE_NAME;

-- ============================================================================
-- SCRIPT COMPLETADO
-- ============================================================================

SELECT 'Base de datos crimes_ny_dw creada exitosamente' AS Resultado;
SELECT 'Total de tablas creadas: 7' AS Info;
SELECT '  - 4 Tablas de dimensiones (dim_tiempo, dim_geografia, dim_agencia, dim_categoria)' AS Info;
SELECT '  - 1 Tabla de hechos (fact_crimes_ny)' AS Info;
SELECT '  - 2 Tablas auxiliares (crimes_raw, log_procesos_etl)' AS Info;
