# Contrato observado: horarios

**Estado: observado** el 2026-11-04 contra el backend local (antes, el 2026-10-29, era una propuesta: no había horarios ni forma de crearlos). Planes: `auditoria-mvvm/plan-diagnostico-horarios.md` (lectura) y `auditoria-mvvm/plan-diagnostico-horarios-escritura.md` (escritura).

Las respuestas son reales; solo se cambió la llave del grupo por la de los fixtures (`Categoria Fase 4` / `Curso Categoria Fase 4` / 2026 / 1) y los `id`.

| Archivo | Ruta | Respuesta |
|---|---|---|
| `horarios_200.json` | `GET /horarios?categoria=&curso=&anio=&iterable=` | `200` con la lista; cada horario trae `eliminado: 0`. Un grupo sin horarios da `200 []` |
| `horario_peticion.json` | Cuerpo de `POST /horario` y `PUT /horario` (`DatosHorarioDto`) | — |
| `horario_201.json` | `POST /horario?categoria=&curso=&anio=&iterable=` | `201` con el horario creado y su `id`, sin `eliminado` |
| `horario_400_dia.json` | `POST`/`PUT` sin `dia` o con `dia` vacío | `400`, un mensaje por campo |
| `horario_400_formato.json` | Hora que no es `HH:mm` ni `HH:mm:ss` (p. ej. `8:00`) | `400` |
| `horario_400_rango.json` | Hora de fin igual o anterior a la de inicio | `400` |
| `horario_404_grupo.json` | `POST` a un grupo inexistente | `404 GC-0003` |
| `horario_404.json` | `PUT` o `DELETE` de un horario inexistente o ya eliminado | `404 GC-0003` |

Observado además:
- `PUT /horario?id=` responde `200` con el horario actualizado; `DELETE /horario?id=` responde `200` con el horario eliminado, y `GET /horarios` deja de listarlo.
- Las horas vuelven **tal como se enviaron** (`08:00` o `14:00:00`).
- Se acepta un día que no existe (`Xyz`) y dos horarios idénticos en el mismo grupo.
