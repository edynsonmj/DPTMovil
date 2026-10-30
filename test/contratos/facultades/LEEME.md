# Contrato observado: facultades

**Estado: observado.** Respuesta del backend local del 2026-10-29. Plan: `auditoria-mvvm/plan-diagnostico-instructores-facultades.md`.

| Archivo | Ruta | Origen |
|---|---|---|
| `facultades_200.json` | `GET /facultades` | Respuesta real completa: la BD de pruebas tiene 1 facultad |

`/v3/api-docs` documenta además un `404` "No existen facultades registradas", que no se puede provocar: la API no permite crear ni borrar facultades.
