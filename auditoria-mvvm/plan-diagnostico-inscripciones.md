# Plan de diagnóstico: módulo 4, Inscripciones

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias` (tras eeab45e)
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md).

> **Estado al 2026-10-29: ejecutado.** 8 pruebas en rojo → 6 hallazgos (IN-08 a IN-13), todos M o B por lo probado. H-06 a H-09 descartadas; H-10 y tres hipótesis nuevas quedan sin verificar. Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 4: diagnóstico por pruebas».

**Regla de este módulo (decisión del usuario):** solo es **hallazgo** lo que demuestra una prueba **en rojo**, unitaria o de integración. Lo que sale de leer el código sin una prueba roja se anota en la lista de **hipótesis**, aparte, para verificarlo después. Una hipótesis cuya prueba sale verde se anota como **descartada**.

## 1. Alcance

Flujo del alumno (ruta `gruposDisponiblesInscripcion`, pantalla `Gruposinscripcion`):

```
Gruposinscripcion.initState
  → Gruposviewmodel.listarGruposDisponiblesInscripcion        GET /gruposInscripcion   (módulo de grupos, fuera de alcance)
  → Inscripcionviewmodel.cargarEstados(alumnoId, grupos)       GET /validarInscripcion?alumnoId&categoria&curso&anio&iterable  (uno por grupo)
botón "Matricular"       → agregarIncripcion   → Servicioinscripcion → Inscripcionrepositorio → Conexioninscripcionremoto  POST /inscripcion
botón "Quitar matrícula" → desvincularInscripcion → …                                                                       PUT  /desvincularInscripcion
tras un éxito → se vuelve a validar solo ese grupo
```

Fuera de alcance: las pantallas del coordinador (abrir, cerrar y programar; ya diagnosticadas y corregidas como IN-01 a IN-04) y la vista del alumno (este plan no incluye pruebas de widget).

Contrato publicado por el backend (`/v3/api-docs`, 2026-10-29):

| Ruta | Entrada | Respuestas documentadas |
|---|---|---|
| `POST /inscripcion` | `InscripcionDto` (`alumnoId`, `categoria`, `curso`, `anio`, `iterable`, todos obligatorios) | 201 registrada o **reactivada** · 409 sin inscripciones abiertas, sin cupos o ya inscrito · 404 alumno o grupo inexistente · 400 faltan datos |
| `PUT /desvincularInscripcion` | `InscripcionEntidad` (lo anterior + `fechaInscripcion`, `fechaDesvinculacion` como *date-time*, `eliminado`) | solo 200 documentado |
| `GET /validarInscripcion` | los 5 campos como query | 200 `boolean` |

## 2. Niveles de prueba de este módulo

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `Inscripcionrepositorio(ConexioninscripcionFalsa)` | `test/unitarias/repositorio/inscripcionRepositorio_test.dart` (se amplía) |
| **I-Local** | `Inscripcionviewmodel → Servicio → Repositorio → Conexioninscripcionremoto → Dio(AdaptadorHttpFalso)`: para las condiciones que el backend real no deja provocar (sin red, un fallo a mitad del flujo) | `test/integracion/inscripcion_integracion_test.dart` (nuevo) |
| **I-Remota** | La misma cadena contra el **backend real** (`localhost:8082`), con datos propios creados en `setUpAll` | `test/remoto/viewModel/inscripcion/vmInscripcionTest.dart` (nuevo, registrado en `main_test.dart`) |

Las pruebas que salgan rojas se mueven a `test/diagnostico/inscripciones/` con el prefijo `BUG IN-xx`, según la convención del proyecto.

## 3. Hipótesis de partida (lectura del código, aún no son hallazgos)

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Conexión | `eliminarInscripcion` hace un `PUT` pero etiqueta sus errores como `"POST"`: el `origen` del `Fallo` dice `POST …/desvincularInscripcion` | I-Local y I-Remota: desvincular con error → `origen` empieza por `PUT` |
| H-02 | VM | `validarInscripcion` convierte **cualquier** error en `false`: sin red, el alumno inscrito ve "Matricular" y nada indica el error. La prueba unitaria existente *"Validar - un error cuenta como no inscrito"* lo fija como esperado (señal D4) | I-Local: `cargarEstados` con la validación sin red → el estado del grupo lleva `error` |
| H-03 | VM | Tras inscribir con éxito, si la revalidación falla, el grupo queda como "no inscrito" aunque el diálogo dice "Te has inscrito" | I-Local: POST 201 + validación sin red → el estado no dice "no inscrito" |
| H-04 | Modelo / conexión | `Inscripcionmodelo.toJson` pone `DateTime` crudos en el mapa: una inscripción con `fechaInscripcion` o `fechaDesvinculacion` no se puede serializar a JSON | I-Local: inscribir con `fechaInscripcion` → el POST sale con la fecha en ISO 8601 |
| H-05 | Repositorio | El repositorio solo captura `Exception`: un `Error` (p. ej. `TypeError`) que suba de la conexión escapa de la capa | U-Repo: doble que lanza `TypeError` → se devuelve `RespuestaModelo` de error |
| H-06 | Backend / VM | Desvincular a un alumno que **no** está inscrito responde 200 y la app lo muestra como éxito | I-Remota |
| H-07 | Backend / VM | Inscribir dos veces al mismo alumno o pasarse del cupo del grupo no da 409 | I-Remota |
| H-08 | Backend / VM | Inscribir de nuevo tras desvincular (reactivar) no funciona | I-Remota |
| H-09 | Backend / VM | Alumno o grupo inexistente no da 404 | I-Remota |
| H-10 | Modelo | `Inscripcionmodelo.fromJson` asigna el texto de la fecha a un `DateTime?` → `TypeError`. **Nadie lo llama hoy** | Sin prueba en este plan: no está en el camino del repositorio ni del VM |

## 4. Pruebas a escribir

### 4.1 U-Repo (se espera verde salvo H-05)

| Caso | Afirma |
|---|---|
| Agregar, validar y eliminar con error de la conexión | La respuesta pasa sin cambios (`same`) |
| Agregar y eliminar con fechas | `fechaInscripcion` y `fechaDesvinculacion` llegan al modelo |
| H-05 | Un `TypeError` lanzado por la conexión se devuelve como `RespuestaModelo` de error, sin lanzar |

### 4.2 I-Local

| Caso | Afirma |
|---|---|
| Inscribir 201 → revalidar `true` | Un `POST /inscripcion` con los 5 campos del grupo y luego un `GET /validarInscripcion`; `Exito`; el grupo queda inscrito |
| Desvincular 200 | Sale un `PUT /desvincularInscripcion` con la inscripción en el cuerpo; `Exito`; el grupo queda no inscrito |
| Inscribir 409 | `Fallo(409)` con el mensaje del backend; no se revalida |
| Inscribir sin red | `Fallo(503)`; el botón deja de estar procesando |
| H-01, H-02, H-03, H-04 | Según la tabla 3 |

### 4.3 I-Remota (backend real)

Datos en `setUpAll`: una categoría, un curso, dos grupos (cupo 20 y cupo 1) con las inscripciones **abiertas** y dos alumnos registrados. Los casos dependen del orden, como los demás grupos remotos.

| Caso | Afirma |
|---|---|
| Inscribir y repetir (H-07) | 1.º `Exito` y validar `true`; 2.º `Fallo(409)` |
| Desvincular y reactivar (H-08) | Desvincular `Exito` → validar `false` → inscribir `Exito` → validar `true` |
| Desvincular sin estar inscrito (H-06) | `Fallo` |
| Cupo lleno (H-07) | Alumno A en el grupo de cupo 1 `Exito`; alumno B `Fallo(409)` |
| Alumno o grupo inexistente (H-09) | `Fallo(404)` |
| Error al desvincular (H-01) | `origen` del `Fallo` empieza por `PUT` |
| Cargar estados | Tras los casos anteriores, `cargarEstados` pinta inscrito donde el backend dice que lo está |

## 5. Criterio de terminado

- Las pruebas de 4.1 a 4.3 ejecutadas y su salida anotada.
- Cada prueba roja tiene su fila **IN-xx** en `registro-bugs.md` (sección «Módulo 4: diagnóstico por pruebas»), con el nombre de la prueba y el mensaje del fallo, y su archivo en `test/diagnostico/inscripciones/`.
- Cada hipótesis queda como *confirmada → IN-xx*, *descartada* o *sin verificar*.
- La suite sin backend sigue en verde y `flutter analyze` sin warnings nuevos (31).
