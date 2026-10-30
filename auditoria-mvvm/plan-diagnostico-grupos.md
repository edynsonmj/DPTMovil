# Plan de diagnóstico: módulo 3, Grupos

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulos anteriores: [inscripciones](plan-diagnostico-inscripciones.md), [estadísticas](plan-diagnostico-estadisticas.md).

> **Estado al 2026-10-29: ejecutado.** 24 escenarios: 8 pruebas en rojo dan 6 hallazgos (GR-01 a GR-06). Los dos más importantes son GR-06 (la lista de alumnos del grupo incluye al alumno desvinculado) y GR-03/GR-05 (un `&` en la categoría o el curso deja al grupo sin lista, curso, clases ni alumnos). H-06 a H-09 quedan descartadas. Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 3».

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios implementados.

## 1. Alcance

```
Curso → lista de grupos            Gruposviewmodel.listarGruposDe      GET  /gruposCurso?prmCategoria&prmCurso
Formulario de grupo                Gruposviewmodel.insertarGrupo       POST /grupo   (anio e iterable los calcula el backend)
Grupos asignados (instructor)      listarGruposInstructor              GET  /gruposInstructor?idInstructor
Pantalla del grupo                 DetalleGrupoViewModel.cargar
                                     curso     GET /curso?prmCategoria&prmCurso
                                     horarios  GET /horarios?categoria&curso&anio&iterable
                                     alumnos   GET /alumnosGrupo?…   (la lista a la que se toma asistencia)
                                     clases    GET /clasesGrupo?…
```

Todas las llaves de grupo de estas rutas se arman **concatenando** el texto en la URL. La única excepción es abrir y cerrar inscripciones, que usa `queryParameters`.

Fuera de alcance:
- Abrir, cerrar y programar inscripciones (`PeriodoInscripcionViewModel`), ya cubiertos en [plan-abrir-inscripciones.md](plan-abrir-inscripciones.md).
- `GET /gruposInscripcion`, que pertenece al módulo 4.
- Eliminar clases (`DELETE /clase`, módulo 2).
- Las vistas: no hay pruebas de widget en este plan.

Contrato (`/v3/api-docs`, 2026-10-29):
- `POST /grupo` recibe un `GrupoDto` y responde solo `201` documentado.
- Las listas responden `200`. Comprobado a mano: un curso sin grupos y un instructor inexistente dan `200 []`.
- `/alumnosGrupo` documenta además un `404`.

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `Gruporepositorio(ConexiongruposFalsa)` | `test/unitarias/repositorio/grupoRepositorio_test.dart` (se amplía) |
| **I-Local** | `Gruposviewmodel` / `Gruporepositorio` → `Conexiongruposremoto` → `Dio(AdaptadorHttpFalso)`: URIs exactas, cuerpo del POST y respuestas que el backend real no da | `test/integracion/grupos_integracion_test.dart` (nuevo) |
| **I-Remota** | `Gruposviewmodel` y `DetalleGrupoViewModel` con su cadena real contra el **backend**, con datos propios en `setUpAll` | `test/remoto/viewModel/grupo/vmGrupoDiagnosticoTest.dart` (nuevo, en `main_test.dart`) |

Las rojas van a `test/diagnostico/grupos/` con el prefijo `BUG GR-xx`.

## 3. Hipótesis de partida

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Conexión | `/gruposCurso` concatena categoría y curso sin codificar: con un `&` en el nombre no se encuentran los grupos | I-Local (URI enviada) + I-Remota (categoría y curso con `&` → la lista trae su grupo) |
| H-02 | Conexión (pantalla del grupo) | `/clasesGrupo`, `/alumnosGrupo` y `/horarios` concatenan la llave igual: en un grupo con `&` en el nombre la pantalla no ve sus clases ni sus alumnos | I-Remota con `DetalleGrupoViewModel` |
| H-03 | Repositorio | El repositorio no tiene `try`: un `TypeError` de la conexión lo atraviesa | U-Repo con el doble lanzando |
| H-04 | Conexión | Las tres listas solo capturan `Exception`: un grupo con un campo obligatorio nulo lanza un `TypeError` desde `GrupoModelo.fromJson` que atraviesa la conexión (a diferencia de `/gruposNoEliminados`, que sí lo captura) | I-Local: repositorio sobre la conexión real con un grupo sin `cupos` → `RespuestaModelo` de error, sin lanzar |
| H-05 | Repositorio / modelo | Al insertar, `GrupoModelo.fromEntidad` y `toJson` descartan `fechaFinalizacion` (era IN-06, sin prueba) | U-Repo (el modelo enviado la conserva) + I-Local (el JSON del POST la lleva) |
| H-06 | VM / backend | Se puede crear un grupo con **0 cupos**: el formulario solo exige dígitos, el VM no valida y quizá el backend tampoco | I-Remota: `insertarGrupo(cupos: 0)` no da 201 |
| H-07 | Backend | Un grupo de un curso inexistente o con un instructor inexistente se crea igual | I-Remota: no da 201 |
| H-08 | Backend | El segundo grupo de un curso no recibe un iterable nuevo | I-Remota: dos grupos con iterables distintos |
| H-09 | Conexión / VM | Un curso sin grupos o un instructor sin grupos dan error en lugar de lista vacía | I-Remota (visto a mano: `200 []`) |
| H-10 | Backend | La lista de alumnos del grupo sigue mostrando a un alumno desvinculado (es la lista a la que se toma asistencia) | I-Remota: inscribir A y B, desvincular B → solo A |
| H-11 | VM | `listarGruposDe` pone en `error` solo `mensaje`, sin código; un error con `mensaje` vacío deja `error == ''` | Sin prueba; es de presentación |

## 4. Criterio de terminado

- Las pruebas ejecutadas. Cada roja tiene su fila **GR-xx** y su archivo en `test/diagnostico/grupos/`; cada hipótesis queda confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- La suite sin backend y la remota siguen en verde (salvo lo ajeno a este módulo), y `flutter analyze` sin warnings nuevos en los archivos del módulo.
