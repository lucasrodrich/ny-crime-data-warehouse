# LEARNING_NOTES — ny-crime-data-warehouse

Progreso de reaprendizaje del proyecto para entrevistas de Data Analyst / Data Engineer.
Metodología: tutor Claude lee el repo, explica un módulo, hace preguntas tipo entrevista,
corrige, y solo avanza al siguiente módulo cuando las respuestas están bien formuladas.

## Estado

- Mapa del repo: hecho y confirmado.
- Módulo actual: M2 — Modelado dimensional (Q1 aprobada; faltan Q2-Q5 y el control de
  1993, ver sección "M2 — en curso" más abajo).

## Módulos completados

- **M1 — Visión general**: 5/5 preguntas aprobadas (con correcciones en el camino).

## Preguntas falladas / a repasar

- **Costo computacional del modelo dimensional (M1, Q2):** error recurrente — pensar que
  pasar de formato ancho a modelo dimensional/UNPIVOT es "más barato computacionalmente".
  Es al revés: 23.830 filas → 71.490 (×3 por CROSS JOIN con dim_categoria) es *más* filas
  para almacenar y potencialmente escanear. La ganancia real es flexibilidad/consistencia
  de la forma de la consulta (mismo patrón sirve para cualquier nivel de categoría), no
  velocidad. Ojo: esto es independiente de la ganancia de performance real del esquema en
  estrella vs. un modelo normalizado (3NF) por menos JOINs — son dos ejes de diseño distintos,
  no confundirlos.
- **"Months Reported" (M1, Q3):** error recurrente — interpretarlo como "mes calendario en
  que se reportó/contó" (ej. "mes 12 = diciembre"). Es una CANTIDAD (cuántos meses de
  cobertura tiene esa fila), no un identificador de mes. Nunca indica en qué mes ocurrió
  el delito; por eso la pregunta de variación mensual es irrespondible con esta fuente.
- **Decisión de negocio (M1, Q1):** primer intento mezcló la decisión con ciclos
  presidenciales (ajeno al repo — el dataset es estatal, no federal, y el README habla de
  recalibración trimestral, no electoral).
- **Números de escala (M1, Q4):** no tener memorizados los básicos (62 condados, 5 NYC,
  57 non-NYC) resta credibilidad en una entrevista aunque el razonamiento esté bien.

## Respuestas finales (en mis palabras, corregidas)

**Q1 — ¿Qué decisión de negocio habilita el análisis?**
El negocio se beneficia de poder asignar correctamente recursos (presupuesto, personal
policial) a los condados o departamentos que realmente están afectados por el alza de
criminalidad, en vez de basarse en el promedio general del estado — que puede estar cayendo
mientras condados específicos van al alza (12 de 62, ninguno de NYC).

**Q2 — ¿Por qué el CSV viene en formato ancho, y qué problema trae eso?**
Viene ancho porque cada fila (condado-agencia-año) tiene una columna por cada tipo/total de
delito. El problema real no es poder sumar violento/propiedad por año (eso es trivial en
formato ancho) — es que cambiar el nivel de agregación (total general → violento → tipo
específico) obliga a reescribir la consulta apuntando a otra columna cada vez. El modelo
dimensional (UNPIVOT contra `dim_categoria`) resuelve eso con un filtro estandarizado
(`category_id`), a costa de triplicar las filas de la tabla de hechos — un costo de
almacenamiento/lectura que se paga una sola vez, no una ganancia de performance.

**Q3 — ¿Por qué se descartó la pregunta de variación mensual?**
La columna que tienta a pensar que hay datos mensuales es `Months Reported`, pero representa
la cantidad de meses que cubre el reporte de esa fila (completitud del dato), no qué mes
calendario ocurrió el delito. El grano mínimo real del dataset es anual; no existe ningún
campo que identifique un mes específico.

**Q4 — ¿Cuántos condados, y por qué importa la distinción NYC/non-NYC?**
62 condados en total: 5 son NYC (New York/Manhattan, Kings/Brooklyn, Queens, Bronx,
Richmond/Staten Island) y 57 son non-NYC. La distinción importa porque permite discriminar
a nivel granular en vez de asignar presupuesto de forma pareja según el agregado estatal —
evita que la tendencia de NYC (que domina el promedio) oculte el comportamiento real de
condados específicos fuera de NYC.

**Q5 — ¿Qué es HEFESTO? (pregunta de intuición, sin penalización)**
Respuesta inicial: un framework que ordena el pipeline de datos de punta a punta. Corrección
pendiente de profundizar en M2: es específicamente una metodología de 4 pasos para diseñar
Data Warehouses (análisis de requerimientos → análisis del OLTP → modelo lógico del DW →
integración de datos) — no un framework genérico de pipelines, y no hay sensores en este
proyecto (la fuente es un CSV abierto del NYS DCJS).

---

## M2 — en curso (Modelado dimensional)

### Conceptos vistos
- **Hechos vs. dimensiones:** hecho = evento medible (tabla larga, medidas numéricas, FKs);
  dimensión = contexto para cortar (tabla chica y ancha, atributos descriptivos).
- **Estrella vs. 3NF:** estrella acepta redundancia (ej. `region_type` repetido en cada
  condado) a cambio de menos JOINs. Es un eje distinto al de "formato ancho vs. dimensional".
- **Grano:** qué representa UNA fila de la fact. Se define primero porque de él dependen
  medidas y dimensiones. Acá: {Año, Condado, Agencia, Categoría}
  (`Proyecto_Crimes_NY_HEFESTO.md:245`).
- **HEFESTO (4 pasos):** requerimientos (`:18`) → análisis OLTP (`:99`) → modelo lógico
  (`:313`) → integración de datos (`:590`).
- **Dimensiones:** `dim_tiempo` (`creacion_tablas_crimes_ny.sql:21`), `dim_geografia` (`:45`),
  `dim_agencia` (`:66`), `dim_categoria` (`:85`); fact en `:113-160`.
- **Fórmulas de granularidad temporal:** `FLOOR(Year/N)*N` devuelve el primer año del bloque de
  N años (década N=10, lustro N=5, bianual N=2; `Proyecto_Crimes_NY_HEFESTO.md:185-189`,
  `:663-665`). Ej. 2017 → 2010 / 2015 / 2016. Control pendiente: 1993 → 1990 / 1990 / 1992.

### Observaciones críticas del diseño (para defender con honestidad en entrevista)
1. **Medidas repetidas ×3:** el `CROSS JOIN` con `dim_categoria` (`Proyecto_Crimes_NY_HEFESTO.md:886`)
   copia `total_violentos`/`total_propiedad` en las 3 filas; solo `total_delitos` cambia por
   categoría (`:840-845`). Sumar sin filtrar `category_id` triplica. Se retoma en M4.
2. **`time_id` = año** (`creacion_tablas_crimes_ny.sql:22`), a diferencia del resto que usan
   autoincremental. Justificación no está en el repo.
3. **`trimestre`/`semestre` son vestigiales:** el informe los condicionaba a "si se tiene dato de
   mes" (`Proyecto_Crimes_NY_HEFESTO.md:188-189`), la fuente es anual (`:34`). El informe usa
   `CEIL(Year/3)` (`:666`) y el ETL `((year-min)//3)+1` (`etl_crimes_ny_mysql.py:209-210`):
   dos fórmulas distintas, ninguna es un trimestre real, y ninguna vista las usa. No defenderlas
   como análisis válido; en M8: eliminarlas o dejarlas NULL hasta tener fuente mensual
   (con mes serían `CEIL(mes/3)` y `CEIL(mes/6)`). Quién las incluyó y por qué: no está en el
   repo, lo respondo yo.
4. **Indicador 4 (ratio) e Indicador 5 (tasa %) son redundantes:** `tasa = ratio × 100`
   (`Proyecto_Crimes_NY_HEFESTO.md:118-126`, columnas en `creacion_tablas_crimes_ny.sql:138-139`).
   Grep sobre las vistas: `tasa_*_pct` se usa en varias (líneas 103-104, 133-134, 214-215, 248,
   276-277, 301 de `vistas_crimes_ny.sql`); `ratio_violencia` solo en la línea 213, junto a
   `tasa_violentos_pct` en la 214 (mismo dato en dos escalas).
5. **Promedio de promedios:** las vistas con `AVG(f.tasa_*_pct)` pesan igual a una agencia de 5
   delitos y a una de 50.000. `v_kpi_globales` (`vistas_crimes_ny.sql:35-45`) en cambio recalcula
   la tasa desde `SUM/SUM`, que es lo correcto. Inconsistencia de método entre vistas; a retomar
   en M5 (vistas) y M8 (qué haría distinto). Pendiente: medir cuánto difieren los números.

### Respondidas (M2)
1. **Grano — aprobada con corrección (3 intentos).** Error: confundir grano con granularidad
   temporal (década/lustro son atributos de `dim_tiempo`, no el grano de la fact) y con "rango
   numérico". Versión final: una fila de la fact es la combinación única de año, condado, agencia
   y categoría; se define primero porque de él dependen qué medidas son válidas y aditivas
   (ej. `total_violentos` vive a grano {año, condado, agencia} y se copia ×3).

### Aporte propio (defecto del diseño)
- En la fact, `total_violentos`, `total_propiedad` y los delitos específicos (`murder`, etc.,
  `Proyecto_Crimes_NY_HEFESTO.md:847-857`) se copian idénticos en las 3 filas por el
  `CROSS JOIN` (`:886`). En la fila Violento duplican a `total_delitos`; en la fila Propiedad no
  significan nada. Solo `total_delitos` varía por categoría (`CASE`, `:840-845`). Corrección que
  propongo: dejar solo `total_delitos` en la fact (o una fact separada a nivel agencia-año).
- Alternativa evaluada y descartada: una tabla por tipo de delito. La categoría pasaría a vivir
  en el nombre de la tabla (UNION para comparar, tabla nueva por categoría, sin slicer en
  Power BI). Con 71.490 filas e índice, el costo de filtrar por `category_id` es despreciable.

### Pendiente de responder (preguntas de entrevista M2)
- Control: 1993 con `FLOOR(Year/N)*N` para N=10, 5, 2.
2. Por qué `region_type` vive dentro de `dim_geografia` y no en una `dim_region` (estrella vs. 3NF).
3. Qué pasa si sumo `total_violentos` sobre toda la fact sin filtrar `category_id` y por qué.
4. Ventaja y riesgo de usar el año como PK de `dim_tiempo` frente a un autoincremental.
5. Para qué sirven `trimestre`/`semestre` y qué responder si preguntan por qué están.

M2 no se marca completado hasta responder estas 5 con respuestas bien formuladas.
