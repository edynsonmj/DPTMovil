# Informe de diagnóstico por pruebas: hallazgos de la app

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias` (commit `ed5abc7`, que incluye la corrección de CL-06) · Método: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md) · Evidencia detallada, escenario por escenario: [registro-bugs.md](registro-bugs.md)

Este informe reúne lo que encontró el diagnóstico de los módulos 1 a 9b, hecho con **pruebas unitarias**, **pruebas de integración local** (la cadena real de la app sobre un transporte HTTP falso) y **pruebas de integración contra el backend real** (BD de pruebas desechable en `localhost:8082`). El módulo 1 (toma de asistencias) tiene su propio informe: [informe-diagnostico-asistencias.md](informe-diagnostico-asistencias.md). Aquí solo se resume.

**Regla del diagnóstico:** un **hallazgo** es lo que demuestra una prueba **en rojo**. Lo que solo sale de leer el código va a la parte B como **hipótesis**, y una hipótesis cuya prueba salió verde queda **descartada**. La severidad se asigna por lo que la prueba demostró, no por lo que podría pasar.

## 1. Conclusión

- **50 hallazgos nuevos** en los módulos 2 a 9b, cada uno con su prueba en rojo, más los del módulo 1 que siguen abiertos. Contando los dos, **quedan 57 abiertos y 7 corregidos**.
- **Uno era grave y ya está corregido:** **CL-06**, una clase registrada con el selector de fecha se guardaba **un día antes**. La app ahora envía la fecha con zona. Se verificó contra el backend a las 00:00, 04:59, 05:00 y 23:30.
- **16 hallazgos abiertos de severidad media.** Son los que el usuario puede ver hoy:
  - Con un `&` en el título, una categoría no se puede editar ni borrar, y su curso y su grupo desaparecen de las listas (GR-03, GR-05, CU-02, CAT-03). Los cuatro tienen la misma causa y una sola corrección.
  - Tres fallos del backend: eliminar una clase no la borra (CL-01), el último día de un rango de estadísticas no cuenta (ES-05), y un alumno desvinculado sigue en la lista del grupo, a la que se toma asistencia (GR-06).
  - La pantalla "Instructores" del coordinador muestra **20 instructores inventados** (IT-03).
  - Errores que la pantalla oculta o confunde: inscripción e inscrito (IN-09, IN-10, IN-13) y toma de asistencias (AS-02, AS-03, AS-06, AS-07).
  - AS-01 (roles en la pantalla del grupo), aplazado por decisión.
- **El resto, 41, son de severidad baja.** Casi todos son **latentes**: la prueba los provoca con datos fabricados (un campo nulo, una respuesta sin cuerpo) que el backend actual no envía. La mayoría comparten dos causas: excepciones que atraviesan las capas y modelos que pierden campos.
- **El camino normal funciona.** Contra el backend real, cada módulo hace bien su ruta crítica: listar, crear, inscribir, registrar y leer estadísticas. **25 hipótesis de fallo quedaron descartadas** con pruebas en verde.

## 2. Qué se hizo

| Nivel | Qué se arma | Para qué |
|---|---|---|
| **U-Repo** | Repositorio con un doble de la conexión | Conversión modelo → entidad; los errores pasan sin cambios; nada lanza |
| **I-Local** | ViewModel → servicio → repositorio → conexión **real** → `AdaptadorHttpFalso`, con las respuestas observadas del backend (`test/contratos/`) | El flujo de la pantalla, sin red, con cortes, con respuestas raras y con datos incompletos |
| **I-Local (vista)** | Las rutas reales de `route_generator` con sus providers | Lo que ve el usuario. Una prueba de **control** en verde demuestra que el montaje es válido |
| **I-Remota** | ViewModel con su cadena real contra el **backend**. Cada corrida crea sus datos (categoría, curso, grupos, alumnos inscritos) en `setUpAll` | Lo que el backend guarda y devuelve de verdad |

**Recorrido:**
1. Para cada módulo se escribió un plan con sus hipótesis ([plan-diagnostico-*.md](.)) y se revisó el contrato publicado en `/v3/api-docs`.
2. Se recorrieron los datos reales de la BD de pruebas. Por ejemplo, los 142 grupos para ver cómo responde un grupo sin alumnos.
3. Las pruebas rojas van a `test/diagnostico/<modulo>/` con el ID del bug en el nombre. Las verdes van a las suites normales.

**Estado final de las suites:**

| Suite | Pruebas | Resultado |
|---|---|---|
| Sin backend (`test/unitarias`, `raiz_composicion_test.dart`, `test/integracion`) | 243 | todas en verde |
| Remota (`test/main_test.dart`, contra el backend) | 103 | todas en verde |
| Diagnóstico (`test/diagnostico`) | 77 | **74 en rojo a propósito**, 2 controles en verde, 1 omitida |
| `flutter analyze` | — | 0 errores, 31 warnings (los mismos que al empezar) |

## 3. Cifras por módulo

| # | Módulo | Escenarios | En rojo | Hallazgos | Hipótesis descartadas |
|---|---|---|---|---|---|
| 1 | Toma de asistencias | 23 unitarias + 5 de integración | 19 | AS-01 a AS-12 (ver su informe) | — |
| 2 | Clases | 19 | 6 | CL-01, CL-03 a CL-06 | 2 |
| 3 | Grupos | 24 | 8 | GR-01 a GR-06 | 4 |
| 4 | Inscripción del alumno | 14 en verde + 8 en rojo | 8 | IN-08 a IN-13 | 4 |
| 5 | Estadísticas | 20 | 5 | ES-01 a ES-05 | 4 |
| 6 | Horarios | 15 | 5 | HO-01 a HO-03 | 1 |
| 7 | Categorías | 23 | 10 | CAT-01 a CAT-06, CAT-09, CAT-13, CAT-14 | 1 |
| 8 | Cursos | 21 | 6 | CU-01 a CU-05 | 3 |
| 9a | Alumnos del grupo | 13 | 4 | AL-01 a AL-04 | 3 |
| 9b | Instructores y facultades | 22 | 7 | IT-01 a IT-03, FA-01 a FA-04 | 3 |

El número de rojas puede superar al de hallazgos: algunos hallazgos tienen más de una prueba, por ejemplo una local y otra contra el backend.

## 4. Parte A1: confirmados contra el backend real

Una prueba de integración con el backend los puso en rojo. Describen lo que el backend guardó o devolvió.

| ID | Sev. | Qué pasa | Evidencia | Resp. | Estado |
|---|---|---|---|---|---|
| **CL-06** | **A** | La clase elegida en el selector (00:00) se guardaba **el día anterior**. La app enviaba la hora local sin zona y el backend la tomaba como UTC | `enviada 2026-10-26 00:00`, guardada `2026-10-25` | app + backend | **corregido** en la app |
| CL-01 | M | **Eliminar una clase no la quita.** `DELETE /clase` responde 200, la app muestra éxito y la clase sigue en la pantalla del grupo con `eliminado: 0` | `sigue la clase 307 con eliminado 0` | backend | abierto |
| ES-05 | M | **El último día del rango de estadísticas no cuenta.** Una clase del 28 da 0 con el rango `[28, 28]` y 1 con `[28, 29]` | `Expected: <1>`, `Actual: <0.0>`; confirmado a mano | backend (o la app, enviando `fin + 1 día`) | abierto |
| GR-06 | M | **Un alumno desvinculado sigue en la lista del grupo**, la que se usa para tomar asistencia, aunque `validarInscripcion` dice que no está inscrito | `Expected: [A]`, `Actual: [A, B]` | backend | abierto |
| GR-05 | M | En un grupo cuya categoría o curso llevan `&`, la pantalla del grupo no ve nada. El curso da 404 y las clases y los alumnos salen vacíos **sin error**, aunque el grupo tiene una clase y un alumno | `curso: null (Código: 404 …); clases: 0; alumnos: 0` | app | abierto |
| GR-03 | M | Con `&` en la categoría, la lista de grupos del curso sale vacía | el backend recibe `prmCategoria=Fútbol ` | app | abierto |
| CU-02 | M | Con `&` (o `+`) en los títulos, los cursos de la categoría no se encuentran | el backend recibe `Fútbol ` y `Nivel 1   2` | app | abierto |
| CAT-03 | M | **Una categoría con `&` en el título no se puede editar ni eliminar**: el backend responde 404 "no existe" | `editar: Fallo 404`, `eliminar: Fallo 404` | app | abierto |
| IN-13 | M | Desvincular a un alumno no inscrito da 404 con **cuerpo vacío**, y el alumno vería un diálogo de error sin texto | `Expected: non-empty`, `Actual: ''` | backend + app | abierto |
| IN-08 | B | Un error al desvincular se etiqueta como `POST`, pero la petición es un `PUT` | `origen: POST …/desvincularInscripcion` | app | abierto |

Ya corregidos en este ciclo, con su prueba en verde: **AS-B01** (el backend publicó `/asistenciasClase` y la app se adaptó), **IN-07** (`validarInscripcion` con parámetros de query) y **AS-04** (desaparece con la nueva ruta de asistencias).

## 5. Parte A2: confirmados con pruebas locales

Los demostró una prueba unitaria o de integración local en rojo. Están agrupados por **causa**, porque cada grupo se corrige de una vez.

### 5.1 Lo que el usuario ve hoy (severidad media)

| ID | Qué pasa | Evidencia |
|---|---|---|
| **IT-03** | La pantalla "Instructores" del menú del coordinador es una **maqueta alcanzable**: muestra "Instructor 0" a "Instructor 19", todos "Activo", y no consulta el backend | `Found 1 widget with text "Instructor 0"`; su control está en verde |
| IN-09 | Si la validación de inscripción falla (sin red), el grupo aparece como **no inscrito y sin error**, y el botón dice "Matricular" | `Expected: not null`, `Actual: <null>` |
| IN-10 | Tras inscribirse (201), si la revalidación falla, el alumno ve "Te has inscrito" pero el botón vuelve a "Matricular" | `Expected: true`, `Actual: <false>` |
| AS-02 | Dos toques a "Guardar" asistencia mientras el primero sigue en camino envían **2** registros | 2 POST en la red |
| AS-03 | Tras una carga fallida, "Guardar" dice "No hay alumnos para registrar" y oculta el error real | `vista_diagnostico` · AS-03 |
| AS-07 | Un 201 sin cuerpo o un 204 al registrar la asistencia se muestran como **error**, aunque se guardó | `viewModel_diagnostico` · AS-07 |
| AS-06 | Una asistencia con `estaAtendido: null` lanza una excepción que escapa de la conexión | `conexion_diagnostico` · AS-06 |
| AS-01 | Si un alumno o un usuario sin sesión llega a la pantalla del grupo, ve "Agregar clase" y "Eliminar". **Aplazado por decisión** al módulo de roles | control en verde |

### 5.2 Llaves sin codificar en la URL (una sola corrección)

GR-03, GR-05, CU-02 y CAT-03, confirmados contra el backend en la parte A1. Las conexiones arman la URL concatenando títulos (`'/curso?categoria=$categoria'`) en lugar de usar `queryParameters`, así que un `&`, un `+` o un `#` cortan o cambian el valor. Es la misma corrección que ya resolvió IN-07.

### 5.3 Excepciones que atraviesan las capas (severidad baja, casi todas latentes)

La regla del proyecto es que los errores se **devuelven** como `RespuestaModelo` y no se lanzan entre capas. Las pruebas demuestran que no se cumple en tres puntos:

| Dónde | Hallazgos | Qué ve el usuario |
|---|---|---|
| Repositorio sin `try`, o con la llamada a la conexión fuera de él | GR-01, CU-01, CAT-13, CL-03, HO-02, AL-02, FA-02, ES-01, IN-12 | Una excepción en lugar de un error con código |
| Conexión que solo captura `Exception`, con `fromJson` ante un campo nulo | AS-06, ES-02, GR-04, CU-04, CAT-06, CL-05, HO-03, AL-04, FA-01 | El texto técnico `type 'Null' is not a subtype of type 'String'` en lugar de `Código: …` |
| Operador `!` sobre un dato opcional | CU-03, CAT-01, CL-04 | `Null check operator used on a null value` |

Son **latentes** porque el JSON incompleto lo fabrica la prueba: los datos reales revisados no traen esos nulos. Hay una excepción que sirve de referencia: la conexión de instructores sí captura todo (`catch (e)`) y su prueba equivalente sale verde.

### 5.4 Datos que se pierden o no se pueden enviar

| ID | Qué se pierde |
|---|---|
| GR-02 | `fechaFinalizacion` del grupo: el modelo no la copia y el `POST` no la envía, aunque el backend la acepta |
| HO-01 | El `id` del horario no llega a las tarjetas (`[null, null]`) |
| AL-01 | `codigo` e `imagen` del alumno no se leen (latente: hoy el backend los manda en `null`) |
| CAT-14 | Al crear una categoría con una imagen ya subida, el `imagenId` no viaja |
| IN-11 | Una inscripción con `fechaInscripcion` no se puede codificar en JSON (latente) |
| ES-03 | Un número entero en las estadísticas (`2` en vez de `2.0`) rompe la sección (latente) |

### 5.5 Errores mal presentados

| ID | Qué pasa |
|---|---|
| X-01 | `DialogError` recibe el código pero no lo muestra: sin red (503) y error del servidor (500) se ven igual |
| CU-05 | Un error al listar cursos abre **dos** diálogos seguidos ("Sin datos" y luego "datos inconsistentes") |
| CAT-05 | `cargarCategorias(context)` muestra cualquier error **con código 204** |
| CAT-02 | Un `POST /categoria` con 201 sin cuerpo se muestra como fallo, aunque se guardó (latente) |
| AS-12 | Un tiempo de espera agotado se reporta con código 0 en lugar de 408 |
| AL-03, IT-01, FA-03 | El 404 que el backend **documenta** para "lista vacía" se mostraría como error, con el JSON crudo. Hoy el backend responde de otra forma (`200` con `GC-0002`), así que es latente: el contrato y el comportamiento no coinciden |

### 5.6 Ciclo de vida y concurrencia

| ID | Qué pasa |
|---|---|
| CAT-09 | Dos cargas solapadas de categorías: la respuesta vieja **pisa** a la nueva (no hay contador de peticiones) |
| CAT-04, IT-02, FA-04 | El ViewModel notifica después de cerrar la pantalla (`was used after being disposed`). No usan `NotificacionSegura`. Solo salta en modo debug |
| AS-08 | Una asistencia de otra clase (`idClase: 999`) llega a la red sin validarse |

### 5.7 Otros

| ID | Qué pasa |
|---|---|
| ES-04 | El orden "de mayor a menor" de las estadísticas solo mira las horas: 1 h 10 min queda delante de 1 h 50 min |

## 6. Hipótesis descartadas (25)

Contra el backend real, el backend y la app se portan bien en esto:

| Módulo | Comprobado en verde |
|---|---|
| Clases | Eliminar una clase inexistente no se ve como éxito; una clase de hoy no se rechaza por la zona horaria |
| Grupos | No se crea un grupo con 0 cupos, ni con un curso o instructor inexistentes; el segundo grupo de un curso recibe un iterable nuevo; un curso o instructor sin grupos no da error |
| Inscripción | Desvincular a un no inscrito da 404; una inscripción duplicada o un cupo lleno dan 409; una inscripción desvinculada se puede reactivar; un alumno o grupo inexistente da 404 |
| Estadísticas | Una asistencia recién registrada se refleja; registrarla dos veces no la cuenta doble; los totales cuadran; un rango que no incluye la clase no la cuenta |
| Horarios | Un grupo sin horarios, o inexistente, deja la tarjeta vacía sin error |
| Cursos | No se crea un curso duplicado, ni con una categoría inexistente o con campos vacíos; una categoría sin cursos no da error |
| Alumnos | La lista trae los datos con que se registró cada alumno; no mezcla alumnos de grupos distintos; un grupo vacío o inexistente no da error |
| Instructores | La lista llega completa y sin ids repetidos; un alumno registrado no aparece como instructor; un instructor incompleto llega como error con código |

## 7. Parte B: por comprobar (no son hallazgos)

### Con el backend
- **Forma real del 404 de "lista vacía"** en `/alumnosGrupo`, `/instructores` y `/facultades`. `/v3/api-docs` lo documenta, pero el backend responde `200` con `GC-0002`, y no se puede vaciar ninguna de esas listas por la API para comprobarlo (AL-03, IT-01, FA-03).
- **Fechas sin zona:** desde la app ya no llegan así (CL-06), pero el backend las sigue tomando como UTC.
- **Mensajes de 404 sin cuerpo** en `POST /inscripcion` con alumno o grupo inexistente: podrían llegar vacíos, como IN-13.

### Con el cliente
- Si la asistencia se puede editar sin límite, o registrar en fechas futuras o muy antiguas (AS-13).
- Si los alumnos retirados o eliminados deben salir de la lista de asistencia (AS-11).
- Avisar de cambios sin guardar al salir de la toma de asistencias (AS-09, AS-10, requisitos propuestos).
- Dónde viven las fechas de inscripción: curso, grupo o categoría (IN-05).
- Si la pantalla "Instructores" se implementa o se oculta del menú hasta tenerla (IT-03).

### Solo leído en el código
- **CAT-11 y AL-V2:** `route_generator.dart` importa `views/Categorias/` y `views/alumnos/alumnosView.dart` con mayúsculas distintas a las del disco. En Windows compila, pero **no compilaría en Linux ni en macOS**. Ninguna prueba en Windows puede ponerlo en rojo.
- `AlumnosView` y `AlumnoView` son maquetas, pero no se llega a ellas (AL-V1).

## 8. Orden de corrección propuesto

| Lote | Hallazgos | Por qué en este orden |
|---|---|---|
| 1 | **GR-03, GR-05, CU-02, CAT-03** | Severidad media, visibles hoy, y una sola corrección (`queryParameters`) con pruebas ya escritas en local y contra el backend |
| 2 | **IN-09, IN-10, AS-02, AS-03, AS-06, AS-07** | Errores que la pantalla oculta en los dos flujos con más valor: inscribirse y tomar asistencia |
| 3 | **IT-03** | Necesita la decisión del cliente: implementar la pantalla o quitarla del menú |
| 4 | Errores mal presentados: **X-01, CU-05, CAT-05, IN-08, AS-12, CAT-02** | Cambios pequeños que mejoran lo que el usuario lee |
| 5 | Excepciones entre capas (5.3) y datos perdidos (5.4) | Muchos y latentes; dos patrones repetidos (un `try` en el repositorio y `catch (e)` en la conexión) |
| 6 | Ciclo de vida: **CAT-04, CAT-09, IT-02, FA-04** y **ES-04** | Severidad baja; `NotificacionSegura` y el contador de peticiones ya existen en otros VM |
| Backend | **CL-01, ES-05, GR-06, IN-13** y el contrato de los 404 | Van al equipo del backend. ES-05 también se puede rodear en la app |
| Al final | **AS-01, O-01, CAT-12** (roles y autenticación) | Decisión del 2026-10-29 |

Los 57 hallazgos abiertos están en el backlog de Jira como tareas de la Epic **SCRUM-39**, cada una con su lote. La tabla que relaciona cada ID con su tarea está al final de [registro-bugs.md](registro-bugs.md).

Cada corrección sigue la misma regla: su prueba diagnóstica pasa a verde, se mueve a la suite normal sin el prefijo `BUG` y el registro marca el hallazgo como *corregido*. Así se hizo con CL-06.

## 9. Cómo reproducir

```bash
flutter test test/unitarias test/raiz_composicion_test.dart test/integracion
```

```bash
flutter test test/main_test.dart
```

```bash
flutter test test/diagnostico
```

```bash
flutter test --plain-name "BUG GR-05"
```

La suite remota y los `remoto_diagnostico_test.dart` necesitan el backend en `localhost:8082`. Sin él fallan en `setUpAll`, y ese rojo no demuestra nada. Se ejecutan desde la raíz del proyecto.

## 10. Límites del diagnóstico

- **Alcance de rutas críticas:** se probó listar, crear, inscribir, registrar y consultar. Los casos especiales quedaron aplazados hasta que la app se estabilice.
- **Roles y autenticación no se diagnosticaron** (módulo 10), por decisión.
- **Los latentes dependen de datos que hoy no existen.** Se marcan así porque el backend actual no envía esos nulos ni esas formas. Si cambia, pasan a ser visibles.
- **BD de pruebas pequeña:** 1 instructor, 1 facultad y 142 grupos. Lo que dependa de volúmenes grandes no está cubierto.
- **Una prueba que monta una pantalla no demuestra que se pueda llegar a ella.** Por eso IT-03 se probó desde la ruta del menú del coordinador y AL-V1 quedó como observación.
- **No se probó en el emulador:** las pruebas de vista son de widget. CL-06 se verificó contra el backend; falta registrar una clase desde el formulario en el emulador.
