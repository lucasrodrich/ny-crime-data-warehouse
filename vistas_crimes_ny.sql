-- ============================================================================
-- VISTAS ANALÍTICAS - DATA WAREHOUSE CRIMES NY
-- Base de Datos II - Metodología HEFESTO
-- Universidad Católica de Córdoba
-- ============================================================================
-- Descripción: Vistas SQL optimizadas para análisis y visualización de datos
--              de delitos del Estado de New York (1990-2024)
-- Base de datos: crimes_ny_dw
-- SGBD: MySQL 8.0+
-- ============================================================================

USE crimes_ny_dw;

-- ============================================================================
-- VISTA 1: KPI GLOBALES (Para tarjetas principales del dashboard)
-- ============================================================================

CREATE OR REPLACE VIEW v_kpi_globales AS
SELECT 
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos_reportados,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_delitos_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_delitos_propiedad,
    
    ROUND(
        SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0) * 100, 
        2
    ) AS tasa_violentos_pct,
    
    ROUND(
        SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0) * 100, 
        2
    ) AS tasa_propiedad_pct,
    
    COUNT(DISTINCT t.year) AS total_años_registrados,
    COUNT(DISTINCT g.county_name) AS total_condados,
    COUNT(DISTINCT a.agency_name) AS total_agencias,
    
    MIN(t.year) AS año_inicio,
    MAX(t.year) AS año_fin
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
JOIN dim_geografia g ON f.geo_id = g.geo_id
JOIN dim_agencia a ON f.agency_id = a.agency_id;

-- ============================================================================
-- VISTA 2: EVOLUCIÓN ANUAL (Para gráfico de líneas temporal)
-- ============================================================================

CREATE OR REPLACE VIEW v_evolucion_anual AS
SELECT 
    t.year AS año,
    t.decada,
    t.periodo_decade AS periodo_decada,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS delitos_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS delitos_propiedad,
    SUM(CASE WHEN f.category_id = 3 THEN f.murder ELSE 0 END) AS homicidios,
    SUM(CASE WHEN f.category_id = 3 THEN f.rape ELSE 0 END) AS violaciones,
    SUM(CASE WHEN f.category_id = 3 THEN f.robbery ELSE 0 END) AS robos,
    SUM(CASE WHEN f.category_id = 3 THEN f.aggravated_assault ELSE 0 END) AS asaltos_agravados,
    SUM(CASE WHEN f.category_id = 3 THEN f.burglary ELSE 0 END) AS allanamientos,
    SUM(CASE WHEN f.category_id = 3 THEN f.larceny ELSE 0 END) AS hurtos,
    SUM(CASE WHEN f.category_id = 3 THEN f.motor_vehicle_theft ELSE 0 END) AS robo_vehiculos
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.year, t.decada, t.periodo_decade
ORDER BY t.year;

-- ============================================================================
-- VISTA 3: EVOLUCIÓN POR DÉCADA (Para análisis decenal)
-- ============================================================================

CREATE OR REPLACE VIEW v_evolucion_decada AS
SELECT 
    t.decada,
    t.periodo_decade AS periodo,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS delitos_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS delitos_propiedad,
    
    ROUND(AVG(f.tasa_violentos_pct), 2) AS tasa_promedio_violentos,
    ROUND(AVG(f.tasa_propiedad_pct), 2) AS tasa_promedio_propiedad,
    
    COUNT(DISTINCT t.year) AS años_en_decada,
    COUNT(DISTINCT g.county_name) AS condados_reportando
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
JOIN dim_geografia g ON f.geo_id = g.geo_id
WHERE f.category_id = 3
GROUP BY t.decada, t.periodo_decade
ORDER BY t.decada;

-- ============================================================================
-- VISTA 4: TOP CONDADOS (Para gráfico de barras)
-- ============================================================================

CREATE OR REPLACE VIEW v_top_condados AS
SELECT 
    g.county_name AS condado,
    g.region_type AS region,
    g.is_nyc AS es_nyc,
    g.crime_tendency AS tendencia_criminal,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    ROUND(AVG(f.tasa_violentos_pct), 2) AS tasa_promedio_violentos,
    ROUND(AVG(f.tasa_propiedad_pct), 2) AS tasa_promedio_propiedad,
    
    RANK() OVER (ORDER BY SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) DESC) AS ranking_total,
    RANK() OVER (ORDER BY SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) DESC) AS ranking_violentos
    
FROM fact_crimes_ny f
JOIN dim_geografia g ON f.geo_id = g.geo_id
GROUP BY g.county_name, g.region_type, g.is_nyc, g.crime_tendency
ORDER BY total_delitos DESC;

-- ============================================================================
-- VISTA 5: COMPARATIVA NYC VS NO-NYC (Para responder preguntas clave)
-- ============================================================================

CREATE OR REPLACE VIEW v_comparativa_nyc_vs_nonyc AS
SELECT 
    t.year AS año,
    t.decada,
    
    -- NYC
    SUM(CASE WHEN g.is_nyc = TRUE AND f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos_nyc,
    SUM(CASE WHEN g.is_nyc = TRUE AND f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS violentos_nyc,
    SUM(CASE WHEN g.is_nyc = TRUE AND f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS propiedad_nyc,
    
    -- Non-NYC
    SUM(CASE WHEN g.is_nyc = FALSE AND f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos_nonyc,
    SUM(CASE WHEN g.is_nyc = FALSE AND f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS violentos_nonyc,
    SUM(CASE WHEN g.is_nyc = FALSE AND f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS propiedad_nonyc,
    
    -- Ratios
    ROUND(
        SUM(CASE WHEN g.is_nyc = TRUE AND f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN g.is_nyc = TRUE AND f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0) * 100,
        2
    ) AS tasa_violentos_nyc,
    
    ROUND(
        SUM(CASE WHEN g.is_nyc = FALSE AND f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN g.is_nyc = FALSE AND f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0) * 100,
        2
    ) AS tasa_violentos_nonyc
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
JOIN dim_geografia g ON f.geo_id = g.geo_id
GROUP BY t.year, t.decada
ORDER BY t.year;

-- ============================================================================
-- VISTA 6: DETALLE POR CONDADO CON TODAS LAS MÉTRICAS
-- ============================================================================

CREATE OR REPLACE VIEW v_detalle_condados AS
SELECT 
    g.county_name AS condado,
    g.region_type AS region,
    g.is_nyc AS es_nyc,
    g.crime_tendency AS tendencia_criminal,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    -- Delitos violentos específicos
    SUM(CASE WHEN f.category_id = 3 THEN f.murder ELSE 0 END) AS homicidios,
    SUM(CASE WHEN f.category_id = 3 THEN f.rape ELSE 0 END) AS violaciones,
    SUM(CASE WHEN f.category_id = 3 THEN f.robbery ELSE 0 END) AS robos,
    SUM(CASE WHEN f.category_id = 3 THEN f.aggravated_assault ELSE 0 END) AS asaltos_agravados,
    
    -- Delitos de propiedad específicos
    SUM(CASE WHEN f.category_id = 3 THEN f.burglary ELSE 0 END) AS allanamientos,
    SUM(CASE WHEN f.category_id = 3 THEN f.larceny ELSE 0 END) AS hurtos,
    SUM(CASE WHEN f.category_id = 3 THEN f.motor_vehicle_theft ELSE 0 END) AS robo_vehiculos,
    
    -- Tasas y ratios
    ROUND(AVG(f.ratio_violencia), 3) AS ratio_promedio_violencia,
    ROUND(AVG(f.tasa_violentos_pct), 2) AS tasa_promedio_violentos,
    ROUND(AVG(f.tasa_propiedad_pct), 2) AS tasa_promedio_propiedad,

    -- Porcentaje sobre el total estatal (window function en vez de subquery
    -- correlacionada: se calcula el total estatal una sola vez por consulta
    -- en lugar de re-escanear fact_crimes_ny por cada condado del GROUP BY)
    ROUND(
        SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) /
        NULLIF(SUM(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END)) OVER (), 0) * 100,
        2
    ) AS porcentaje_del_total_estatal
    
FROM fact_crimes_ny f
JOIN dim_geografia g ON f.geo_id = g.geo_id
GROUP BY g.county_name, g.region_type, g.is_nyc, g.crime_tendency
ORDER BY total_delitos DESC;

-- ============================================================================
-- VISTA 7: TOP AGENCIAS POLICIALES
-- ============================================================================

CREATE OR REPLACE VIEW v_top_agencias AS
SELECT 
    a.agency_name AS agencia,
    a.county AS condado,
    a.region AS region,
    a.agency_type AS tipo_agencia,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    ROUND(AVG(f.tasa_violentos_pct), 2) AS tasa_promedio_violentos,
    
    COUNT(DISTINCT t.year) AS años_reportando,
    
    RANK() OVER (ORDER BY SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) DESC) AS ranking
    
FROM fact_crimes_ny f
JOIN dim_agencia a ON f.agency_id = a.agency_id
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY a.agency_name, a.county, a.region, a.agency_type
ORDER BY total_delitos DESC;

-- ============================================================================
-- VISTA 8: EVOLUCIÓN POR LUSTRO (Para análisis de pregunta 5)
-- ============================================================================

CREATE OR REPLACE VIEW v_evolucion_lustro AS
SELECT 
    t.lustro,
    t.periodo_lustro,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS delitos_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS delitos_propiedad,
    
    ROUND(AVG(f.tasa_violentos_pct), 2) AS tasa_promedio_violentos,
    ROUND(AVG(f.tasa_propiedad_pct), 2) AS tasa_promedio_propiedad
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE f.category_id = 3
GROUP BY t.lustro, t.periodo_lustro
ORDER BY t.lustro;

-- ============================================================================
-- VISTA 9: EVOLUCIÓN BIANUAL DE DELITOS DE PROPIEDAD (Para pregunta 6)
-- ============================================================================

CREATE OR REPLACE VIEW v_evolucion_bianual_propiedad AS
SELECT 
    t.bianual AS periodo_bianual,
    CONCAT(t.bianual, '-', t.bianual + 1) AS descripcion_periodo,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_delitos_propiedad,
    SUM(CASE WHEN f.category_id = 3 THEN f.burglary ELSE 0 END) AS allanamientos,
    SUM(CASE WHEN f.category_id = 3 THEN f.larceny ELSE 0 END) AS hurtos,
    SUM(CASE WHEN f.category_id = 3 THEN f.motor_vehicle_theft ELSE 0 END) AS robo_vehiculos,
    
    ROUND(AVG(f.tasa_propiedad_pct), 2) AS tasa_promedio_propiedad
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE f.category_id = 3
GROUP BY t.bianual
ORDER BY t.bianual;

-- ============================================================================
-- VISTA 10: TENDENCIAS POR CONDADO (Para pregunta 7)
-- ============================================================================

CREATE OR REPLACE VIEW v_tendencias_condados AS
WITH primeros_5_años AS (
    SELECT 
        g.county_name,
        g.region_type,
        AVG(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS promedio_violentos_inicio
    FROM fact_crimes_ny f
    JOIN dim_geografia g ON f.geo_id = g.geo_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    WHERE t.year BETWEEN 1990 AND 1994
    GROUP BY g.county_name, g.region_type
),
ultimos_5_años AS (
    SELECT 
        g.county_name,
        g.region_type,
        AVG(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS promedio_violentos_final
    FROM fact_crimes_ny f
    JOIN dim_geografia g ON f.geo_id = g.geo_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    WHERE t.year BETWEEN 2020 AND 2024
    GROUP BY g.county_name, g.region_type
)
SELECT 
    p.county_name AS condado,
    p.region_type AS region,
    ROUND(p.promedio_violentos_inicio, 2) AS promedio_1990_1994,
    ROUND(u.promedio_violentos_final, 2) AS promedio_2020_2024,
    ROUND(u.promedio_violentos_final - p.promedio_violentos_inicio, 2) AS diferencia_absoluta,
    ROUND(
        ((u.promedio_violentos_final - p.promedio_violentos_inicio) / 
        NULLIF(p.promedio_violentos_inicio, 0)) * 100,
        2
    ) AS variacion_porcentual,
    CASE 
        WHEN u.promedio_violentos_final > p.promedio_violentos_inicio THEN 'Alza'
        WHEN u.promedio_violentos_final < p.promedio_violentos_inicio THEN 'Baja'
        ELSE 'Estable'
    END AS tendencia
FROM primeros_5_años p
JOIN ultimos_5_años u ON p.county_name = u.county_name
ORDER BY variacion_porcentual DESC;

-- ============================================================================
-- VISTA 11: VARIACIÓN INTERANUAL (Para análisis de crecimiento)
-- ============================================================================

CREATE OR REPLACE VIEW v_variacion_interanual AS
WITH delitos_anuales AS (
    SELECT 
        t.year,
        SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_año,
        SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS violentos_año,
        SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS propiedad_año
    FROM fact_crimes_ny f
    JOIN dim_tiempo t ON f.time_id = t.time_id
    GROUP BY t.year
)
SELECT 
    year AS año,
    total_año AS total_delitos,
    violentos_año AS delitos_violentos,
    propiedad_año AS delitos_propiedad,
    
    LAG(total_año) OVER (ORDER BY year) AS total_año_anterior,
    
    total_año - LAG(total_año) OVER (ORDER BY year) AS variacion_absoluta,
    
    ROUND(
        ((total_año - LAG(total_año) OVER (ORDER BY year)) / 
        NULLIF(LAG(total_año) OVER (ORDER BY year), 0)) * 100,
        2
    ) AS variacion_porcentual_total,
    
    ROUND(
        ((violentos_año - LAG(violentos_año) OVER (ORDER BY year)) / 
        NULLIF(LAG(violentos_año) OVER (ORDER BY year), 0)) * 100,
        2
    ) AS variacion_porcentual_violentos
    
FROM delitos_anuales
ORDER BY year;

-- ============================================================================
-- VISTA 12: PROPORCIÓN VIOLENTOS/PROPIEDAD POR DÉCADA Y REGIÓN (Pregunta 9)
-- ============================================================================

CREATE OR REPLACE VIEW v_proporcion_por_decada_region AS
SELECT 
    t.decada,
    t.periodo_decade AS periodo,
    
    CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END AS region,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    ROUND(
        SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0) * 100,
        2
    ) AS proporcion_violentos_pct,
    
    ROUND(
        SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0) * 100,
        2
    ) AS proporcion_propiedad_pct
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
JOIN dim_geografia g ON f.geo_id = g.geo_id
GROUP BY t.decada, t.periodo_decade, CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END
ORDER BY t.decada, region;

-- ============================================================================
-- VISTA 13: RANKING DE DELITOS ESPECÍFICOS POR AÑO (Para pregunta 11)
-- ============================================================================

CREATE OR REPLACE VIEW v_ranking_delitos_especificos AS
SELECT 
    t.year AS año,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.murder ELSE 0 END) AS homicidios,
    SUM(CASE WHEN f.category_id = 3 THEN f.rape ELSE 0 END) AS violaciones,
    SUM(CASE WHEN f.category_id = 3 THEN f.robbery ELSE 0 END) AS robos,
    SUM(CASE WHEN f.category_id = 3 THEN f.aggravated_assault ELSE 0 END) AS asaltos_agravados,
    SUM(CASE WHEN f.category_id = 3 THEN f.burglary ELSE 0 END) AS allanamientos,
    SUM(CASE WHEN f.category_id = 3 THEN f.larceny ELSE 0 END) AS hurtos,
    SUM(CASE WHEN f.category_id = 3 THEN f.motor_vehicle_theft ELSE 0 END) AS robo_vehiculos,
    
    -- Variación respecto al año anterior
    ROUND(
        ((SUM(CASE WHEN f.category_id = 3 THEN f.murder ELSE 0 END) - 
          LAG(SUM(CASE WHEN f.category_id = 3 THEN f.murder ELSE 0 END)) OVER (ORDER BY t.year)) /
        NULLIF(LAG(SUM(CASE WHEN f.category_id = 3 THEN f.murder ELSE 0 END)) OVER (ORDER BY t.year), 0)) * 100,
        2
    ) AS var_pct_homicidios,
    
    ROUND(
        ((SUM(CASE WHEN f.category_id = 3 THEN f.robbery ELSE 0 END) - 
          LAG(SUM(CASE WHEN f.category_id = 3 THEN f.robbery ELSE 0 END)) OVER (ORDER BY t.year)) /
        NULLIF(LAG(SUM(CASE WHEN f.category_id = 3 THEN f.robbery ELSE 0 END)) OVER (ORDER BY t.year), 0)) * 100,
        2
    ) AS var_pct_robos
    
FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.year
ORDER BY t.year;

-- ============================================================================
-- VERIFICAR QUE LAS VISTAS SE CREARON
-- ============================================================================

SHOW FULL TABLES WHERE Table_type = 'VIEW';

SELECT 
    TABLE_NAME AS Vista,
    TABLE_TYPE AS Tipo
FROM information_schema.TABLES
WHERE TABLE_SCHEMA = 'crimes_ny_dw'
  AND TABLE_TYPE = 'VIEW'
ORDER BY TABLE_NAME;

-- ============================================================================
-- EJEMPLOS DE USO DE LAS VISTAS
-- ============================================================================

-- Ejemplo 1: Ver KPIs globales
-- SELECT * FROM v_kpi_globales;

-- Ejemplo 2: Ver evolución anual
-- SELECT * FROM v_evolucion_anual WHERE año >= 2010;

-- Ejemplo 3: Top 10 condados con más delitos
-- SELECT * FROM v_top_condados LIMIT 10;

-- Ejemplo 4: Comparativa NYC vs Non-NYC en la última década
-- SELECT * FROM v_comparativa_nyc_vs_nonyc WHERE año >= 2014;

-- Ejemplo 5: Ver tendencias de condados (alza/baja)
-- SELECT * FROM v_tendencias_condados WHERE tendencia = 'Baja';

-- ============================================================================
-- SCRIPT COMPLETADO
-- ============================================================================

SELECT '✅ 13 vistas analíticas creadas exitosamente' AS Resultado;
