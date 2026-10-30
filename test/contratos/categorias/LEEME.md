# Contrato observado: categorías

**Estado: observado.** Respuestas del backend local del 2026-10-29. Plan: `auditoria-mvvm/plan-diagnostico-categorias.md`.

| Archivo | Ruta | Origen |
|---|---|---|
| `categorias2_200.json` | `GET /categorias2` | 3 categorías reales de la respuesta, que traía 132. El backend manda `imagenId`, no `imagen` |
| `categoria_201.json` | `POST /categoria` (y forma de la respuesta de `PUT /categoria`) | Forma del `CategoriaDto`; valores de ejemplo |
| `imagenMultipart_201.json` | `POST /imagenMultipart` | Copia de `../cursos/imagenMultipart_201.json` |
