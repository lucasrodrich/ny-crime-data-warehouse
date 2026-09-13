"""
============================================================================
ETL CRIMES NY → MYSQL DATA WAREHOUSE
============================================================================
Descripción: Script ETL para cargar datos de delitos de New York (1990-2024)
             desde CSV al Data Warehouse MySQL siguiendo metodología HEFESTO

Autor: Equipo BD2 - UCC
Fecha: Noviembre 2025
Base de datos: crimes_ny_dw
SGBD: MySQL 8.0+
============================================================================
"""

import os
import sys
import getpass
from pathlib import Path
from datetime import datetime

# En Windows, la consola suele usar un codepage (cp1252) que no sabe
# codificar los emojis de estos prints y el script explota con
# UnicodeEncodeError. Forzamos stdout/stderr a UTF-8 (Python 3.7+).
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8')
    sys.stderr.reconfigure(encoding='utf-8')

import pandas as pd
import numpy as np
from sqlalchemy import create_engine, text
import warnings
warnings.filterwarnings('ignore')

# ============================================================================
# CONFIGURACIÓN DE CONEXIÓN A MYSQL
# ============================================================================
# Las credenciales NUNCA se hardcodean. Se leen de variables de entorno y,
# si falta la contraseña, se solicita de forma interactiva (no queda en
# texto plano en el repositorio). Ver README para las variables soportadas:
#   CRIMES_NY_DB_HOST, CRIMES_NY_DB_PORT, CRIMES_NY_DB_USER,
#   CRIMES_NY_DB_PASSWORD, CRIMES_NY_DB_NAME

DB_CONFIG = {
    'host': os.environ.get('CRIMES_NY_DB_HOST', 'localhost'),
    'port': int(os.environ.get('CRIMES_NY_DB_PORT', '3306')),
    'user': os.environ.get('CRIMES_NY_DB_USER', 'root'),
    'password': os.environ.get('CRIMES_NY_DB_PASSWORD'),
    'database': os.environ.get('CRIMES_NY_DB_NAME', 'crimes_ny_dw'),
    'charset': 'utf8mb4',
}

if not DB_CONFIG['password']:
    if sys.stdin.isatty():
        DB_CONFIG['password'] = getpass.getpass(
            f"Password de MySQL para {DB_CONFIG['user']}@{DB_CONFIG['host']}: "
        )
    else:
        print("❌ Error: falta CRIMES_NY_DB_PASSWORD (o una terminal interactiva "
              "para pedirla) y no hay ningún valor por defecto configurado.")
        sys.exit(1)

connection_string = (
    f"mysql+pymysql://{DB_CONFIG['user']}:{DB_CONFIG['password']}"
    f"@{DB_CONFIG['host']}:{DB_CONFIG['port']}/{DB_CONFIG['database']}"
    f"?charset={DB_CONFIG['charset']}"
)

try:
    engine = create_engine(connection_string, echo=False)
    with engine.connect() as _probe:
        pass
    print("=" * 80)
    print("ETL CRIMES NY → MYSQL DATA WAREHOUSE")
    print("=" * 80)
    print(f"📊 Conectando a base de datos: {DB_CONFIG['database']}")
    print(f"🔌 Host: {DB_CONFIG['host']}:{DB_CONFIG['port']}")
    print("✅ Conexión establecida exitosamente\n")
except Exception as e:
    print(f"❌ Error al conectar con MySQL: {e}")
    sys.exit(1)

# ============================================================================
# LOG DE PROCESOS ETL (log_procesos_etl)
# ============================================================================
# Cada corrida del ETL queda registrada en log_procesos_etl: un evento
# INICIADO al comienzo y un COMPLETADO/ERROR al final, con duración y
# cantidad de registros procesados.

PROCESO_ID = f"ETL_{datetime.now():%Y%m%d_%H%M%S}"
_t_inicio = datetime.now()


def log_etl(estado, mensaje=None, registros=None, tipo_proceso='CARGA_INICIAL'):
    """Inserta un evento de auditoría en log_procesos_etl. No debe frenar el
    ETL si falla (es un log, no una fuente de verdad de los datos)."""
    try:
        with engine.connect() as conn:
            conn.execute(text("""
                INSERT INTO log_procesos_etl
                    (proceso_id, tipo_proceso, estado, mensaje, registros_procesados,
                     fecha_inicio, fecha_fin, duracion_segundos)
                VALUES
                    (:proceso_id, :tipo_proceso, :estado, :mensaje, :registros,
                     :fecha_inicio, :fecha_fin, :duracion)
            """), {
                'proceso_id': PROCESO_ID,
                'tipo_proceso': tipo_proceso,
                'estado': estado,
                'mensaje': mensaje,
                'registros': registros,
                'fecha_inicio': _t_inicio,
                'fecha_fin': datetime.now() if estado in ('COMPLETADO', 'ERROR') else None,
                'duracion': int((datetime.now() - _t_inicio).total_seconds()) if estado in ('COMPLETADO', 'ERROR') else None,
            })
            conn.commit()
    except Exception as e:
        print(f"⚠️  No se pudo escribir en log_procesos_etl: {e}")


# ============================================================================
# PASO 1: CARGAR Y LIMPIAR DATOS DEL CSV
# ============================================================================

print("=" * 80)
print("PASO 1: CARGA Y LIMPIEZA DE DATOS")
print("=" * 80)

# Ruta del archivo CSV: por defecto, el que vive junto a este script (así el
# proyecto corre igual sin importar en qué máquina/carpeta se clone). Se
# puede sobreescribir con la variable de entorno CRIMES_NY_CSV_PATH.
SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_CSV = SCRIPT_DIR / 'Index_Crimes_by_County_and_Agency__Beginning_1990.csv'
CSV_FILE = os.environ.get('CRIMES_NY_CSV_PATH', str(DEFAULT_CSV))

try:
    df = pd.read_csv(CSV_FILE, encoding='utf-8')
    print(f"✅ CSV cargado: {len(df):,} filas")
    print(f"📋 Columnas: {list(df.columns)}\n")
except FileNotFoundError:
    print(f"❌ Error: No se encontró el archivo {CSV_FILE}")
    log_etl('ERROR', mensaje=f'CSV no encontrado: {CSV_FILE}')
    sys.exit(1)

# ============================================================================
# PASO 2: LIMPIEZA Y VALIDACIÓN DE DATOS
# ============================================================================

print("⏳ Limpiando datos...")

# Eliminar espacios en columnas de texto
df['County'] = df['County'].str.strip()
df['Agency'] = df['Agency'].str.strip()
df['Region'] = df['Region'].str.strip()

# Rellenar valores nulos en 'Months Reported'
df['Months Reported'] = df['Months Reported'].fillna(12)

# Eliminar filas con valores nulos críticos
antes = len(df)
df_clean = df.dropna(subset=['County', 'Agency', 'Year', 'Index Total']).copy()
despues = len(df_clean)

print(f"✅ Limpieza completada:")
print(f"   Filas originales: {antes:,}")
print(f"   Filas con valores nulos eliminadas: {antes - despues:,}")
print(f"   Filas finales: {despues:,}\n")

# ============================================================================
# PASO 3: ESTADÍSTICAS BÁSICAS
# ============================================================================

print("=" * 80)
print("PASO 2: ESTADÍSTICAS DEL DATASET")
print("=" * 80)

print(f"📊 Rango temporal: {df_clean['Year'].min()} - {df_clean['Year'].max()}")
print(f"📍 Total de condados únicos: {df_clean['County'].nunique()}")
print(f"🚔 Total de agencias únicas: {df_clean['Agency'].nunique()}")
print(f"🗓️  Total de años: {df_clean['Year'].nunique()}\n")

# Clasificación NYC vs Non-NYC
nyc_counties = ['New York', 'Kings', 'Queens', 'Bronx', 'Richmond']
df_clean['is_nyc'] = df_clean['County'].isin(nyc_counties)
total_nyc = df_clean[df_clean['is_nyc']]['County'].nunique()
total_non_nyc = df_clean[~df_clean['is_nyc']]['County'].nunique()

print(f"🏙️  Condados de NYC: {total_nyc}")
print(f"🌆 Condados fuera de NYC: {total_non_nyc}\n")

# ============================================================================
# PASO 4: CREAR DIMENSIÓN TIEMPO
# ============================================================================

print("=" * 80)
print("PASO 3: CREAR DIMENSIÓN TIEMPO")
print("=" * 80)

years_unique = sorted(df_clean['Year'].unique())

dim_tiempo = pd.DataFrame({
    'time_id': years_unique,
    'year': years_unique
})

# Agregar granularidades temporales
dim_tiempo['decada'] = (dim_tiempo['year'] // 10) * 10
dim_tiempo['lustro'] = (dim_tiempo['year'] // 5) * 5
dim_tiempo['bianual'] = (dim_tiempo['year'] // 2) * 2
dim_tiempo['trimestre'] = ((dim_tiempo['year'] - dim_tiempo['year'].min()) // 3) + 1
dim_tiempo['semestre'] = ((dim_tiempo['year'] - dim_tiempo['year'].min()) // 6) + 1

# Períodos descriptivos
dim_tiempo['periodo_decade'] = dim_tiempo['decada'].astype(str) + 's'
dim_tiempo['periodo_lustro'] = dim_tiempo['lustro'].astype(str) + '-' + (dim_tiempo['lustro'] + 4).astype(str)

# Flags por década
dim_tiempo['es_decada_90'] = (dim_tiempo['decada'] == 1990)
dim_tiempo['es_decada_00'] = (dim_tiempo['decada'] == 2000)
dim_tiempo['es_decada_10'] = (dim_tiempo['decada'] == 2010)
dim_tiempo['es_decada_20'] = (dim_tiempo['decada'] == 2020)

print(f"✅ dim_tiempo creada: {len(dim_tiempo)} períodos")
print(f"   Rango: {dim_tiempo['year'].min()} - {dim_tiempo['year'].max()}")
print("\nPrimeras 5 filas:")
print(dim_tiempo.head())
print()

# ============================================================================
# PASO 5: CREAR DIMENSIÓN GEOGRAFÍA
# ============================================================================

print("=" * 80)
print("PASO 4: CREAR DIMENSIÓN GEOGRAFÍA")
print("=" * 80)

dim_geografia = df_clean[['County']].drop_duplicates().reset_index(drop=True)
dim_geografia.columns = ['county_name']

# Clasificación NYC vs Non-NYC
dim_geografia['is_nyc'] = dim_geografia['county_name'].isin(nyc_counties)
dim_geografia['region_type'] = dim_geografia['is_nyc'].apply(
    lambda x: 'NYC' if x else 'Non-New York City'
)

# Crime tendency será calculado después de cargar hechos
dim_geografia['crime_tendency'] = 'Pending_Calculation'
dim_geografia['latitude'] = None
dim_geografia['longitude'] = None
dim_geografia['population'] = None
dim_geografia['area_sq_miles'] = None

print(f"✅ dim_geografia creada: {len(dim_geografia)} condados")
print(f"   Condados NYC: {dim_geografia['is_nyc'].sum()}")
print(f"   Condados Non-NYC: {(~dim_geografia['is_nyc']).sum()}")
print("\nPrimeras 10 condados:")
print(dim_geografia[['county_name', 'region_type', 'is_nyc']].head(10))
print()

# ============================================================================
# PASO 6: CREAR DIMENSIÓN AGENCIA
# ============================================================================

print("=" * 80)
print("PASO 5: CREAR DIMENSIÓN AGENCIA")
print("=" * 80)

dim_agencia = df_clean[['Agency', 'County', 'Region']].drop_duplicates(subset=['Agency', 'County']).reset_index(drop=True)
dim_agencia.columns = ['agency_name', 'county', 'region']

# El CSV trae ~20 pares (agencia, condado) que sólo difieren en mayúsculas/
# minúsculas (p.ej. "SUNY College at Alfred" vs "SUNY College At Alfred").
# drop_duplicates() de pandas es case-sensitive y no los detecta, pero la
# UNIQUE KEY (agency_name, county) de MySQL usa una collation case-insensitive
# (utf8mb4_unicode_ci), así que esas filas chocan al insertar. Se normaliza
# antes de cargar, quedándonos con una sola grafía por agencia real.
_dedup_key = dim_agencia['agency_name'].str.lower() + '|' + dim_agencia['county'].str.lower()
n_variantes = _dedup_key.duplicated().sum()
if n_variantes:
    print(f"⚠️  {n_variantes} agencias con variantes de mayúsculas/minúsculas "
          f"(mismo nombre, distinta grafía) — se conserva una sola por condado")
dim_agencia = dim_agencia.loc[~_dedup_key.duplicated(keep='first')].reset_index(drop=True)

# Clasificar is_nyc
dim_agencia['is_nyc'] = dim_agencia['region'] == 'New York City'

# Clasificar tipo de agencia
def classify_agency_type(agency_name):
    if 'City PD' in agency_name or 'City Police' in agency_name:
        return 'City Police'
    elif 'County Sheriff' in agency_name or ' SO' in agency_name:
        return 'County Sheriff'
    elif 'State Police' in agency_name or 'SP' in agency_name:
        return 'State Police'
    elif 'Village PD' in agency_name:
        return 'Village Police'
    elif 'Town PD' in agency_name:
        return 'Town Police'
    else:
        return 'Other'

dim_agencia['agency_type'] = dim_agencia['agency_name'].apply(classify_agency_type)

print(f"✅ dim_agencia creada: {len(dim_agencia)} agencias")
print("\nDistribución por tipo de agencia:")
print(dim_agencia['agency_type'].value_counts())
print("\nPrimeras 10 agencias:")
print(dim_agencia[['agency_name', 'county', 'agency_type']].head(10))
print()

# ============================================================================
# PASO 7: PREPARAR TABLA DE HECHOS (PRE-PROCESAMIENTO)
# ============================================================================

print("=" * 80)
print("PASO 6: PREPARAR TABLA DE HECHOS")
print("=" * 80)

# Crear tabla de hechos base (sin categorías aún)
fact_base = df_clean[[
    'Year', 'County', 'Agency',
    'Index Total', 'Violent Total', 'Property Total',
    'Murder', 'Rape', 'Robbery', 'Aggravated Assault',
    'Burglary', 'Larceny', 'Motor Vehicle Theft',
    'Months Reported'
]].copy()

# Renombrar columnas
fact_base.columns = [
    'year', 'county', 'agency',
    'index_total', 'violent_total', 'property_total',
    'murder', 'rape', 'robbery', 'aggravated_assault',
    'burglary', 'larceny', 'motor_vehicle_theft',
    'months_reported'
]

# Calcular métricas
fact_base['ratio_violencia'] = (
    fact_base['violent_total'] / fact_base['index_total'].replace(0, np.nan)
).fillna(0).round(3)

fact_base['tasa_violentos_pct'] = (
    (fact_base['violent_total'] / fact_base['index_total'].replace(0, np.nan)) * 100
).fillna(0).round(2)

fact_base['tasa_propiedad_pct'] = (
    (fact_base['property_total'] / fact_base['index_total'].replace(0, np.nan)) * 100
).fillna(0).round(2)

print(f"✅ Tabla de hechos base preparada: {len(fact_base):,} registros")
print("\nEstadísticas:")
print(fact_base[['index_total', 'violent_total', 'property_total']].describe())
print()

# ============================================================================
# PASO 8: LIMPIAR TABLAS EXISTENTES EN MYSQL
# ============================================================================

print("=" * 80)
print("PASO 7: PREPARAR BASE DE DATOS")
print("=" * 80)

try:
    with engine.connect() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
        conn.execute(text("TRUNCATE TABLE fact_crimes_ny"))
        conn.execute(text("TRUNCATE TABLE dim_tiempo"))
        conn.execute(text("TRUNCATE TABLE dim_geografia"))
        conn.execute(text("TRUNCATE TABLE dim_agencia"))
        conn.execute(text("TRUNCATE TABLE crimes_raw"))
        conn.execute(text("DELETE FROM log_procesos_etl"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
        conn.commit()
    print("✅ Tablas limpiadas correctamente\n")
except Exception as e:
    print(f"⚠️  Advertencia al limpiar tablas: {e}\n")

# A partir de acá log_procesos_etl ya existe y está vacía: registramos el
# inicio de esta corrida.
log_etl('INICIADO', mensaje=f'ETL iniciado. CSV: {CSV_FILE}')

# ============================================================================
# PASO 9: CARGAR DIMENSIONES A MYSQL
# ============================================================================

print("=" * 80)
print("PASO 8: CARGANDO DIMENSIONES A MYSQL")
print("=" * 80)

try:
    # Cargar dimensión tiempo
    print("⏳ Cargando dim_tiempo...")
    dim_tiempo.to_sql('dim_tiempo', engine, if_exists='append', index=False, method='multi', chunksize=100)
    print(f"✅ dim_tiempo: {len(dim_tiempo)} registros insertados")

    # Cargar dimensión geografía (geo_id es AUTO_INCREMENT en MySQL)
    print("⏳ Cargando dim_geografia...")
    dim_geografia.to_sql(
        'dim_geografia', engine, if_exists='append', index=False, method='multi', chunksize=100
    )
    print(f"✅ dim_geografia: {len(dim_geografia)} registros insertados")

    # Cargar dimensión agencia (agency_id es AUTO_INCREMENT en MySQL).
    # dim_agencia ya viene deduplicada por (agency_name, county) y la tabla
    # se truncó en el paso anterior, así que un insert masivo alcanza: no
    # hace falta ir fila por fila con INSERT IGNORE (ese patrón sólo tiene
    # sentido si la tabla pudiera tener datos previos en conflicto).
    print("⏳ Cargando dim_agencia...")
    dim_agencia.to_sql(
        'dim_agencia', engine, if_exists='append', index=False, method='multi', chunksize=200
    )
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM dim_agencia")).fetchone()
        print(f"✅ dim_agencia: {result[0]} registros insertados\n")

except Exception as e:
    print(f"❌ Error al cargar dimensiones: {e}")
    import traceback
    traceback.print_exc()
    log_etl('ERROR', mensaje=f'Error cargando dimensiones: {e}')
    sys.exit(1)

# ============================================================================
# PASO 10: CARGAR TABLA RAW A MYSQL
# ============================================================================

print("=" * 80)
print("PASO 9: CARGANDO DATOS CRUDOS (crimes_raw)")
print("=" * 80)

try:
    # Preparar crimes_raw
    crimes_raw = df_clean[[
        'County', 'Agency', 'Year', 'Months Reported',
        'Index Total', 'Violent Total', 'Murder', 'Rape', 'Robbery', 'Aggravated Assault',
        'Property Total', 'Burglary', 'Larceny', 'Motor Vehicle Theft', 'Region'
    ]].copy()

    crimes_raw.columns = [
        'county', 'agency', 'year', 'months_reported',
        'index_total', 'violent_total', 'murder', 'rape', 'robbery', 'aggravated_assault',
        'property_total', 'burglary', 'larceny', 'motor_vehicle_theft', 'region'
    ]

    print("⏳ Cargando crimes_raw...")
    crimes_raw.to_sql('crimes_raw', engine, if_exists='append', index=False, method='multi', chunksize=500)
    print(f"✅ crimes_raw: {len(crimes_raw):,} registros insertados\n")

except Exception as e:
    print(f"❌ Error al cargar crimes_raw: {e}")
    import traceback
    traceback.print_exc()
    log_etl('ERROR', mensaje=f'Error cargando crimes_raw: {e}')
    sys.exit(1)

# ============================================================================
# PASO 11: CARGAR TABLA DE HECHOS USANDO SQL (UNPIVOT POR CATEGORÍAS)
# ============================================================================

print("=" * 80)
print("PASO 10: CARGANDO TABLA DE HECHOS (fact_crimes_ny)")
print("=" * 80)

# Insertar hechos directamente desde crimes_raw con CROSS JOIN de categorías
sql_insert_facts = text("""
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
INNER JOIN dim_geografia g ON g.county_name = cr.county
INNER JOIN dim_agencia a ON a.agency_name = cr.agency AND a.county = cr.county
CROSS JOIN dim_categoria cat
WHERE cr.index_total >= 0
""")

try:
    print("⏳ Insertando hechos con categorías (puede tomar unos segundos)...")
    with engine.connect() as conn:
        result = conn.execute(sql_insert_facts)
        conn.commit()
        fact_rows_inserted = result.rowcount
        print(f"✅ fact_crimes_ny: {fact_rows_inserted:,} registros insertados\n")
except Exception as e:
    print(f"❌ Error al cargar hechos: {e}")
    import traceback
    traceback.print_exc()
    log_etl('ERROR', mensaje=f'Error cargando fact_crimes_ny: {e}')
    sys.exit(1)

# ============================================================================
# PASO 12: CALCULAR CRIME TENDENCY POR CONDADO
# ============================================================================

print("=" * 80)
print("PASO 11: CALCULAR CRIME TENDENCY POR CONDADO")
print("=" * 80)

# Umbrales calibrados sobre la distribución real del dataset (1990-2024,
# 62 condados): el % de delitos violentos por condado va de ~5% a ~34%
# (mediana ~10%, p90 ~14.4%) y el % de propiedad va de ~66% a ~95%
# (mediana ~90%). Con el umbral original (violentos > 20%) sólo entraban
# Bronx/Kings/Queens, y con propiedad > 85% (por debajo de la mediana)
# casi todos los condados quedaban en 'Property_Prone', dejando la
# clasificación sin poder discriminar. Los umbrales de abajo (>15% y >90%,
# aprox. p85-p90 de cada distribución) reparten los 62 condados en algo
# más balanceado (~6 Violence_Prone / ~31 Property_Prone / ~25 Mixed).
sql_update_tendency = text("""
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
    WHERE f.category_id = 3  -- Solo categoría Mixed (Total)
    GROUP BY g.geo_id, g.county_name
)
UPDATE dim_geografia g
JOIN county_stats cs ON g.geo_id = cs.geo_id
SET g.crime_tendency = CASE
    WHEN cs.pct_violentos > 15 THEN 'Violence_Prone'
    WHEN cs.pct_propiedad > 90 THEN 'Property_Prone'
    ELSE 'Mixed_Profile'
END
""")

try:
    print("⏳ Calculando tendencias criminales por condado...")
    with engine.connect() as conn:
        conn.execute(sql_update_tendency)
        conn.commit()
    print("✅ Crime tendency actualizado para todos los condados\n")
except Exception as e:
    print(f"❌ Error al calcular crime tendency: {e}")
    log_etl('ERROR', mensaje=f'Error calculando crime_tendency: {e}')

# ============================================================================
# PASO 13: VERIFICACIÓN FINAL
# ============================================================================

print("=" * 80)
print("PASO 12: VERIFICACIÓN DE DATOS")
print("=" * 80)

with engine.connect() as conn:
    result_tiempo = conn.execute(text("SELECT COUNT(*) as count FROM dim_tiempo")).fetchone()
    result_geo = conn.execute(text("SELECT COUNT(*) as count FROM dim_geografia")).fetchone()
    result_agencia = conn.execute(text("SELECT COUNT(*) as count FROM dim_agencia")).fetchone()
    result_categoria = conn.execute(text("SELECT COUNT(*) as count FROM dim_categoria")).fetchone()
    result_hechos = conn.execute(text("SELECT COUNT(*) as count FROM fact_crimes_ny")).fetchone()
    result_raw = conn.execute(text("SELECT COUNT(*) as count FROM crimes_raw")).fetchone()

    print(f"📊 dim_tiempo: {result_tiempo[0]:,} registros")
    print(f"📊 dim_geografia: {result_geo[0]:,} registros")
    print(f"📊 dim_agencia: {result_agencia[0]:,} registros")
    print(f"📊 dim_categoria: {result_categoria[0]:,} registros")
    print(f"📊 fact_crimes_ny: {result_hechos[0]:,} registros")
    print(f"📊 crimes_raw: {result_raw[0]:,} registros\n")

    if result_hechos[0] > 0:
        print("📈 ESTADÍSTICAS GLOBALES:")

        total_casos = conn.execute(text("""
            SELECT SUM(total_delitos) as total
            FROM fact_crimes_ny
            WHERE category_id = 3
        """)).fetchone()

        total_violentos = conn.execute(text("""
            SELECT SUM(total_violentos) as total
            FROM fact_crimes_ny
            WHERE category_id = 3
        """)).fetchone()

        total_propiedad = conn.execute(text("""
            SELECT SUM(total_propiedad) as total
            FROM fact_crimes_ny
            WHERE category_id = 3
        """)).fetchone()

        print(f"   Total delitos reportados (1990-2024): {total_casos[0]:,}")
        print(f"   Total delitos violentos: {total_violentos[0]:,}")
        print(f"   Total delitos de propiedad: {total_propiedad[0]:,}")

        print("\n🏙️  TOP 5 CONDADOS CON MÁS DELITOS:")
        top_condados = conn.execute(text("""
            SELECT g.county_name, g.region_type, SUM(f.total_delitos) as total
            FROM fact_crimes_ny f
            JOIN dim_geografia g ON f.geo_id = g.geo_id
            WHERE f.category_id = 3
            GROUP BY g.county_name, g.region_type
            ORDER BY total DESC
            LIMIT 5
        """)).fetchall()

        for i, (county, region, total) in enumerate(top_condados, 1):
            print(f"   {i}. {county} ({region}): {total:,} delitos")

        print("\n🧭 DISTRIBUCIÓN DE CRIME TENDENCY:")
        tendencia_counts = conn.execute(text("""
            SELECT crime_tendency, COUNT(*) as cantidad
            FROM dim_geografia
            GROUP BY crime_tendency
            ORDER BY cantidad DESC
        """)).fetchall()
        for tendencia, cantidad in tendencia_counts:
            print(f"   {tendencia}: {cantidad} condados")

log_etl('COMPLETADO', mensaje='ETL finalizado sin errores', registros=result_hechos[0])

print("\n" + "=" * 80)
print("✅ ETL COMPLETADO EXITOSAMENTE")
print("=" * 80)
print("\n🎉 Data Warehouse 'crimes_ny_dw' está listo para análisis!")
print("📊 Puedes comenzar a crear visualizaciones en Power BI o ejecutar consultas SQL.\n")
