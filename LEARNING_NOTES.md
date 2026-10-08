# LEARNING_NOTES — ny-crime-data-warehouse

Progreso de reaprendizaje del proyecto para entrevistas de Data Analyst / Data Engineer.
Metodología: tutor Claude lee el repo, explica un módulo, hace preguntas tipo entrevista,
corrige, y solo avanza al siguiente módulo cuando las respuestas están bien formuladas.

## Estado

- Mapa del repo: hecho y confirmado.
- Módulo actual: M2 — Modelado dimensional (siguiente a arrancar).

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
