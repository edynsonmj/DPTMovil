# Contrato observado: alumnos del grupo

**Estado: observado.** Respuestas del backend local del 2026-10-29. Plan: `auditoria-mvvm/plan-diagnostico-alumnos.md`.

| Archivo | Ruta | Origen |
|---|---|---|
| `alumnosGrupo_200.json` | `GET /alumnosGrupo?categoria=&curso=&anio=&iterable=` | Los 2 primeros alumnos de un grupo real |
| `alumnosGrupo_vacio.json` | La misma ruta, para un grupo sin alumnos | Respuesta real: `200` con el objeto `GC-0002`, no `[]` |

Observado en los 142 grupos:
- Los grupos sin alumnos responden siempre con el objeto `GC-0002`; nunca con el `404` que documenta `/v3/api-docs`.
- `codigo` e `imagen` llegan a `null` en los 112 alumnos.
