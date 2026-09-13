# 🔍 CONSULTAS SQL PARA LAS 9 PREGUNTAS PRINCIPALES

## Base de Datos: crimes_ny_dw

---

## 📋 PREGUNTA 1
**¿Cuáles son las diferencias en índices de delitos entre NYC y condados fuera de NYC?**

### Consulta SQL:
```sql
SELECT 
    CASE 
        WHEN g.is_nyc THEN 'NYC' 
        ELSE 'Non-New York City' 
    END AS region,
    
    COUNT(DISTINCT g.county_name) AS cantidad_condados,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    ROUND(
        AVG(f.tasa_violentos_pct), 2
    ) AS tasa_promedio_violentos,
    
    ROUND(
        AVG(f.tasa_propiedad_pct), 2
    ) AS tasa_promedio_propiedad,
    
    ROUND(
        SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) / 
        COUNT(DISTINCT g.county_name), 2
    ) AS promedio_delitos_por_condado

FROM fact_crimes_ny f
JOIN dim_geografia g ON f.geo_id = g.geo_id
GROUP BY CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-New York City' END;
```

### Alternativa usando vista:
```sql
SELECT * FROM v_comparativa_nyc_vs_nonyc;
```

---

## 📋 PREGUNTA 2
**¿Qué región (NYC/noNYC) presenta mayor crecimiento en delitos violentos?**

### Consulta SQL:
```sql
WITH primeros_5_años AS (
    SELECT 
        CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END AS region,
        AVG(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS promedio_violentos_1990_1994
    FROM fact_crimes_ny f
    JOIN dim_geografia g ON f.geo_id = g.geo_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    WHERE t.year BETWEEN 1990 AND 1994
    GROUP BY CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END
),
ultimos_5_años AS (
    SELECT 
        CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END AS region,
        AVG(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS promedio_violentos_2020_2024
    FROM fact_crimes_ny f
    JOIN dim_geografia g ON f.geo_id = g.geo_id
    JOIN dim_tiempo t ON f.time_id = t.time_id
    WHERE t.year BETWEEN 2020 AND 2024
    GROUP BY CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END
)
SELECT 
    p.region,
    ROUND(p.promedio_violentos_1990_1994, 2) AS promedio_inicio,
    ROUND(u.promedio_violentos_2020_2024, 2) AS promedio_final,
    ROUND(u.promedio_violentos_2020_2024 - p.promedio_violentos_1990_1994, 2) AS diferencia_absoluta,
    ROUND(
        ((u.promedio_violentos_2020_2024 - p.promedio_violentos_1990_1994) / 
        NULLIF(p.promedio_violentos_1990_1994, 0)) * 100, 
        2
    ) AS crecimiento_porcentual,
    CASE 
        WHEN u.promedio_violentos_2020_2024 > p.promedio_violentos_1990_1994 THEN 'Crecimiento'
        WHEN u.promedio_violentos_2020_2024 < p.promedio_violentos_1990_1994 THEN 'Decrecimiento'
        ELSE 'Estable'
    END AS tendencia
FROM primeros_5_años p
JOIN ultimos_5_años u ON p.region = u.region
ORDER BY crecimiento_porcentual DESC;
```

---

## 📋 PREGUNTA 3
**¿Cómo se distribuye la proporción de delitos violentos o de propiedad entre NYC y noNYC?**

### Consulta SQL:
```sql
SELECT 
    CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END AS region,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0)) * 100,
        2
    ) AS proporcion_violentos_pct,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0)) * 100,
        2
    ) AS proporcion_propiedad_pct

FROM fact_crimes_ny f
JOIN dim_geografia g ON f.geo_id = g.geo_id
GROUP BY CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END;
```

### Versión con gráfico por año:
```sql
SELECT 
    t.year AS año,
    CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END AS region,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0)) * 100,
        2
    ) AS proporcion_violentos_pct,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0)) * 100,
        2
    ) AS proporcion_propiedad_pct

FROM fact_crimes_ny f
JOIN dim_geografia g ON f.geo_id = g.geo_id
JOIN dim_tiempo t ON f.time_id = t.time_id
GROUP BY t.year, CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END
ORDER BY t.year, region;
```

---

## 📋 PREGUNTA 4
**¿Qué década presenta los mayores índices de criminalidad?**

### Consulta SQL:
```sql
SELECT 
    t.decada,
    t.periodo_decade AS periodo,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    ROUND(AVG(f.tasa_violentos_pct), 2) AS tasa_promedio_violentos,
    
    COUNT(DISTINCT t.year) AS años_en_decada,
    
    RANK() OVER (ORDER BY SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) DESC) AS ranking

FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE f.category_id = 3
GROUP BY t.decada, t.periodo_decade
ORDER BY total_delitos DESC;
```

### Alternativa usando vista:
```sql
SELECT * FROM v_evolucion_decada ORDER BY total_delitos DESC;
```

---

## 📋 PREGUNTA 5
**¿Cuál es la evolución de los delitos violentos en lustros?**

### Consulta SQL:
```sql
SELECT 
    t.lustro,
    t.periodo_lustro,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.murder ELSE 0 END) AS homicidios,
    SUM(CASE WHEN f.category_id = 3 THEN f.rape ELSE 0 END) AS violaciones,
    SUM(CASE WHEN f.category_id = 3 THEN f.robbery ELSE 0 END) AS robos,
    SUM(CASE WHEN f.category_id = 3 THEN f.aggravated_assault ELSE 0 END) AS asaltos_agravados,
    
    ROUND(AVG(f.tasa_violentos_pct), 2) AS tasa_promedio_violentos,
    
    -- Variación respecto al lustro anterior
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) - 
    LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END)) 
        OVER (ORDER BY t.lustro) AS variacion_absoluta,
    
    ROUND(
        ((SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) - 
        LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END)) 
            OVER (ORDER BY t.lustro)) /
        NULLIF(LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END)) 
            OVER (ORDER BY t.lustro), 0)) * 100,
        2
    ) AS variacion_porcentual

FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE f.category_id = 3
GROUP BY t.lustro, t.periodo_lustro
ORDER BY t.lustro;
```

### Alternativa usando vista:
```sql
SELECT * FROM v_evolucion_lustro;
```

---

## 📋 PREGUNTA 6
**¿Qué tendencia bianual muestran los delitos contra la propiedad?**

### Consulta SQL:
```sql
SELECT 
    t.bianual AS periodo_bianual,
    CONCAT(t.bianual, '-', t.bianual + 1) AS descripcion_periodo,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.burglary ELSE 0 END) AS allanamientos,
    SUM(CASE WHEN f.category_id = 3 THEN f.larceny ELSE 0 END) AS hurtos,
    SUM(CASE WHEN f.category_id = 3 THEN f.motor_vehicle_theft ELSE 0 END) AS robo_vehiculos,
    
    ROUND(AVG(f.tasa_propiedad_pct), 2) AS tasa_promedio_propiedad,
    
    -- Variación respecto al período bianual anterior
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) - 
    LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END)) 
        OVER (ORDER BY t.bianual) AS variacion_absoluta,
    
    ROUND(
        ((SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) - 
        LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END)) 
            OVER (ORDER BY t.bianual)) /
        NULLIF(LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END)) 
            OVER (ORDER BY t.bianual), 0)) * 100,
        2
    ) AS variacion_porcentual,
    
    CASE 
        WHEN SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) > 
             LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END)) 
                OVER (ORDER BY t.bianual) 
        THEN 'Alza'
        WHEN SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) < 
             LAG(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END)) 
                OVER (ORDER BY t.bianual)
        THEN 'Baja'
        ELSE 'Estable'
    END AS tendencia

FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
WHERE f.category_id = 3
GROUP BY t.bianual
ORDER BY t.bianual;
```

### Alternativa usando vista:
```sql
SELECT * FROM v_evolucion_bianual_propiedad;
```

---

## 📋 PREGUNTA 7
**¿Qué condados presentan tendencias a la baja o a la alza en crímenes violentos específicamente?**

### Consulta SQL:
```sql
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
```

### Solo condados con tendencia a la baja:
```sql
SELECT * FROM v_tendencias_condados 
WHERE tendencia = 'Baja'
ORDER BY variacion_porcentual ASC;
```

### Solo condados con tendencia al alza:
```sql
SELECT * FROM v_tendencias_condados 
WHERE tendencia = 'Alza'
ORDER BY variacion_porcentual DESC;
```

---

## 📋 PREGUNTA 8
**¿Cuál es la proporción de delitos contra la propiedad por región?**

### Consulta SQL:
```sql
SELECT 
    CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END AS region,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.burglary ELSE 0 END) AS allanamientos,
    SUM(CASE WHEN f.category_id = 3 THEN f.larceny ELSE 0 END) AS hurtos,
    SUM(CASE WHEN f.category_id = 3 THEN f.motor_vehicle_theft ELSE 0 END) AS robo_vehiculos,
    
    -- Proporción de propiedad sobre total
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0)) * 100,
        2
    ) AS proporcion_propiedad_pct,
    
    -- Distribución interna de delitos de propiedad
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.burglary ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END), 0)) * 100,
        2
    ) AS pct_allanamientos,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.larceny ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END), 0)) * 100,
        2
    ) AS pct_hurtos,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.motor_vehicle_theft ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END), 0)) * 100,
        2
    ) AS pct_robo_vehiculos

FROM fact_crimes_ny f
JOIN dim_geografia g ON f.geo_id = g.geo_id
GROUP BY CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END;
```

---

## 📋 PREGUNTA 9
**¿Cómo evoluciona la proporción delito violento/propiedad por década en NYC vs noNYC?**

### Consulta SQL:
```sql
SELECT 
    t.decada,
    t.periodo_decade AS periodo,
    CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END AS region,
    
    SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END) AS total_delitos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) AS total_violentos,
    SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) AS total_propiedad,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0)) * 100,
        2
    ) AS proporcion_violentos_pct,
    
    ROUND(
        (SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_delitos ELSE 0 END), 0)) * 100,
        2
    ) AS proporcion_propiedad_pct,
    
    -- Ratio violentos/propiedad
    ROUND(
        SUM(CASE WHEN f.category_id = 3 THEN f.total_violentos ELSE 0 END) / 
        NULLIF(SUM(CASE WHEN f.category_id = 3 THEN f.total_propiedad ELSE 0 END), 0),
        3
    ) AS ratio_violentos_propiedad

FROM fact_crimes_ny f
JOIN dim_tiempo t ON f.time_id = t.time_id
JOIN dim_geografia g ON f.geo_id = g.geo_id
WHERE f.category_id = 3
GROUP BY t.decada, t.periodo_decade, CASE WHEN g.is_nyc THEN 'NYC' ELSE 'Non-NYC' END
ORDER BY t.decada, region;
```

### Alternativa usando vista:
```sql
SELECT * FROM v_proporcion_por_decada_region;
```

### Versión pivoteada para comparación directa:
```sql
SELECT 
    decada,
    periodo,
    MAX(CASE WHEN region = 'NYC' THEN proporcion_violentos_pct END) AS violentos_nyc_pct,
    MAX(CASE WHEN region = 'Non-NYC' THEN proporcion_violentos_pct END) AS violentos_nonyc_pct,
    MAX(CASE WHEN region = 'NYC' THEN proporcion_propiedad_pct END) AS propiedad_nyc_pct,
    MAX(CASE WHEN region = 'Non-NYC' THEN proporcion_propiedad_pct END) AS propiedad_nonyc_pct,
    
    -- Diferencia entre regiones
    MAX(CASE WHEN region = 'NYC' THEN proporcion_violentos_pct END) - 
    MAX(CASE WHEN region = 'Non-NYC' THEN proporcion_violentos_pct END) AS diferencia_violentos,
    
    MAX(CASE WHEN region = 'NYC' THEN proporcion_propiedad_pct END) - 
    MAX(CASE WHEN region = 'Non-NYC' THEN proporcion_propiedad_pct END) AS diferencia_propiedad

FROM v_proporcion_por_decada_region
GROUP BY decada, periodo
ORDER BY decada;
```

---

## 📊 CONSULTAS ADICIONALES ÚTILES

### Top 10 Condados con más delitos totales:
```sql
SELECT * FROM v_top_condados LIMIT 10;
```

### Top 10 Agencias con más delitos:
```sql
SELECT * FROM v_top_agencias LIMIT 10;
```

### KPIs Globales:
```sql
SELECT * FROM v_kpi_globales;
```

### Evolución anual completa:
```sql
SELECT * FROM v_evolucion_anual;
```

### Variación interanual:
```sql
SELECT * FROM v_variacion_interanual WHERE año >= 2010;
```

---

## 📝 NOTAS

- Todas las consultas usan `category_id = 3` (Mixed) para obtener totales generales
- Las vistas simplifican el acceso a los datos más utilizados
- Los porcentajes están redondeados a 2 decimales
- Se usa `NULLIF` para evitar divisiones por cero
- Las funciones de ventana (`LAG`, `RANK`, `OVER`) permiten análisis comparativos

---

**Base de datos:** crimes_ny_dw  
**Fecha:** Noviembre 2025  
**Autor:** Equipo BD2 - UCC
