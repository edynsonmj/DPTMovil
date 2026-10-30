# Contrato observado: clases

**Estado: observado.** Respuestas del backend local del 2026-10-29. Plan: `auditoria-mvvm/plan-diagnostico-clases.md`.

| Archivo | Ruta | Origen |
|---|---|---|
| `clasesGrupo_200.json` | `GET /clasesGrupo?categoria=Categoria Fase 4&curso=Curso Categoria Fase 4&anio=2026&iterable=1` | Respuesta real recortada. `fecha` llega como `yyyy-MM-dd`, sin hora |
| `clasesGrupo_vacio.json` | La misma ruta con `iterable=99` | Respuesta real: **`[]`** |

**Cambio del backend:** el 2026-10-29, un grupo sin clases responde `200 []`. Antes respondía `200` con un objeto `GC-0002` "listado vacío", que la conexión convertía en 406; así lo describen `CLAUDE.md` y el comentario de `DetalleGrupoViewModel._seccionLista`. La app maneja las dos formas.
