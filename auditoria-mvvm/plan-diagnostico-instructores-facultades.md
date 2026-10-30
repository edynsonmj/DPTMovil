# Plan de diagnóstico: módulo 9b, Instructores y facultades

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulo anterior: [9a, alumnos](plan-diagnostico-alumnos.md).

> **Estado al 2026-10-29: ejecutado.** 22 escenarios: 7 pruebas en rojo dan 7 hallazgos (IT-01 a IT-03, FA-01 a FA-04). El más visible es IT-03: la pantalla "Instructores" del coordinador es una maqueta con 20 instructores inventados. Los demás son B y tres de ellos latentes. H-04, H-08 y H-09 quedan descartadas. Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 9b».

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios.

## 1. Alcance

Las dos listas solo se leen; la app no crea instructores ni facultades.

```
Formulario de grupo (coordinador)   InstructoresViewModel.listarYNotificarInstructores
                                      → ServicioInstructor → Instructoresrepositorio → Conexioninstructoresremoto
                                         GET /instructores
Registro del alumno                 Facultadesviewmodel.listarYNotificarFacultades
                                      → Serviciofacultades → Facultadesrepositorio → Conexionfacultadremoto
                                         GET /facultades
Menú del coordinador → Instructores Instructoresview (no lee ningún VM)
```

Fuera de alcance:
- Enviar el registro del alumno con la facultad elegida: es del módulo de autenticación, aplazado al final. Aquí solo se usa para preparar datos.
- Crear un grupo con el instructor elegido: ya lo cubre `VmModuloGrupoTest`.
- `InstructorView` (detalle de un instructor): solo se llega desde `Instructoresview`.

Contrato (`/v3/api-docs`, 2026-10-29):
- `GET /instructores`: `200` "Listado de instructores" y **`404` "No existen instructores registrados"**. `InstructorDto` = `{id, nombre, correo, sexo}`, todos `string`.
- `GET /facultades`: `200` "Listado de facultades" y **`404` "No existen facultades registradas"**. `FacultadDto` = `{nombre}`.

Observado el 2026-10-29 en la BD de pruebas:
- `/instructores`: `200` con **1** instructor, sin nulos en sus 4 campos, aunque hay más de cien alumnos registrados.
- `/facultades`: `200` con **1** facultad (`fiet`).
- No hay forma de vaciar ninguna de las dos listas por la API, así que el `404` documentado no se puede provocar contra el backend.

Leído en el código antes de probar:
- `Conexioninstructoresremoto` captura todo (`catch (e)`); `Conexionfacultadremoto` solo captura `Exception`.
- `Facultadesrepositorio` no tiene `try`; `Instructoresrepositorio` llama a la conexión fuera del `try`, pero su conexión no deja salir nada.
- Ninguno de los dos VM usa `NotificacionSegura`, y los dos se crean por ruta.

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `Instructoresrepositorio(ConexioninstructoresFalsa)` y `Facultadesrepositorio(ConexionfacultadesFalsa)` | `test/unitarias/repositorio/instructoresRepositorio_test.dart` (nuevo) y `facultadesRepositorio_test.dart` (se amplía) |
| **I-Local** | Cada VM → conexión real → `Dio(AdaptadorHttpFalso)`, con fixtures en `test/contratos/instructores/` y `test/contratos/facultades/` | `test/integracion/instructores_integracion_test.dart` y `facultades_integracion_test.dart` (nuevos) |
| **I-Local (vista)** | Ruta real `AppRutas.instructores` con la sesión del coordinador | `test/diagnostico/instructores/vista_diagnostico_test.dart` |
| **I-Remota** | `InstructoresViewModel` contra el **backend**, con un alumno registrado en `setUpAll` | `test/remoto/viewModel/instructor/vmInstructorDiagnosticoTest.dart` (nuevo, en `main_test.dart`) |

Las rojas van a `test/diagnostico/instructores/` (`BUG IT-xx`) y `test/diagnostico/facultades/` (`BUG FA-xx`).

## 3. Hipótesis

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Conexión → VM | El `404` documentado de "no hay instructores" se muestra en el formulario de grupo como error (`Código: 404 - …`) y no como lista vacía | I-Local |
| H-02 | Conexión → VM | Lo mismo con el `404` documentado de "no hay facultades" en el registro | I-Local |
| H-03 | Conexión | Una facultad con `nombre: null` lanza un `TypeError` en `fromJson` que atraviesa la conexión y el repositorio: el registro muestra el texto técnico | I-Local: error con el formato `Código: …` |
| H-04 | Conexión | Lo mismo con un instructor con `id: null` | I-Local (se espera verde: la conexión captura todo) |
| H-05 | Repositorio | Un `TypeError` de la conexión de facultades atraviesa `listarFacultades` (no hay `try`) | U-Repo con el doble lanzando. No se hace para instructores: su conexión real no deja salir un `TypeError`, y el doble no debe aceptar lo que la real no hace |
| H-06 | VM | Una carga que termina después de salir del formulario de grupo (instructores) o del registro (facultades) lanza al notificar | I-Local con la respuesta retenida |
| H-07 | Vista | La pantalla "Instructores" del menú del coordinador no muestra los instructores del backend | I-Local (vista) con la ruta real |
| H-08 | Backend | La lista de instructores llega con campos vacíos o ids repetidos; el desplegable pinta `nombre - id` | I-Remota |
| H-09 | Backend | Un alumno recién registrado aparece en la lista de instructores (se le podría asignar un grupo) | I-Remota |

## 4. Criterio de terminado

- Las pruebas ejecutadas; cada roja con su fila **IT-xx** o **FA-xx** y su archivo en `test/diagnostico/`; cada hipótesis confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- Las suites normales siguen en verde y `flutter analyze` sin warnings nuevos.
