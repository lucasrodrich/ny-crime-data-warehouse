# 📊 RESUMEN EJECUTIVO - DATA WAREHOUSE CRIMES NY

## Universidad Católica de Córdoba - Base de Datos II

---

## 🎯 OBJETIVO DEL PROYECTO

Diseñar e implementar un **Data Warehouse** para el análisis de delitos del Estado de New York (1990-2024) siguiendo la **metodología HEFESTO**, replicando la estructura y calidad del proyecto COVID-19 previamente analizado.

---

## 📂 ARCHIVOS ENTREGABLES

### 📄 Documentación Principal

1. **Proyecto_Crimes_NY_HEFESTO.md** (51 KB)
   - Documento completo siguiendo metodología HEFESTO
   - 4 pasos completos con todos los detalles
   - Modelo dimensional completo
   - Procesos ETL documentados

2. **README_CRIMES_NY_DW.md** (10 KB)
   - Guía de instalación y uso
   - Ejemplos de consultas SQL
   - Integración con Power BI
   - Documentación técnica

### 💾 Scripts SQL

3. **creacion_tablas_crimes_ny.sql** (12 KB)
   - Creación de base de datos `crimes_ny_dw`
   - 7 tablas (4 dimensiones + 1 hechos + 2 auxiliares)
   - Índices optimizados
   - Datos maestros

4. **vistas_crimes_ny.sql** (20 KB)
   - 13 vistas analíticas optimizadas
   - Responden a las 12 preguntas de negocio
   - Listas para Power BI/Tableau

### 🐍 Script Python ETL

5. **etl_crimes_ny_mysql.py** (21 KB)
   - Proceso ETL completo automatizado
   - Limpieza y validación de datos
   - Carga con UNPIVOT para categorías
   - Logging y validaciones

---

## 📊 MODELO DIMENSIONAL

### Esquema en Estrella (Star Schema)

```
FACT TABLE: fact_crimes_ny (~71,490 registros)
├── time_id (FK) → dim_tiempo
├── geo_id (FK) → dim_geografia
├── agency_id (FK) → dim_agencia
├── category_id (FK) → dim_categoria
│
├── MEDIDAS:
│   ├── total_delitos
│   ├── total_violentos
│   ├── total_propiedad
│   ├── murder, rape, robbery, aggravated_assault
│   ├── burglary, larceny, motor_vehicle_theft
│   ├── ratio_violencia
│   ├── tasa_violentos_pct
│   └── tasa_propiedad_pct
```

### Dimensiones

| Dimensión | Registros | Descripción |
|-----------|-----------|-------------|
| **dim_tiempo** | 35 | Años 1990-2024 con múltiples granularidades |
| **dim_geografia** | 62 | Condados de NY (5 NYC + 57 no-NYC) |
| **dim_agencia** | 843 | Agencias policiales del estado |
| **dim_categoria** | 3 | Violent, Property, Mixed |

---

## 🎯 12 PREGUNTAS DE NEGOCIO RESUELTAS

| # | Pregunta | Vista SQL |
|---|----------|-----------|
| 1 | Diferencias NYC vs no-NYC | `v_comparativa_nyc_vs_nonyc` |
| 2 | Crecimiento por región | `v_comparativa_nyc_vs_nonyc` |
| 3 | Distribución violentos/propiedad | `v_detalle_condados` |
| 4 | Década con mayor criminalidad | `v_evolucion_decada` |
| 5 | Evolución en lustros | `v_evolucion_lustro` |
| 6 | Tendencia bianual propiedad | `v_evolucion_bianual_propiedad` |
| 7 | Tendencias por condado (alza/baja) | `v_tendencias_condados` |
| 8 | Proporción delitos propiedad | `v_detalle_condados` |
| 9 | Evolución ratio por década NYC/noNYC | `v_proporcion_por_decada_region` |
| 10 | Ranking agencias | `v_top_agencias` |
| 11 | Incremento delitos específicos | `v_ranking_delitos_especificos` |
| 12 | Variación mensual | `fact_crimes_ny.months_reported` |

---

## 📈 INDICADORES CLAVE (KPIs)

### Calculados en `v_kpi_globales`:

- ✅ **Total delitos reportados** (1990-2024)
- ✅ **Total delitos violentos** (Murder + Rape + Robbery + Aggravated Assault)
- ✅ **Total delitos de propiedad** (Burglary + Larceny + Motor Vehicle Theft)
- ✅ **Tasa de violencia** (% violentos / total)
- ✅ **Tasa de propiedad** (% propiedad / total)
- ✅ **35 años** de datos históricos
- ✅ **62 condados** analizados
- ✅ **843 agencias** reportando

---

## 🔄 PROCESO ETL

### Flujo Implementado

```
1. EXTRACCIÓN
   └─ CSV: Index_Crimes_by_County_and_Agency__Beginning_1990.csv
      └─ 23,830 registros originales

2. TRANSFORMACIÓN
   ├─ Limpieza de datos (nulls, espacios, normalización)
   ├─ Clasificación NYC / Non-NYC
   ├─ Cálculo de granularidades temporales
   ├─ Cálculo de ratios y tasas
   └─ Técnica UNPIVOT para categorías

3. CARGA
   ├─ dim_tiempo (35 registros)
   ├─ dim_geografia (62 registros)
   ├─ dim_agencia (843 registros)
   ├─ dim_categoria (3 registros)
   ├─ fact_crimes_ny (~71,490 registros)
   └─ crimes_raw (23,830 registros)

4. VALIDACIÓN
   ├─ Integridad referencial
   ├─ Consistencia de totales
   ├─ Rangos de tasas (0-100%)
   └─ Duplicados
```

---

## 🎓 METODOLOGÍA HEFESTO - 4 PASOS

### ✅ Paso 1: Análisis de Requerimientos
- Identificación de 12 preguntas clave de negocio
- Definición de 7 indicadores principales
- Identificación de 4 perspectivas/dimensiones
- Modelo conceptual inicial

### ✅ Paso 2: Análisis de los OLTP
- Conformación de indicadores con fórmulas matemáticas
- Establecimiento de correspondencias CSV → DW
- Definición de granularidad: `{Año, Condado, Agencia, Categoría}`
- Modelo conceptual ampliado

### ✅ Paso 3: Modelo Lógico del DW
- Elección: **Esquema en Estrella**
- Diseño de 4 dimensiones + 1 tabla de hechos
- Definición de PKs, FKs, índices
- Scripts SQL de creación

### ✅ Paso 4: Integración de Datos
- **Carga inicial**: ETL completo con validaciones
- **Actualización**: Estrategia incremental cada 3 meses
- **Calidad**: 10 validaciones post-carga
- **Auditoría**: Log completo de procesos

---

## 💻 TECNOLOGÍAS Y HERRAMIENTAS

| Componente | Tecnología |
|------------|------------|
| **Base de Datos** | MySQL 8.0+ |
| **ETL** | Python 3.8+ (pandas, numpy, sqlalchemy, pymysql) |
| **Modelado** | Esquema en Estrella |
| **Metodología** | HEFESTO |
| **BI Tools** | Power BI, Tableau (compatible) |
| **Versionado** | Git (recomendado) |

---

## 🚀 GUÍA RÁPIDA DE INSTALACIÓN

### 1. Crear Base de Datos
```bash
mysql -u root -p < creacion_tablas_crimes_ny.sql
```

### 2. Instalar Dependencias
```bash
pip install pandas numpy sqlalchemy pymysql --break-system-packages
```

### 3. Configurar Credenciales
Editar `etl_crimes_ny_mysql.py` líneas 23-28

### 4. Ejecutar ETL
```bash
python etl_crimes_ny_mysql.py
```

### 5. Crear Vistas
```bash
mysql -u root -p crimes_ny_dw < vistas_crimes_ny.sql
```

### 6. Conectar a Power BI
- Obtener datos → MySQL
- Servidor: localhost
- Base de datos: crimes_ny_dw
- Importar tablas y vistas

---

## 📊 ESTADÍSTICAS DEL PROYECTO

### Datos Procesados

| Métrica | Valor |
|---------|-------|
| Registros CSV originales | 23,830 |
| Registros en fact_crimes_ny | ~71,490 |
| Condados únicos | 62 |
| Agencias policiales | 843 |
| Años de histórico | 35 (1990-2024) |
| Vistas analíticas | 13 |
| Líneas de código Python | 400+ |
| Líneas de código SQL | 1,000+ |

### Cobertura Temporal

- **Década 1990**: 10 años (1990-1999)
- **Década 2000**: 10 años (2000-2009)
- **Década 2010**: 10 años (2010-2019)
- **Década 2020**: 5 años (2020-2024)

---

## ✅ VALIDACIONES DE CALIDAD

### Implementadas en el ETL:

1. ✅ Eliminación de registros con nulls críticos
2. ✅ Validación Violent + Property ≈ Index Total
3. ✅ Normalización de texto (espacios, mayúsculas)
4. ✅ Verificación de integridad referencial
5. ✅ Control de duplicados
6. ✅ Rangos válidos de tasas (0-100%)
7. ✅ Años en rango esperado (1990-2024)
8. ✅ Consistencia de totales por categoría
9. ✅ Recálculo automático de crime_tendency
10. ✅ Logging completo de procesos

---

## 🎯 CASOS DE USO PRINCIPALES

### 1. Análisis Comparativo NYC vs Resto del Estado
```sql
SELECT * FROM v_comparativa_nyc_vs_nonyc 
WHERE año >= 2010;
```

### 2. Identificar Condados con Tendencia a la Baja
```sql
SELECT * FROM v_tendencias_condados 
WHERE tendencia = 'Baja'
ORDER BY variacion_porcentual ASC;
```

### 3. Top 10 Agencias con Mayor Índice de Delitos
```sql
SELECT * FROM v_top_agencias LIMIT 10;
```

### 4. Evolución Temporal por Década
```sql
SELECT * FROM v_evolucion_decada;
```

### 5. Dashboard de KPIs Globales
```sql
SELECT * FROM v_kpi_globales;
```

---

## 🏆 LOGROS DEL PROYECTO

### Técnicos:
- ✅ Modelo dimensional robusto y escalable
- ✅ ETL automatizado con validaciones exhaustivas
- ✅ 13 vistas optimizadas para análisis
- ✅ Documentación completa y profesional
- ✅ Código limpio y bien comentado

### Académicos:
- ✅ Aplicación rigurosa de metodología HEFESTO
- ✅ Replicación exitosa de estructura de proyecto COVID
- ✅ Respuesta completa a 12 preguntas de negocio
- ✅ Integración de teoría y práctica

### De Negocio:
- ✅ Análisis histórico de 35 años de criminalidad
- ✅ Comparación justa NYC vs resto del estado
- ✅ Identificación de tendencias y patrones
- ✅ Soporte para toma de decisiones en seguridad pública

---

## 👥 EQUIPO

**Integrantes:**
- Amuchastegui, Matias - 2317591
- Rodriguez Richard, Lucas - 2317609
- Sardoy, Blas - 2318896

**Profesores:**
- Gastón Emilio Severina
- Julio Gutierrez

**Institución:**
Universidad Católica de Córdoba  
Facultad de Ingeniería  
Base de Datos II

---

## 📚 REFERENCIAS

- **Metodología HEFESTO**: Diseño de Data Warehouses
- **Kimball, Ralph**: The Data Warehouse Toolkit
- **Dataset**: Index_Crimes_by_County_and_Agency__Beginning_1990.csv
- **Proyecto de referencia**: COVID-19 Data Warehouse

---

## 📝 CONCLUSIONES

El proyecto demuestra la **aplicación exitosa de la metodología HEFESTO** en el diseño de un Data Warehouse para análisis criminal. Se logró:

1. **Diseño dimensional sólido**: Esquema en estrella con 4 dimensiones y 1 tabla de hechos
2. **ETL robusto**: Proceso automatizado con validaciones de calidad
3. **Respuestas de negocio**: 12 preguntas respondidas con vistas SQL optimizadas
4. **Escalabilidad**: Arquitectura preparada para crecimiento futuro
5. **Documentación completa**: Todos los pasos metodológicos documentados

El Data Warehouse está **listo para producción** y puede integrarse con herramientas de BI como Power BI o Tableau para crear dashboards interactivos.

---

## 🚀 PRÓXIMOS PASOS (OPCIONALES)

### Mejoras Futuras:
- 📊 Dashboard interactivo en Power BI/Tableau
- 🗺️ Integración con datos geoespaciales (mapas de calor)
- 📈 Análisis predictivo con Machine Learning
- 🌐 API REST para consultas externas
- 📱 Aplicación móvil de consulta
- 🔄 Integración con sistemas en tiempo real

---

**Fecha:** Noviembre 2025  
**Versión:** 1.0  
**Estado:** ✅ Completado y listo para entrega
