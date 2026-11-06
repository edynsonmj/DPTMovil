# Contrato observado: periodo de inscripción de un grupo

**Actualizado el 2026-11-05 contra el backend nuevo:** `periodo_200.json`, `cerrarManual_200.json` y `periodo_422_cierre.json` tienen la forma observada ese día. Las rutas `PUT /abrirInscripcionesGrupo` y `/cerrarInscripcionesGrupo` ya no existen; `abrir_200.json` y `cerrar_200.json` quedan solo como muestras de un grupo y sus fechas.

**Estado: observado.** A diferencia de `../atenciones/`, que es una propuesta, estos archivos son respuestas **reales** del backend, capturadas el 2026-10-29 contra el backend local (`/v3/api-docs` con 36 rutas). Plan de implementación: `auditoria-mvvm/plan-abrir-inscripciones.md`.

**Errata del backend:** el campo de cierre se llama `fechaIncripcionCierre`, sin la segunda "s". Se conserva tal cual porque es lo que el backend responde (decisión D2 del plan). Si el backend lo corrige, hay que actualizar estos archivos y la clave en `GrupoModelo` y `PeriodoInscripcionModelo`; las pruebas que usan estos archivos lo detectarán.

## Endpoints

| Método | Ruta (sobre `/api/v2`) | Cuerpo | Respuesta |
|---|---|---|---|
| PATCH | `/grupo/periodo` | `{ "fechaApertura"?: "yyyy-MM-dd", "fechaCierre": "yyyy-MM-dd", "grupos": [{categoria, curso, anio, iterable}] }`. El cierre es obligatorio y de hoy en adelante | `200` con la lista de grupos (`periodo_200.json`); `422 GC-0015` de fechas (`periodo_422_cierre.json`); `404 GC-0003` (`grupo_404.json`). No reabre un grupo cerrado a mano |
| PATCH | `/grupo/inscripciones?categoria=&curso=&anio=&iterable=&cerradas=` | Sin cuerpo | `200` con el grupo y `inscripcionesCerradasManual` (`cerrarManual_200.json`); las fechas no cambian. Reabrir da 422 si el cierre ya paso |
| GET | `/gruposNoEliminados` | — | `200` con los grupos y sus dos fechas (`gruposNoEliminados_200.json`) |

## Archivos

| Archivo | Petición que lo produjo |
|---|---|
| `abrir_200.json` | Abrir con apertura `2026-10-29` y cierre `2026-11-30` |
| `cerrar_200.json` | Cerrar el mismo grupo el 2026-10-29 |
| `abrir_400_cierre.json` | Abrir con cierre (`2026-11-01`) anterior a la apertura (`2026-11-10`). El mismo cuerpo sale con un cierre en el pasado |
| `abrir_400_formato.json` | Abrir con `"fechaInscripcionApertura": "29/10/2026"` |
| `grupo_404.json` | Abrir un grupo inexistente. Cerrar uno inexistente da el mismo `GC-0003`, con el mensaje "el grupo buscado no existe en el sistema" |
| `gruposNoEliminados_200.json` | **Recorte** de la respuesta real (14 grupos) a 3: uno **abierto** el 2026-10-29 (`Categoria Fase 4`/1), uno **sin periodo** (ambas fechas `null`, `Categoria Fase 4`/2) y uno **cerrado** (`prueba_...`/2, apertura = cierre = 2026-10-28) |

## Comportamiento observado

- Un grupo aparece en `GET /gruposInscripcion` si `apertura <= hoy` y (`cierre` es nulo o `cierre >= hoy`). Si el día de cierre cuenta como abierto se **infiere** de que "cerrar" deja el cierre en ayer; falta una prueba remota que lo confirme (fase 5 del plan).
- Una apertura futura se acepta con `200`, pero el grupo no aparece hasta esa fecha. Así se "programa".
- Los errores `400` llegan como un objeto JSON con mensajes por campo. `DialogError` los desglosa.

## Inscripción del alumno (observado el 2026-11-05, backend nuevo)

| Archivo | Petición que lo produjo |
|---|---|
| `inscripcion_201_inscrito.json` | `POST /inscripcion` con cupos. Nombres de categoría y curso cambiados; la forma es la observada |
| `inscripcion_201_en_espera.json` | `POST /inscripcion` con el grupo lleno. También es 201: solo `estado` lo distingue (BK-06) |
| `inscripcion_409_en_espera.json` | Repetir `POST /inscripcion` estando en lista de espera |
| `inscripcion_422_cerrada.json` | `POST /inscripcion` con el grupo cerrado a mano |
| `inscripcion_422_limite.json` | Cuarta inscripción activa de un alumno |
| `misCursos_200_en_espera.json` | `GET /inscripcion/misCursos` de un alumno en lista de espera |
| `gruposInscripcion_200.json` | `GET /gruposInscripcion`, un grupo. Trae `inscripcionesAbiertas` y `motivoInscripcion`, que la app no lee |

`GET /validarInscripcion` solo cuenta `INSCRITO`: en lista de espera responde `false`. Un 401 o un 403 llegan sin cuerpo.

## Fechas de estos archivos

Son fechas de una captura, no relativas a hoy. Una prueba que calcule si un grupo está abierto debe pasar su propia fecha `hoy` (por ejemplo, `DateTime(2026, 10, 29)`), no usar `DateTime.now()`.
