# Plan de diagnóstico: módulo 9a, Alumnos

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulos ya hechos: inscripciones, estadísticas, grupos, cursos, categorías, clases y horarios.

> **Estado al 2026-10-29: ejecutado.** 13 escenarios: 4 pruebas en rojo dan 4 hallazgos (AL-01 a AL-04), todos B y tres de ellos latentes. H-05 a H-07 quedan descartadas: contra el backend, cada grupo lista solo a sus alumnos y con los datos correctos. También se observó que `AlumnosView` y `AlumnoView` son maquetas inalcanzables. Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 9a».

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios.

## 1. Alcance

En la app, "alumnos" es la **lista de alumnos de un grupo**, la que ve el instructor en la pantalla del grupo y a la que se le toma asistencia:

```
Pantalla del grupo   DetalleGrupoViewModel._cargarAlumnos
                       → Servicioalumno → Alumnosrepositorio → Conexionalumnosremoto
                          GET /alumnosGrupo?categoria&curso&anio&iterable
```

Fuera de alcance:
- `Alumnosviewmodel`, que no tiene consumidores (se conserva por decisión).
- El registro de un alumno (`POST /RegistroPerfilAlumno`), que entra por `Servicioautenticacion` y es parte del módulo de autenticación, aplazado al final por decisión del 2026-10-29. Aquí solo se usa para preparar datos.
- La codificación de la URL: ya está confirmada como GR-05 contra el backend, también en `/alumnosGrupo`.
- Que el alumno desvinculado siga en la lista: ya está confirmado como GR-06.

Contrato (`/v3/api-docs`, 2026-10-29): `GET /alumnosGrupo` documenta `200` "Listado de alumnos del grupo" y **`404` "No existen alumnos para el grupo consultado"**.

Observado el 2026-10-29, recorriendo los 142 grupos de la BD de pruebas:
- **Grupos sin alumnos (70):** responden `200` con el objeto `GC-0002`, no `404` ni `[]`. La conexión lo convierte en 406 y `DetalleGrupoViewModel` lo trata como lista vacía.
- **Grupos con alumnos (72):** 112 alumnos, sin nulos en `id`, `tipo`, `nombre`, `correo`, `sexo` ni `tipoid`.
- **`codigo` e `imagen`:** llegan a `null` en los 112.

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `Alumnosrepositorio(ConexionalumnosFalsa)` | `test/unitarias/repositorio/alumnoRepositorio_test.dart` (nuevo; el caso feliz ya está en `horarioAlumnoInstructorRepositorio_test.dart`) |
| **I-Local** | `DetalleGrupoViewModel` (sección de alumnos) → `Conexionalumnosremoto` → `Dio(AdaptadorHttpFalso)`, con fixtures en `test/contratos/alumnos/` | `test/integracion/alumnos_integracion_test.dart` (nuevo) |
| **I-Remota** | `DetalleGrupoViewModel` contra el **backend**, con dos grupos propios y tres alumnos registrados e inscritos en `setUpAll` | `test/remoto/viewModel/alumno/vmAlumnoDiagnosticoTest.dart` (nuevo, en `main_test.dart`) |

Las rojas van a `test/diagnostico/alumnos/` con el prefijo `BUG AL-xx`.

## 3. Hipótesis

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Modelo | `Alumnomodelo.fromJson` no lee `codigo` ni `imagen`: la pantalla del grupo nunca los recibe. Es la causa de AS-05, vista desde la lista | I-Local: un alumno con `codigo` e `imagen` en el JSON los conserva |
| H-02 | Conexión → VM | El `404` que documenta el backend para un grupo sin alumnos se mostraría como error ("Código: 404") en lugar de lista vacía | I-Local: 404 documentado → lista vacía y sin error |
| H-03 | Conexión | Un alumno con un campo obligatorio nulo lanza un `TypeError` desde `fromJson` que atraviesa la conexión y el repositorio; la pantalla muestra el texto técnico | I-Local: error con el formato `Código: …` |
| H-04 | Repositorio | Un `TypeError` de la conexión atraviesa el repositorio (la llamada está fuera del `try`) | U-Repo con el doble lanzando |
| H-05 | Backend | La lista no trae los datos con los que el alumno se registró (nombre, correo, sexo, tipo de documento, tipo de alumno) | I-Remota |
| H-06 | Backend | Un alumno inscrito en otro grupo del mismo curso aparece también en este | I-Remota: cada grupo lista solo a sus alumnos |
| H-07 | Backend / VM | Un grupo sin alumnos, o inexistente, da error | I-Remota |
| H-08 | Modelo | `eliminadoestado` llega pero ni la entidad ni el VM lo usan; un alumno dado de baja se listaría | Sin prueba: no hay forma de dar de baja un alumno por la API, y GR-06 muestra que un desvinculado llega con `eliminadoestado: 0` |

## 4. Criterio de terminado

- Las pruebas ejecutadas; cada roja con su fila **AL-xx** y su archivo en `test/diagnostico/alumnos/`; cada hipótesis confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- Las suites normales siguen en verde y `flutter analyze` sin warnings nuevos.
