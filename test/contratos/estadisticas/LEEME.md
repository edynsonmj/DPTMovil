# Contrato observado: estadísticas generales

**Estado: observado.** Tienen la forma de las respuestas **reales** del backend local del 2026-10-29: `GET /estadisticas/{categorias,cursos,grupos}?inicio=yyyy-MM-dd&fin=yyyy-MM-dd`. Se recortaron a unas pocas filas, con nombres que existen en la BD de pruebas.

- Los números llegan siempre como `double` (`1.0`, `0.0`).
- `leyenda1` a `leyenda4` son, según la ruta, la categoría, el curso, el año y el iterable; las leyendas que no usa la ruta llegan como `null`.
- `duracion` es el total en minutos, y `horas` y `minutos` son su desglose (`horas × 60 + minutos == duracion`).
- **Observado el 2026-11-05:** `minutos` no se pasa a horas. Tres clases de 1 h 30 llegan como `horas: 3.0`, `minutos: 90.0`, `duracion: 270.0` (ES-06). La igualdad de arriba se cumple, pero `minutos` puede pasar de 59.

Plan: `auditoria-mvvm/plan-diagnostico-estadisticas.md`.

| Archivo | Ruta |
|---|---|
| `categorias_200.json` | `/estadisticas/categorias` (3 filas, solo `leyenda1`) |
| `cursos_200.json` | `/estadisticas/cursos` (2 filas, `leyenda1` y `leyenda2`) |
| `grupos_200.json` | `/estadisticas/grupos` (2 filas, las cuatro leyendas) |
