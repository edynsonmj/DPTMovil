# Contrato observado: instructores

**Estado: observado.** Respuesta del backend local del 2026-10-29. Plan: `auditoria-mvvm/plan-diagnostico-instructores-facultades.md`.

| Archivo | Ruta | Origen |
|---|---|---|
| `instructores_200.json` | `GET /instructores` | Respuesta real completa: la BD de pruebas tiene 1 instructor |

`/v3/api-docs` documenta además un `404` "No existen instructores registrados", que no se puede provocar: la API no permite crear ni borrar instructores.
