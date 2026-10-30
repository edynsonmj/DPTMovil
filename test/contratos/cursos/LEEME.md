# Contrato observado: cursos

**Estado: observado.** Respuestas del backend local del 2026-10-29. Plan: `auditoria-mvvm/plan-diagnostico-cursos.md`.

| Archivo | Ruta | Origen |
|---|---|---|
| `cursosbycategoria_200.json` | `GET /cursosbycategoria?prmCategoria=` | Respuesta real de `Categoria Fase 4` (1 curso), más un segundo curso con la misma forma, añadido para tener dos filas |
| `curso_200.json` | `GET /curso?prmCategoria=&prmCurso=` | Respuesta real |
| `curso_201.json` | `POST /curso` | Forma del `CursoDto`. `/v3/api-docs` documenta `200`, pero el backend responde `201` |
| `imagenMultipart_201.json` | `POST /imagenMultipart` | Forma del `ImagenDto` que lee `ImagenModelo.fromJson`; valores de ejemplo |

Otros datos observados:
- Una categoría sin cursos da `200 []`.
- Un curso inexistente da `404` con `{"codigoError":"GC-0003", …}`.
