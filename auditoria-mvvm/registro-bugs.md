# Registro de bugs del diagnóstico

Plan: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Cada fila pasa por estos estados: **hipótesis** → **confirmado** (la prueba de diagnóstico sale roja) → **corregido**, o bien **descartado** (la prueba sale verde).

- **Severidad:** A = pérdida o corrupción de datos, crash o acceso indebido; M = operación que falla o mensaje incorrecto; B = cosmético o de mantenimiento.
- **Responsable:** app, backend o cliente (regla de negocio por definir).
- **Origen de la evidencia:** de dónde sale lo que se afirma.
  - **Prueba:** una prueba ejecutada que afirma el comportamiento correcto y sale en rojo; el valor real queda en el síntoma. Las pruebas corren sobre dobles o sobre el adaptador falso con el contrato **propuesto**, nunca contra el backend real: demuestran lo que la app hace o envía, no lo que haría el servidor.
  - **API del backend:** comprobado contra el backend levantado (`/v3/api-docs` o una prueba remota).
  - **Emulador:** observado por el usuario en la app.
  - **Código:** solo lectura del código, sin prueba.
  - **Inferido / Supuesto / Propuesta:** la parte de la afirmación que la prueba no cubre (una consecuencia en el servidor, un código de respuesta que no existe todavía, una API sugerida).
- Las pruebas de diagnóstico se escribieron **a partir de hipótesis sacadas del código**. Un rojo confirma lo que se buscó; no garantiza que no haya otros fallos que no se buscaron.
- Las hipótesis de categorías (CAT-01 a CAT-12, T-01 a T-05, en el anexo A del plan) se probaron el 2026-10-29: ver «Módulo 7».

## Línea base (fase 0, 2026-10-28)

| Medida | Valor |
|---|---|
| Suite sin backend (`test/unitarias` + `raiz_composicion_test.dart`) | 82 pruebas, todas en verde |
| `flutter analyze` | 0 errores, 31 warnings, 301 infos |
| Backend (`/v3/api-docs`) | Levantado, 33 rutas. **Ninguna de atenciones o asistencias.** Sí publica `/estadisticas/*`, que agregan atenciones: el backend calcula estadísticas de asistencias que nadie puede registrar. |
| Cambio sin commit en `test/dobles/conexionautenticacionFalsa.dart` | Solo una línea en blanco; no afecta a las pruebas |

## Fase 1: infraestructura (2026-10-28)

| Pieza | Archivo |
|---|---|
| Transporte falso de Dio | `test/dobles/adaptadorHttpFalso.dart`, con su prueba de humo `test/unitarias/conexion/adaptadorHttpFalso_test.dart` (5 casos) |
| Etiqueta `diagnostico` | `dart_test.yaml` |
| Contrato propuesto | `test/contratos/atenciones/` (`LEEME.md`, 3 JSON) y `test/contratos/leerContrato.dart` |
| Doble de atenciones | `ConexionatencionesFalsa`: por defecto toma la lista del contrato, devuelve una copia por petición y tiene el gancho `antesDeRegistrar` |

Resultado:
- Suite sin backend: **87 pruebas en verde** (82 + 5 de humo).
- `flutter analyze`: 0 errores y 31 warnings, igual que la línea base. Las infos suben de 301 a 304, todas por `file_names`: los archivos nuevos siguen el camelCase del proyecto.

## Fase 2: limpieza de las pruebas existentes (2026-10-28)

| Paso | Prueba | Cambio | Resultado |
|---|---|---|---|
| 2.1 | E-12 `VmAtencionTest.prueba4BackendSinEndpoint` | Renombrada a `BUG AS-B01 - backend sin endpoints (fija el 404, no es lo esperado)`; el comentario aclara que su verde documenta un bug | Verde contra el backend real (las 4 remotas de atenciones) |
| 2.2 | E-02 (repo, registrar) | Afirma los 8 campos del alumno enviado, incluidos `codigo` e `imagen` | **Verde**: el repositorio **no** pierde datos. Por eso AS-05 se limita al modelo (`Alumnomodelo.fromJson` y `toJson`) y a la entidad (`Alumnoentidad` no tiene `eliminadoestado`), y se prueba en la fase 4 |
| 2.3 | E-01 (repo, listar), E-03 (VM), E-07/E-08 (vista) | Usan la lista del contrato (`listar_200.json`, 3 alumnos, uno ya marcado), sin modelos armados en la prueba. Afirman la lista completa de marcas, no solo un elemento | Verde |

Resultado:
- Suite sin backend: **87 pruebas en verde**.
- `flutter analyze`: 0 errores, 31 warnings, 304 infos (sin cambios).
- Ninguna prueba existente de asistencias se apoya ya en datos que solo inventa el doble.

## Fase 3: pruebas unitarias nuevas (2026-10-29)

Las 23 pruebas nuevas salieron **en verde**: en el camino normal y en el manejo de errores no apareció ningún bug nuevo.

| Capa | Archivo | Casos | Qué queda probado |
|---|---|---|---|
| Conexión | `test/unitarias/conexion/conexionAtencionesRemoto_test.dart` (nuevo) | 9 | URI del GET con los 5 parámetros · 200 lista → modelos · 200 `[]` sin error · 200 objeto → 406 · 404/500 con código, mensaje del backend y método · sin red → 503 · POST con `?idclase=210` y el cuerpo **idéntico** a `registrar_peticion.json` (si los modelos están completos) · POST 400/500 · POST sin red → 503 |
| Modelo | `test/unitarias/modelo/atencionModelo_test.dart` (nuevo) | 2 | Ida y vuelta de `Atencionmodelo` (`idClase`, `estaAtendido`) y `Alumnomodelo` (`id`, `tipo`, `nombre`, `correo`, `sexo`, `tipoid`) |
| Repositorio | `atencionesRepositorio_test.dart` | 2 | Los errores de listar y de registrar pasan sin cambios (`same`) |
| ViewModel | `atencionViewModel_test.dart` | 6 | Carga 404/500/503 → error con código y detalle, lista vacía · `200 []` sin error · un 200 tras un error limpia el error · registrar 400/500 → `Fallo` con código, mensaje y origen `POST /atenciones` · sin alumnos → `Fallo(0)` sin llamar a la red · se envía la última marca de cada alumno |
| Vista | `claseView_test.dart` | 4 | Error de carga pintado · "¡No hay alumnos aún!" · registro fallido → `DialogError`, la pantalla sigue con sus 3 checkbox · registro exitoso → diálogo y, al aceptar, vuelve a la pantalla anterior |

Resultado:
- Suite sin backend: **110 pruebas en verde** (87 + 23).
- `flutter analyze`: 0 errores y 31 warnings, sin cambios. Las infos pasan de 304 a 306, por `file_names` de los dos archivos nuevos.

Observación al escribir la prueba de registro fallido: `DialogError` recibe `codigo` pero **no lo muestra**. El usuario ve el título y el mensaje, nunca el código. Queda registrado como X-01 (transversal).

## Fase 4: diagnóstico (2026-10-29)

Se corre con `flutter test test/diagnostico`. Resultado al cerrar la fase 4: **17 en rojo** (bugs confirmados), 1 en verde (prueba de control) y 1 omitida (espera una regla del cliente). La fase 5 suma 2 rojas más. La suite normal sigue con 110 pruebas en verde. `flutter analyze`: 0 errores y 31 warnings; las infos suben de 306 a 308, solo por `file_names`.

| Archivo | Pruebas | Rojas |
|---|---|---|
| `test/diagnostico/atenciones/conexion_diagnostico_test.dart` | 7 (AS-04, AS-05 ×2, AS-06, AS-07 ×2, AS-12) | 7 |
| `test/diagnostico/atenciones/viewModel_diagnostico_test.dart` | 4 (AS-07 ×2, AS-08, AS-09) | 4 |
| `test/diagnostico/atenciones/vista_diagnostico_test.dart` | 6 (AS-01 ×3, control de AS-01, AS-02, AS-03) | 4. La prueba de control pasa (el montaje es válido) y la de AS-01c queda omitida |
| `test/diagnostico/transversal/dialogError_diagnostico_test.dart` | 2 (X-01, una por cada forma del diálogo) | 2 |

**Control de AS-01.** El instructor del grupo sí llega a la toma de asistencia en el mismo montaje. Eso prueba que el rojo de los otros casos viene de la app y no de un fallo de la prueba.

**AS-14 descartado** sin prueba, por los tipos: `Clasemodelo.fecha` es `DateTime` no nulo, así que ninguna clase llega a la lista con `fecha` nula por el camino de datos. El riesgo se traslada a `Clasemodelo.fromJson` con una fecha nula, que es del módulo 3 (clases).

## Fase 5: integración local (2026-10-29)

**Montaje** (`test/integracion/montajeAtenciones.dart`, compartido):
- Rutas **reales** de `route_generator`: "Mis grupos" → grupos asignados → grupo → clase. Cada ruta crea su VM como en la app.
- Cadena **real** de atenciones (`Atencionviewmodel` → servicio → repositorio → `Conexionatencionesremoto` → Dio), con el adaptador falso y las respuestas del contrato.
- Los demás módulos (grupos, horarios, curso, alumnos, clases) van con sus dobles.

| Archivo | Caso | Resultado |
|---|---|---|
| `test/integracion/atenciones_integracion_test.dart` | El instructor del grupo navega hasta la clase, marca a Ana y a Luis, desmarca a Marta y guarda. Se comprueba: GET con los 5 parámetros del grupo, exactamente `GET` y luego `POST`, cuerpo `[true, true, false]` con los 3 alumnos e `idclase=210`, diálogo de éxito y regreso a la pantalla del grupo | verde |
| ″ | Sin red al guardar → "Error al registrar atenciones" / "No hay conexion a internet"; el usuario sigue en la clase con sus marcas `[true, false, true]` | verde |
| ″ | 404 del backend al cargar → "Código: 404" en la clase, sin checkbox | verde |
| `test/diagnostico/atenciones/integracion_diagnostico_test.dart` | **AS-07** de punta a punta: POST 201 → el instructor ve "Error al registrar atenciones" con el texto `type 'Null' is not a subtype of type 'String'` | **rojo** |
| ″ | **AS-02** de punta a punta: doble toque con el primer POST retenido → **2** POST en la red | **rojo** |

Resultado:
- Suite sin backend + integración (`test/unitarias`, `raiz_composicion_test.dart`, `test/integracion`): **113 pruebas en verde**.
- `test/diagnostico`: 19 en rojo, 1 en verde (control) y 1 omitida.
- `flutter analyze`: 0 errores, 31 warnings y 309 infos (solo `file_names`).

AS-01 no se repitió de punta a punta. El alumno llega al grupo por cursos, no por grupos asignados, y la pantalla del grupo ya demostró el fallo en `vista_diagnostico`. Lo que sí confirma esta fase es que `route_generator` tampoco comprueba el rol al abrir `AppRutas.clase`.

## Fase 6: cierre y entregables (2026-10-29)

| Entregable | Para quién | Archivo |
|---|---|---|
| Informe de diagnóstico, con el resumen por severidad y el orden de corrección en 6 lotes | Equipo / docente | [informe-diagnostico-asistencias.md](informe-diagnostico-asistencias.md) |
| Contrato propuesto y 6 preguntas | Backend | [entregables/contrato-atenciones-backend.md](entregables/contrato-atenciones-backend.md) (los JSON de referencia están en `test/contratos/atenciones/`) |
| 6 preguntas de reglas de negocio | Cliente | [entregables/preguntas-cliente-asistencias.md](entregables/preguntas-cliente-asistencias.md) |

**Pendiente fuera de la app:**
- enviar los dos entregables;
- registrar las respuestas aquí, junto a AS-01c, AS-10, AS-11 y AS-13;
- la fase 7 (pruebas remotas) espera AS-B01.

## Transversales (afectan a varios módulos)

| ID | Capa | Síntoma observable | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| O-01 | Vista `CursosView` | **Explicado.** En el emulador (2026-10-29): desde categorías se entra y se ven los cursos, pero tocar un curso no lleva a ninguna vista. Causa: un bloqueo intencional por rol, porque [cursos.dart:183-187](../lib/presentation/view/views/curso/cursos.dart) solo navega a `AppRutas.curso` si el rol es coordinador; para alumno, instructor o sin sesión el `onTap` no hace nada. Al principio se pensó que el corte estaba en categorías, pero una prueba de widget mostró que categorías abre `/cursos` para todos los roles. Queda un problema de usabilidad: el `InkWell` muestra la animación del toque y no pasa nada, sin mensaje ni tarjeta deshabilitada, y el instructor tampoco ve el detalle del curso | Lectura del código (condición explícita `if (esCoordinador)`) | **Emulador + código.** El síntoma lo vio el usuario en el emulador y la causa sale de leer el código. Una prueba de widget temporal (ya borrada) solo comprobó que categorías abre `/cursos` para todos los roles; el toque sobre un curso no tiene prueba | B | cliente (¿alumno e instructor deberían ver el detalle del curso?) + app (señalar que no es navegable) | **explicado**: no es un fallo de navegación; queda como observación de usabilidad, con roles al final |
| X-01 | Widget `DialogError` | El parámetro `codigo` no se pinta en ninguna de las dos formas del diálogo ([dialogError.dart](../lib/presentation/view/widgets/dialogError.dart)). Un 503 (sin red) y un 500 (servidor) se ven igual salvo por el texto | `dialogError_diagnostico_test` ×2: no aparece `503` | **Prueba** | B | app | **confirmado** |

## Módulo 1: Toma de asistencias

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| AS-B01 | Backend | No existían `GET /atencionesporclase` ni `POST /atenciones` (404); la funcionalidad no se podía usar en ningún entorno. El 2026-10-29 el backend publicó `GET`/`POST /asistenciasClase?idClase=` con otra forma (`{alumno, asistio}` al leer, `{idPerfil, asistio}` al registrar) y la app se adaptó: conexión, modelo y contrato en `test/contratos/atenciones/` | `/v3/api-docs` del 2026-10-29; `VmAtencionTest.prueba4ClaseInexistente` (404 `GC-0003` para una clase que no existe); ciclo cargar → marcar → guardar → recargar comprobado a mano contra la clase 207 de la BD de pruebas | **API del backend + prueba remota** | A | backend + app | **corregido** (2026-10-29) |
| AS-01 | Navegación / roles | **Si llegan a la pantalla del grupo**, un alumno y un usuario sin sesión ven "AGREGAR CLASE" y el botón de eliminar clase, y abren la toma de asistencia: ni esa pantalla ni la ruta `clase` comprueban el rol. En la app (2026-10-29) el alumno **no llega** a esa pantalla: por el catálogo se queda en la lista de cursos, porque tocar un curso solo navega para el coordinador ([cursos.dart:184](../lib/presentation/view/views/curso/cursos.dart), ver O-01); en inscripciones solo ve los cursos a los que puede inscribirse; y el menú lateral muestra "grupos asignados" solo al instructor. Lo mismo vale sin sesión. Lo que falta es la comprobación en la pantalla y en la ruta (defensa en profundidad), no un camino abierto conocido. Que coordinador e instructor vean "AGREGAR CLASE" es lo esperado | `vista_diagnostico` · AS-01 alumno y AS-01 sin sesión (control en verde) | **Prueba + emulador.** La prueba monta la pantalla del grupo **directamente**, sin pasar por la navegación: demuestra lo que hace la pantalla, no que se pueda llegar a ella. Que no se llega sale de lo que observó el usuario en el emulador y de leer `cursos.dart` | A → **M** (no hay camino conocido en la interfaz) | app | **confirmado, aplazado por decisión**: roles y autenticación se tratan al final de la corrección de hallazgos. El caso del instructor ajeno al grupo espera la regla 3.4-1. Sus pruebas siguen en rojo como evidencia |
| AS-02 | Vista | Dos toques a "Guardar" mientras el primer envío sigue en camino → **2** registros enviados | `vista_diagnostico` · AS-02 (`Expected: <1>`, `Actual: <2>`); `integracion_diagnostico` · AS-02 (2 POST en la red) | **Prueba** (pantalla y de punta a punta). **Inferido:** que se dupliquen los registros en la base de datos depende de si un segundo POST reemplaza o agrega (pregunta 2 del contrato) | M (A si se confirma B-01) | app | **confirmado** |
| AS-03 | Vista / VM | Tras una carga con 500, "Guardar" sigue activo y muestra "No hay alumnos para registrar", lo que oculta el error real | `vista_diagnostico` · AS-03 | **Prueba** | M | app | **confirmado** |
| AS-04 | Conexión | Con categoría `Fútbol & Voleibol` el backend recibe `categoria=Fútbol ` (el `&` corta el valor), así que se pide otra clase | `conexion_diagnostico` · AS-04 | **Prueba** (la URI que sale de la app). **Inferido:** que el backend responda con otra clase o con ninguna; no hay backend con el que comprobarlo | M (A si se confirma B-02) | app | **corregido** (2026-10-29): con `/asistenciasClase` la app solo envía `idClase`, ya no viaja texto en la query. Su prueba salió del diagnóstico; `conexionAtencionesRemoto_test` fija la query `{idClase}` |
| AS-05 | Modelo | Al registrar, cada alumno se reenvía con `codigo: null` (había `'104619011001'`) e `imagen: null`, y un alumno retirado (`eliminadoestado: 1`) se reenvía como activo (`0`). Causas: `Alumnomodelo.fromJson` no lee `codigo` ni `imagen`, `toJson` fija `eliminadoestado: 0` y `Alumnoentidad` no tiene ese campo. El repositorio no es la causa (E-02 en verde) | `conexion_diagnostico` · AS-05 ×2 (cadena real completa) | **Prueba** (el JSON que la app envía). **Inferido:** que se borren datos o se reactiven alumnos depende de si el backend guarda el alumno que va dentro de cada asistencia (pregunta 3 del contrato). La causa (qué línea pierde cada campo) sale de leer el código | M (A si se confirma B-03) | app + backend | **descartado** (2026-10-29): el contrato real (`RegistroAsistenciaDto`) solo recibe `{idPerfil, asistio}`, así que el alumno ya no se reenvía y no hay datos que perder. Sus dos pruebas salieron del diagnóstico. La pérdida de `codigo`/`imagen` en `Alumnomodelo` sigue existiendo, pero ya no afecta a la asistencia |
| AS-06 | Conexión | Un JSON con `estaAtendido: null` provoca un `TypeError` (`'Null' is not a subtype of type 'bool'`) que **escapa** de la conexión | `conexion_diagnostico` · AS-06 | **Prueba.** El JSON incompleto lo fabrica la prueba; no se sabe si el backend real lo enviaría alguna vez | M | app | **confirmado** |
| AS-07 | Conexión → VM | **201 sin cuerpo:** la conexión lanza un `TypeError` (`'Null' is not a subtype of type 'String'`, al armar `ErrorModelo.mensaje`). **204:** la conexión devuelve un error. En ambos casos el VM devuelve `Fallo`, así que el usuario ve un error **aunque la asistencia se guardó** | `conexion_diagnostico` · AS-07 ×2; `viewModel_diagnostico` · AS-07 ×2; `integracion_diagnostico` · AS-07 (el usuario ve `type 'Null' is not a subtype of type 'String'`) | **Prueba** (lo que hace la app ante 201 y 204). **Supuesto:** que el backend responda 201 o 204; los endpoints no existen y el código de éxito está por acordar (pregunta 1 del contrato). Si responde 200, el fallo no se ve en uso real | M (A si se confirma B-04) | app + backend | **confirmado**. Es más grave de lo previsto: con 201 hay una excepción, no solo un mensaje equivocado |
| AS-08 | Repositorio | Una atención con `idClase: 999` en un registro de la clase 210 llega a la red (1 llamada) | `viewModel_diagnostico` · AS-08 | **Prueba.** La entrada inconsistente la fabrica la prueba; la pantalla actual siempre envía el mismo `idClase` | B | app | **confirmado** |
| AS-09 | VM | Tras un registro fallido, el VM no puede indicar que hay cambios sin guardar: no existe `hayCambiosSinGuardar` (`NoSuchMethodError`) | `viewModel_diagnostico` · AS-09 | **Prueba** de que la funcionalidad falta. **Propuesta:** el nombre y el comportamiento de `hayCambiosSinGuardar` son míos, no un requisito acordado | M | cliente | **requisito propuesto**: espera la respuesta C-08 del cliente; la prueba pide una API sugerida por el diagnóstico, no acordada |
| AS-10 | Vista | "Cancelar" o atrás descartan las marcas sin avisar | — | **Código + regla pendiente.** Leído en `claseView.dart`; sin prueba hasta conocer la regla del cliente | B | cliente | hipótesis (espera la regla 3.4-6) |
| AS-11 | Modelo / VM | Se listan alumnos eliminados o retirados | — | **Código + regla pendiente.** El VM no filtra por `eliminadoestado`; sin prueba | M | backend + cliente | hipótesis (espera la regla 3.4-4) |
| AS-12 | Conexión | `receiveTimeout` se reporta con código 0 en vez de 408 | `conexion_diagnostico` · AS-12 (`Actual: <0>`) | **Prueba** | B | app | **confirmado** |
| AS-13 | Reglas | Se puede registrar una clase futura o muy antigua, y editarla sin límite | — | **Código + regla pendiente.** No hay ninguna validación de fecha en el flujo; sin prueba | M | cliente | hipótesis (espera las reglas 3.4-2 y 3.4-3) |
| AS-14 | Vista (lista de clases) | Una clase con `fecha` nula revienta la lista de clases | Análisis de tipos: `Clasemodelo.fecha` no es nulo | **Código.** Descartado por los tipos, sin prueba | M | app | **descartado** (se revisa `Clasemodelo.fromJson` en el módulo 3) |

### Resumen del módulo 1

La severidad corresponde a **lo probado**. Las consecuencias que dependen del backend o del cliente están separadas en la parte B del [informe](informe-diagnostico-asistencias.md) (B-01 a B-11 y C-01 a C-08).

| Estado | A | M | B | Total |
|---|---|---|---|---|
| Confirmado por prueba (con dobles o con el adaptador falso) | — | 5 (AS-01, 02, 03, 06, 07) | 3 (AS-08, 12, X-01) | 8 |
| Corregido | 1 (AS-B01) | 1 (AS-04) | — | 2 |
| Requisito propuesto o regla del cliente | — | 3 (AS-09, 11, 13) | 1 (AS-10) | 4 |
| Descartado | — | 2 (AS-05, AS-14) | — | 2 |

**2026-10-29, endpoints de asistencia publicados:** según su descripción en `/v3/api-docs`, el POST sincroniza (inserta las marcadas nuevas y elimina las desmarcadas), así que AS-02 probablemente no duplica filas (pregunta 2), aunque sigue enviando dos POST. El éxito es `200` con resumen, así que AS-07 no se ve en uso real; su prueba sigue roja porque la app no acepta 201/204.

AS-02 y AS-07 suben a **A** si se confirman B-01 y B-04, respectivamente.

*(Hasta el 2026-10-29 este resumen contaba 11 confirmados con 6 de severidad A. Esas severidades daban por hechas consecuencias que ninguna prueba demostró.)*

**Decisión del 2026-10-29:** la gestión de roles y autenticación se trata **al final**, después de corregir los demás hallazgos. Quedan aplazados AS-01 (con AS-01c) y O-01. AS-01 baja de A a M porque, según el uso real de la app, el alumno no llega a la pantalla del grupo.

## Módulo 4: Inscripciones (hallazgos anticipados, 2026-10-29)

Salieron de las preguntas del usuario sobre el coordinador ("¿puede abrir inscripciones?", "¿puede abrir o cerrar fechas de inscripción de los cursos?"), **antes** de diagnosticar el módulo. Origen de la evidencia:
- **IN-01 a IN-03:** confirmados por prueba el 2026-10-29, en la fase 1 de [plan-abrir-inscripciones.md](plan-abrir-inscripciones.md).
- **IN-04:** se comprobó contra el backend.
- **IN-05 e IN-06:** siguen siendo solo lectura del código; sus pruebas se escriben cuando el plan de diagnóstico llegue al módulo 4.
- **IN-07:** confirmado por la suite remota el 2026-10-29, en la fase 5 de [plan-abrir-inscripciones.md](plan-abrir-inscripciones.md), y corregido el mismo día.
- **Regla nueva del backend (2026-10-29), no es un bug:** `POST /inscripcion` en un grupo sin inscripciones abiertas responde `409 GC-0012` ("El grupo no tiene inscripciones abiertas"). La fija `VmGruposInscripcionTest.prueba3SinInscripcionesAbiertas`.

| ID | Capa | Síntoma observable | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| IN-01 | Vista `InscripcionesGeneralesView` | "Abrir" y "Cerrar" inscripciones de una categoría piden confirmación, pero "Confirmar" solo cierra el diálogo ([inscripcionesGeneralesView.dart:164](../lib/presentation/view/views/inscripciones/inscripcionesGeneralesView.dart) y [:195](../lib/presentation/view/views/inscripciones/inscripcionesGeneralesView.dart), con `TODO`). No llama a ningún ViewModel ni servicio, y no avisa de que no pasó nada | `inscripciones/vista_diagnostico` · IN-01 Abrir y IN-01 Cerrar (por grupo): **0** PUT tras confirmar, sin excepción · IN-01 Generales: tras elegir categoría se ofrecen `[Abrir, Cerrar, Programar]` habilitados (con D1 no deben ofrecerse) | **Prueba** (rutas reales + `Serviciogrupo` real sobre el adaptador falso, 2026-10-29; control en verde). **Inferido:** que el coordinador crea que abrió o cerró las inscripciones | M | app + backend | **corregido** (2026-10-29, fase 4 de [plan-abrir-inscripciones.md](plan-abrir-inscripciones.md)); su prueba pasó a verde sin cambios y está en `test/unitarias/vista/inscripcionesCoordinador_test.dart` |
| IN-02 | Vistas de inscripciones (generales y particulares) | "Programar" abre el selector de rango de fechas, pero la selección solo se imprime en consola (generales, [:116-118](../lib/presentation/view/views/inscripciones/inscripcionesGeneralesView.dart)) o no hace nada (particulares, [:182](../lib/presentation/view/views/inscripciones/inscripcionesParticulares.dart)), con `TODO` | `inscripciones/vista_diagnostico` · IN-02: elegida la fecha de hoy y confirmados los dos diálogos, **0** PUT `/abrirInscripcionesGrupo`, sin excepción · en Generales, cubierto por IN-01 Generales | **Prueba** | M | app + backend | **corregido** (2026-10-29, fase 4 del plan); su prueba pasó a verde sin cambios y está en `test/unitarias/vista/inscripcionesCoordinador_test.dart` |
| IN-03 | Vista `InscripcionesParticularesView` | La lista de grupos es **ficticia**: siempre 20 tarjetas, de "grupo 0" a "grupo 19" ([:115](../lib/presentation/view/views/inscripciones/inscripcionesParticulares.dart)), no traídas del backend. El estado "Cerradas"/"abiertas" se alterna según la posición par o impar ([:124](../lib/presentation/view/views/inscripciones/inscripcionesParticulares.dart)), y el diálogo de cada grupo dice siempre "cerrado" ([:128](../lib/presentation/view/views/inscripciones/inscripcionesParticulares.dart)). Abrir, Cerrar y Programar se comportan como en IN-01 e IN-02 | `inscripciones/vista_diagnostico` · IN-03: no pide `GET /gruposNoEliminados`, muestra "grupo 0", no muestra los cursos del backend y pinta 20 tarjetas en vez de 3 | **Prueba.** **Inferido:** que el coordinador tome por reales los grupos y estados mostrados | M | app | **corregido** (2026-10-29, fase 4 del plan); su prueba pasó a verde sin cambios y está en `test/unitarias/vista/inscripcionesCoordinador_test.dart` |
| IN-04 | Backend | ~~No hay endpoints para abrir, cerrar o programar inscripciones.~~ **Actualizado el 2026-10-29:** el backend ya publica `PUT /abrirInscripcionesGrupo` y `PUT /cerrarInscripcionesGrupo` **por grupo** (36 rutas). `/gruposInscripcion` ahora filtra por el periodo de inscripción. Sigue sin haber endpoint **por categoría** | `/v3/api-docs` del 2026-10-29; peticiones manuales contra el backend (ver [plan-abrir-inscripciones.md](plan-abrir-inscripciones.md), 1.1) | **API del backend** | M | backend | **corregido por grupo**; por categoría, pendiente (decisión D1 del plan) |
| IN-05 | Modelo de curso | `CursoModelo` y `CursoEntidad` no tienen ningún campo de fecha: un curso no puede guardar cuándo abren o cierran sus inscripciones | — | **Código** | M | cliente + backend + app | **funcionalidad inexistente**. Falta definir con el cliente si las fechas de inscripción van por curso, por grupo o por categoría |
| IN-06 | Modelo / formulario de grupo | `fechaCreacion` la fija la app con la fecha del día ([GrupoFormulario.dart:243](../lib/presentation/view/views/grupo/GrupoFormulario.dart)). `fechaFinalizacion` existe en `GrupoModelo` y se lee del backend, pero el formulario no la pide y `toJson` no la envía ([grupoModelo.dart:59-70](../lib/data/models/grupoModelo.dart)): la app no puede fijar cuándo termina un grupo. Ninguna de las dos es una fecha de inscripción | — | **Código** | B | app | **confirmado como GR-02** (2026-10-29, módulo 3): el modelo y el JSON del POST pierden `fechaFinalizacion` |
| IN-07 | Conexión | **Confirmado el 2026-10-29.** El backend cambió `GET /validarInscripcion`: ahora exige `alumnoId`, `categoria`, `curso`, `anio` e `iterable` como **parámetros de query** (`/v3/api-docs`). La app los sigue mandando en el **cuerpo del GET** ([ConexionInscripcionRemoto.dart:47-51](../lib/data/api/conexion/remoto/ConexionInscripcionRemoto.dart)); el backend responde `400 MissingServletRequestParameterException` y `Inscripcionviewmodel.validarInscripcion` lo convierte en `false`. Efecto: tras inscribirse con éxito, la pantalla del alumno sigue mostrando "Matricular" | `VmGruposInscripcionTest.prueba4CicloInscripcion` (remota): inscribir → `Exito`, pero validar después → `false` (`Expected: true`, `Actual: false`). Petición manual: con cuerpo y sin query → 400; con query → 200 | **Prueba (remota) + API del backend.** **Inferido:** que el alumno, al ver "Matricular", vuelva a intentarlo y reciba el 409 de "ya está inscrito" (según la descripción del endpoint; no probado) | M | app | **corregido** (2026-10-29): `validarInscripcion` envía la inscripción con `queryParameters`, sin cuerpo, y una respuesta que no es booleana se devuelve como error. Pruebas: `test/unitarias/conexion/conexionInscripcionRemoto_test.dart` (4) y el ciclo remoto otra vez en verde (suite remota 65/65) |

Relacionados ya registrados: estas dos pantallas cargan las categorías con `cargarCategorias(context)`, de estilo antiguo (CAT-04 y CAT-05 en el anexo A del plan).

## Módulo 4: diagnóstico por pruebas de la inscripción del alumno (2026-10-29)

Plan: [plan-diagnostico-inscripciones.md](plan-diagnostico-inscripciones.md). **Regla de este módulo:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a la lista de hipótesis, más abajo.

Backend levantado (`/v3/api-docs`: `POST /inscripcion`, `PUT /desvincularInscripcion`, `GET /validarInscripcion`).

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/inscripcionRepositorio_test.dart` (+4 casos) | 4 | — |
| U-Repo (diagnóstico) | `test/diagnostico/inscripciones/repositorio_diagnostico_test.dart` | — | 2 (IN-12) |
| I-Local: VM → conexión real → transporte falso | `test/integracion/inscripcion_integracion_test.dart` (nuevo) | 4 | — |
| I-Local (diagnóstico) | `test/diagnostico/inscripciones/integracion_diagnostico_test.dart` | — | 4 (IN-08, 09, 10, 11; IN-08, IN-09 e IN-10 corregidos y movidos a la suite de integración el 2026-11-05) |
| I-Remota: VM → backend real | `test/remoto/viewModel/inscripcion/vmInscripcionTest.dart` (nuevo, en `main_test.dart`) | 6 | — |
| I-Remota (diagnóstico) | `test/diagnostico/inscripciones/remoto_diagnostico_test.dart` (**necesita el backend**) | — | 2 (IN-08, IN-13; IN-08 corregido y movido a la suite remota el 2026-11-05) |

Resultado:
- Suite sin backend: **168 en verde** (antes 160).
- Suite remota: **71 en verde** (antes 65).
- `test/diagnostico/inscripciones`: 8 en rojo.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios); 318 infos (+1, `file_names`).

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| IN-08 | Conexión | Un error al desvincular se etiqueta como `POST`, pero la petición que sale es un `PUT`: el `origen` del `Fallo` es `POST …/desvincularInscripcion`. Causa: `metodo = "POST"` en [ConexionInscripcionRemoto.dart:81](../lib/data/api/conexion/remoto/ConexionInscripcionRemoto.dart) | `integracion_diagnostico` · IN-08 (500 programado; `Actual: 'POST http://falso/api/v2/desvincularInscripcion'`); `remoto_diagnostico` · IN-08 (grupo inexistente contra el backend real; `Actual: 'POST http://localhost:8082/api/v2/desvincularInscripcion'`) | **Prueba** (sin backend y contra el backend real) | B | app | **corregido** (2026-11-05): `eliminarInscripcion` etiqueta el error con `PUT`, el método que envía. Las dos pruebas pasaron a verde: la local a `test/integracion/inscripcion_integracion_test.dart` y la remota a la suite remota (`VmInscripcionTest.prueba6OrigenDelError`, llamada desde `main_test.dart`) |
| IN-09 | VM | Si la validación no se puede hacer (sin red), el grupo queda como **no inscrito**, sin error: `datos: false`, `error: null`. La pantalla pinta "Matricular" y nada indica que la consulta falló | `integracion_diagnostico` · IN-09 (`Expected: not null`, `Actual: <null>`) | **Prueba.** **Inferido:** que un alumno ya inscrito pulse "Matricular" y reciba el 409 de "ya inscrito" | M | app | **corregido** (2026-11-05): `Inscripcionviewmodel` guarda el error de la consulta en el estado del grupo (`_consultar`), y la tarjeta muestra «No se pudo consultar tu inscripción» con un botón «Reintentar» en lugar de «Matricular». La prueba pasó a `test/integracion/inscripcion_integracion_test.dart`, y dos `testWidgets` nuevos en `test/unitarias/vista/gruposInscripcionView_test.dart` cubren la tarjeta |
| IN-10 | VM | Tras un `POST /inscripcion` con 201, si la revalidación falla, el VM devuelve `Exito` (diálogo "Te has inscrito al grupo") pero deja el grupo como **no inscrito** (`datos: false`, `error: null`): el botón vuelve a decir "Matricular". Misma causa que IN-09 (`validarInscripcion` convierte el error en `false`) | `integracion_diagnostico` · IN-10 (`Expected: true`, `Actual: <false>`) | **Prueba** | M | app | **corregido** (2026-11-05): tras un 201 (o un 200 al desvincular), si la revalidación falla el grupo queda con el resultado esperado y el error, y la tarjeta muestra el aviso con «Reintentar» en lugar de volver a «Matricular». La prueba pasó a `test/integracion/inscripcion_integracion_test.dart` |
| IN-11 | Modelo / conexión | Una inscripción con `fechaInscripcion` no se puede enviar: el VM devuelve `Fallo(0, "null")`. Causa probable: `Inscripcionmodelo.toJson` pone el `DateTime` sin convertir y el JSON no se puede codificar | `integracion_diagnostico` · IN-11 (`Fallo 0 null (POST …/inscripcion)`) | **Prueba.** La entrada con fecha la fabrica la prueba: la pantalla actual **nunca** pone fechas, así que hoy no se ve en uso real. La causa sale de leer el código | B | app | **confirmado** (latente) |
| IN-12 | Repositorio | Un `TypeError` lanzado por la conexión **escapa** del repositorio (`agregarInscripcion` y `eliminarInscripcion` solo capturan `Exception`), cuando la regla del proyecto es devolver los errores | `repositorio_diagnostico` · IN-12 ×2 (`Instance of 'TypeError'`) | **Prueba.** El `TypeError` lo lanza el doble. **Inferido:** la conexión real puede lanzarlo ante un 2xx distinto del esperado y sin cuerpo (mismo mecanismo que AS-07); el VM lo atrapa y lo muestra como mensaje técnico (`Fallo(-1, …)`) | B | app | **confirmado** |
| IN-13 | Backend → VM | Desvincular a un alumno que no está inscrito da `404` con el **cuerpo vacío** y el `Fallo` llega con `mensaje: ''`. El alumno vería un diálogo de error sin texto (y sin código, X-01) | `remoto_diagnostico` · IN-13 (`Expected: non-empty`, `Actual: ''`; `Fallo 404  (POST …)`) | **Prueba contra el backend real.** Que el diálogo salga vacío se deduce de `DialogError` (pinta `mensaje`); no hay prueba de widget | M | backend (404 sin cuerpo) + app (sin texto por defecto cuando el mensaje viene vacío) | **confirmado** |

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-06 | Desvincular a un alumno no inscrito responde 200 y se ve como éxito | `vmInscripcionTest` · Desvincular sin inscripción → `Fallo 404` (su mensaje vacío es IN-13) |
| H-07 | Inscripción duplicada o cupo lleno no dan 409 | `vmInscripcionTest` · segunda inscripción → 409; segundo alumno en un grupo de cupo 1 → 409 |
| H-08 | No se puede reactivar una inscripción desvinculada | `vmInscripcionTest` · desvincular → validar `false` → inscribir `Exito` → validar `true` |
| H-09 | Alumno o grupo inexistente no dan 404 | `vmInscripcionTest` · ambos → 404 |

También salieron en verde los caminos normales: 201 envía los 5 campos del grupo y revalida, `PUT` con la inscripción en el cuerpo, 409 con el mensaje del backend sin revalidar, sin red → 503 y el botón se libera, los errores pasan por el repositorio sin cambios (`same`) y las fechas llegan al modelo.

### Hipótesis sin verificar (no son hallazgos)

| Hip. | Capa | Hipótesis | Por qué no se probó |
|---|---|---|---|
| H-10 | Modelo | `Inscripcionmodelo.fromJson` asigna el texto de la fecha a un `DateTime?` → `TypeError` | Nadie lo llama: no está en el camino del repositorio ni del VM |
| H-12 | Backend → VM | Los 404 de `POST /inscripcion` (alumno o grupo inexistente) también llegan sin mensaje, como IN-13 | La prueba remota solo comprobó el código 404 |
| H-13 | Pruebas | La prueba unitaria `Validar - un error cuenta como no inscrito` (`gruposInscripcionViewModel_test.dart`) fija como esperado el comportamiento que causa IN-09 y IN-10 (señal D4) | Es una observación sobre la prueba; se revisa al corregir IN-09 |
| H-14 | VM | `cargarEstados` no descarta respuestas viejas si se vuelve a cargar mientras hay validaciones en camino | La pantalla carga una sola vez (`initState`); no hay camino de recarga que probar |

## Módulo 5: diagnóstico por pruebas de las estadísticas generales (2026-10-29)

Plan: [plan-diagnostico-estadisticas.md](plan-diagnostico-estadisticas.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

Backend levantado. `/v3/api-docs` publica `/estadisticas/{categorias,cursos,grupos,alumnos,instructores}` y, **desde ahora, `GET` y `POST /asistenciasClase`**: el backend ya tiene endpoints de asistencia, aunque con rutas distintas a las que usa la app (ver AS-B01). Aquí `POST /asistenciasClase` solo se usa para **sembrar** datos de prueba.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/estadisticasRepositorio_test.dart` (+5 casos) | 5 | — |
| U-Repo (diagnóstico) | `test/diagnostico/estadisticas/repositorio_diagnostico_test.dart` | — | 1 (ES-01) |
| I-Local: VM → conexión real → transporte falso | `test/integracion/estadisticas_integracion_test.dart` (nuevo; fixtures en `test/contratos/estadisticas/`) | 5 | — |
| I-Local (diagnóstico) | `test/diagnostico/estadisticas/integracion_diagnostico_test.dart` | — | 3 (ES-02, 03, 04) |
| I-Remota: VM → backend real | `test/remoto/viewModel/estadisticas/vmEstadisticasAsistenciaTest.dart` (nuevo, en `main_test.dart`) | 5 | — |
| I-Remota (diagnóstico) | `test/diagnostico/estadisticas/remoto_diagnostico_test.dart` (**necesita el backend**) | — | 1 (ES-05) |

Resultado:
- Suite sin backend: **178 en verde** (antes 168), medido antes de que empezara en el mismo árbol la migración de atenciones a `/asistenciasClase`. Con esa edición a medias fallan 5 pruebas de atenciones y `flutter analyze` da 2 errores, en `conexionatencionesFalsa.dart` y `atencionModelo_test.dart`. Ninguno es de este módulo.
- Suite remota: **76 en verde** (antes 71).
- `test/diagnostico/estadisticas`: 5 en rojo.
- `flutter analyze` sobre los archivos de este módulo: sin errores ni warnings, solo infos de `file_names`.

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| ES-01 | Repositorio | `EstadisticasRespositorio` no tiene ningún `try`: un `TypeError` de la conexión lo atraviesa en las tres rutas | `repositorio_diagnostico` · ES-01 (`Instance of 'TypeError'`) | **Prueba.** El `TypeError` lo lanza el doble; ES-02 demuestra que la conexión real también lo deja pasar | B | app | **confirmado** |
| ES-02 | Modelo / conexión | Una fila con `leyenda1: null` hace que la sección muestre el texto de la excepción (`type 'Null' is not a subtype of type 'String'`) en lugar de un error con código: `fromJson` lanza un `TypeError`, la conexión solo captura `Exception`, el repositorio no captura nada (ES-01) y lo atrapa el `catch` del VM | `integracion_diagnostico` · ES-02 (`Expected: a string starting with 'Código: '`) | **Prueba.** La fila incompleta la fabrica la prueba: el backend real siempre manda `leyenda1` | B | app | **confirmado** |
| ES-03 | Modelo | Un número entero en el JSON (`"clases": 2` en vez de `2.0`) rompe la sección con `type 'int' is not a subtype of type 'double'`: `fromJson` asigna `json['clases']` (y `horas`, `minutos`, `duracion`) directamente a un `double` | `integracion_diagnostico` · ES-03 (`Expected: null`, `Actual: "type 'int' is not a subtype of type 'double'"`) | **Prueba.** Hoy el backend manda `1.0`; si cambia a `Integer`, o un serializador omite el `.0`, las tres gráficas fallan | B | app | **confirmado** (latente) |
| ES-04 | VM | El orden "de mayor a menor" solo mira `horas`: 1 h 10 min queda **delante** de 1 h 50 min (`_ordenarPorHoras` compara `b.horas` con `a.horas`) | `integracion_diagnostico` · ES-04 (`at location [0] is 'Una hora y diez' instead of 'Una hora y cincuenta'`) | **Prueba** | B | app | **confirmado** |
| ES-05 | Backend | **El último día del rango no cuenta.** Una clase del 2026-10-28 (`fecha` guardada `2026-10-28`) da 0 clases con el rango `[2026-10-28, 2026-10-28]` y también con `[2026-10-27, 2026-10-28]`; con `[2026-10-28, 2026-10-29]` cuenta 1 clase y 120 min. El coordinador que pide "octubre" (hasta el 31) no ve las clases del 31 | `remoto_diagnostico` · ES-05 (`Expected: <1>`, `Actual: <0.0>`); confirmado a mano con las tres peticiones al backend | **Prueba contra el backend real.** **Inferido:** la causa probable es que se compara un *date-time* con `fin` a las 00:00; no se ha visto el código del backend | M | backend (o la app, enviando `fin + 1 día`, si se acuerda así) | **confirmado** |

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-06 | Las estadísticas no reflejan una asistencia recién registrada | `vmEstadisticasAsistenciaTest` · prueba1: 1 clase y 120 min en categoría, curso y grupo |
| H-07 | Repetir el registro de la misma asistencia la cuenta dos veces | prueba5: tras repetir el POST, siguen 1 clase y 120 min |
| H-08 | Los totales no cuadran | prueba2: en las 3 secciones y en toda la BD de pruebas, `horas × 60 + minutos == duracion`, cada categoría suma sus cursos y cada curso suma sus grupos |
| H-09 | Un rango que no incluye la clase la cuenta igual | prueba4: la categoría nueva queda en 0 |

También salieron en verde:
- La carga de las tres secciones con el contrato: la query lleva `inicio` y `fin` exactos y las filas se ordenan.
- `200 []` → secciones vacías y sin exportación.
- Sin red → `Código: 503` en las tres secciones.
- 400 en texto plano → código y texto del backend.
- 200 con un objeto → 406.
- En el repositorio: conversión de categorías y cursos, lista vacía, errores sin cambios y "sin lista" → 0 en cursos y grupos.

### Hipótesis sin verificar (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no se probó |
|---|---|---|---|
| H-10 | Backend / cliente | Un rango sin clases devuelve todas las categorías en 0, no una lista vacía; `prueba3RangoSinClases` lo fija (señal D4) | Es una regla del cliente: no hay un comportamiento correcto definido que afirmar |
| H-11 | Backend | Un rango invertido (`inicio > fin`) devuelve las categorías con ceros (visto a mano con `[2030-01-01, 2020-12-31]`; no se anotó el código) en lugar de un 400 | La pantalla no deja elegirlo: el selector de la fecha final empieza en la inicial |
| H-12 | Backend / cliente | **Observado:** con 2 asistencias en una clase de 2 h, la categoría da `clases 1.0, duracion 120.0`, lo mismo que con 1 asistencia. Las estadísticas parecen contar **clases dictadas**, no asistencias (el `summary` del backend dice "atenciones brindadas") | Hay que confirmar con el cliente qué debe medir la gráfica |
| H-13 | Backend / cliente | Si se cuentan clases dictadas (H-12), una clase **sin ninguna asistencia** quizá también suma horas | Depende de la respuesta a H-12 |
| H-14 | Conexión | Las fechas van concatenadas en la ruta sin codificar (`?inicio=$fechaInicio&fin=$fechafin`) | La pantalla siempre manda `yyyy-mm-dd` (`FormatDate`), que no necesita codificarse |
| H-15 | Conexión | `institucionalFacultades` e `institucionalProgramas` lanzan `UnimplementedError` | No tienen ningún llamador en el flujo diagnosticado |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | Categorías 200 → entidades, `leyenda2` nula, `duracion` conservada | ✅ |
| 2 | U-Repo | Cursos 200 → entidades con categoría y curso, `horas` y `minutos` | ✅ |
| 3 | U-Repo | `200 []` en las 3 rutas → lista vacía de entidades, código 200, sin error | ✅ |
| 4 | U-Repo | 503 en categorías y 500 en grupos → la respuesta pasa sin cambios (`same`) | ✅ |
| 5 | U-Repo | 200 sin lista en cursos y grupos → código 0, con la `url` de cada ruta | ✅ |
| 6 | U-Repo | La conexión lanza un `TypeError` → error devuelto, sin lanzar (3 rutas) | ❌ ES-01 |
| 7 | I-Local | Carga con el contrato: 3 GET con `inicio` y `fin` exactos; secciones sin error, ordenadas por horas; se puede exportar | ✅ |
| 8 | I-Local | `200 []` en las 3 rutas → vacías, sin error, sin exportación | ✅ |
| 9 | I-Local | Sin red → `Código: 503` en las 3 secciones, sin datos | ✅ |
| 10 | I-Local | 400 en texto plano en cursos → `Código: 400` y el texto del backend; categorías sigue bien | ✅ |
| 11 | I-Local | 200 con un objeto en grupos → `Código: 406`, sin exportación | ✅ |
| 12 | I-Local | Una fila con `leyenda1: null` → error con formato `Código: …` | ❌ ES-02 |
| 13 | I-Local | Números enteros en el JSON → se convierten sin error | ❌ ES-03 |
| 14 | I-Local | 1 h 10 min y 1 h 50 min → primero la de 1 h 50 min | ❌ ES-04 |
| 15 | I-Remota | Clase de 2 h con 1 asistencia → 1 clase y 120 min en categoría, curso y grupo | ✅ |
| 16 | I-Remota | Toda la BD de pruebas: cada fila cuadra y cada nivel suma el de abajo | ✅ |
| 17 | I-Remota | Rango `[ayer, ayer]` → incluye la clase de ayer | ❌ ES-05 |
| 18 | I-Remota | Rango de hace 40 a hace 10 días → la categoría nueva en 0 | ✅ |
| 19 | I-Remota | Repetir el POST de la misma asistencia → totales sin cambios | ✅ |
| 20 | I-Remota | Observación H-12: 2 asistencias → se imprime `clases 1.0, duracion 120.0`; solo se afirma que la fila cuadra | ✅ (observación) |

## Módulo 3: diagnóstico por pruebas de grupos (2026-10-29)

Plan: [plan-diagnostico-grupos.md](plan-diagnostico-grupos.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/grupoRepositorio_test.dart` (+5 casos) | 5 | — |
| U-Repo (diagnóstico) | `test/diagnostico/grupos/repositorio_diagnostico_test.dart` | — | 2 (GR-01, GR-02; la mitad de GR-02 del repositorio se corrigió y pasó a la suite unitaria el 2026-11-04) |
| I-Local: VM / repositorio → conexión real → transporte falso | `test/integracion/grupos_integracion_test.dart` (nuevo; los grupos salen del contrato observado `inscripciones/gruposNoEliminados_200.json`) | 5 | — |
| I-Local (diagnóstico) | `test/diagnostico/grupos/integracion_diagnostico_test.dart` | — | 3 (GR-02, 03, 04; GR-02 corregido y movido a la suite de integración el 2026-11-04) |
| I-Remota: VM → backend real | `test/remoto/viewModel/grupo/vmGrupoDiagnosticoTest.dart` (nuevo, en `main_test.dart`) | 6 | — |
| I-Remota (diagnóstico) | `test/diagnostico/grupos/remoto_diagnostico_test.dart` (**necesita el backend**) | — | 3 (GR-03, 05, 06) |

Resultado:
- Suite sin backend: **189 en verde**, que ya incluye lo que añadió en paralelo la migración de atenciones.
- Suite remota: **82 en verde** (antes 76).
- `test/diagnostico`: 39 pruebas, de ellas 37 rojas, 1 verde (control) y 1 omitida; 8 de las rojas son de grupos.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios). Los archivos de este módulo solo añaden infos de `file_names`.

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| GR-06 | Backend | **La lista de alumnos del grupo incluye a un alumno desvinculado.** Después de inscribir a A y B y desvincular a B, `/alumnosGrupo` devuelve los dos, con `eliminadoestado: 0`, aunque `validarInscripcion` dice que B **no** está inscrito (`false`). Esa lista es la que ve la pantalla del grupo y la de la toma de asistencia | `remoto_diagnostico` · GR-06 (`Expected: [A]`, `Actual: [A, B]`); confirmado a mano con `/alumnosGrupo` y `/validarInscripcion` | **Prueba contra el backend real.** **Inferido:** que se le pueda tomar asistencia a un alumno retirado y que cuente en estadísticas; tiene relación con AS-11 | M | backend | **confirmado** |
| GR-03 | Conexión | `/gruposCurso` concatena categoría y curso en la URL sin codificar. Con `Fútbol & Voleibol` el backend recibe `prmCategoria=Fútbol ` y la lista del curso sale **vacía** aunque el grupo existe | `integracion_diagnostico` · GR-03 (`Actual: 'Fútbol '`); `remoto_diagnostico` · GR-03 (categoría y curso con `&` creados en la corrida → `Actual: []`) | **Prueba** sin backend y contra el backend real | M | app | **confirmado** |
| GR-05 | Conexiones de la pantalla del grupo | En un grupo cuya categoría o curso llevan `&`, la pantalla del grupo no ve **nada**: el curso da `404 GC-0003` y las clases y los alumnos salen vacíos y **sin error**, aunque el grupo tiene 1 clase y 1 alumno inscrito. `/curso`, `/clasesGrupo`, `/alumnosGrupo` y `/horarios` concatenan la llave igual que GR-03 | `remoto_diagnostico` · GR-05 (`curso: null (Código: 404 …); clases: 0; alumnos: 0`) | **Prueba contra el backend real.** Que el vacío no muestre error se debe a que el backend responde `GC-0002` y la app lo toma por lista vacía | M | app | **confirmado** |
| GR-02 | Repositorio / modelo | Al crear un grupo se pierde `fechaFinalizacion`: `GrupoModelo.fromEntidad` no la copia y `toJson` no la envía, aunque `GrupoDto` la acepta (antes IN-06, sin prueba) | `repositorio_diagnostico` · GR-02 (`Actual: <null>`); `integracion_diagnostico` · GR-02 (el JSON del `POST /grupo` no la lleva) | **Prueba.** El formulario actual no pide esa fecha, así que hoy solo se pierde si otra pantalla la pone | B | app | **corregido** (2026-11-04): `GrupoMapper.aModelo` copia todos los campos y `GrupoModelo.toJson` envía `fechaFinalizacion` cuando la hay (opcional en `GrupoDto`; sin fecha el POST no cambia). Las pruebas pasaron a `test/unitarias/repositorio/grupoRepositorio_test.dart` y `test/integracion/grupos_integracion_test.dart`. Verificado contra el backend real: `vmGrupoDiagnosticoTest.prueba7FechaFinalizacion` (suite remota) crea el grupo con 201 y la fecha vuelve en `/gruposCurso` |
| GR-04 | Conexión | Las listas por curso e instructor solo capturan `Exception`: un grupo sin `cupos` hace que `GrupoModelo.fromJson` lance `type 'Null' is not a subtype of type 'int'`, que atraviesa la conexión y el repositorio. `/gruposNoEliminados` sí lo captura | `integracion_diagnostico` · GR-04 (`lanzo: type 'Null' is not a subtype of type 'int'`) | **Prueba.** El JSON incompleto lo fabrica la prueba: los 55 grupos reales tienen todos sus campos obligatorios | B | app | **confirmado** (latente) |
| GR-01 | Repositorio | `Gruporepositorio` no tiene `try` en las listas: un `TypeError` de la conexión lo atraviesa (por curso, por instructor y disponibles) | `repositorio_diagnostico` · GR-01 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; GR-04 demuestra que la conexión real lo deja pasar | B | app | **confirmado** |
| GR-07 | Vista | Al crear un grupo, el formulario avisa **«Curso registrado»** («El curso se ha guardado exitosamente») y, si falla, **«Error al guardar clase»**: textos copiados de otros formularios (E-19) | `formularioGrupo_integracion` · 201 (`Actual: 'Curso registrado'`) y error del backend (`Actual: (400, Error al guardar clase)`) | **Prueba** (`testWidgets` por la ruta real). Hallado el 2026-11-05 | B | app | **corregido** (2026-11-05): «Grupo registrado» / «Error al guardar el grupo». La prueba está en `test/integracion/formularioGrupo_integracion_test.dart` |
| GR-08 | Vista | Unos cupos que no caben en un `int` (el campo solo filtra dígitos, no el largo) hacen que `int.parse` lance `FormatException` al pulsar GUARDAR: la excepción se pierde en el `onPressed` y la pantalla no muestra nada | `formularioGrupo_integracion` · `unos cupos que no caben en un numero…` (`FormatException`, `Found 0 widgets with type "DialogError"`) | **Prueba** (`testWidgets` con 23 dígitos). Hallado el 2026-11-05 | B | app | **corregido** (2026-11-05): el envío pasa a `Gruposviewmodel.registrarGrupo`, que usa `int.tryParse` y devuelve `Fallo` («Los cupos deben ser un numero valido») sin enviar nada |

`IN-06` queda sustituido por GR-02.

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-06 | Se puede crear un grupo con 0 cupos | `vmGrupoDiagnosticoTest` · prueba5: el backend no responde 201 |
| H-07 | Un curso o un instructor inexistentes crean grupo igual | prueba6: ninguno de los dos da 201 |
| H-08 | El segundo grupo de un curso no recibe un iterable nuevo | prueba2: dos grupos con iterables distintos |
| H-09 | Un curso o un instructor sin grupos dan error | prueba3: `200 []`, sin error y con la lista vacía |

### Hipótesis sin verificar

| Hip. | Capa | Hipótesis | Por qué no se probó |
|---|---|---|---|
| H-11 | VM | `listarGruposDe` pone en `error` solo el `mensaje`, sin el código; si el mensaje llega vacío, el error queda en `''` | Es de presentación; las vistas no están en el alcance |
| H-12 | Conexión | `/gruposInstructor` concatena el id sin codificar | Los ids son numéricos (cédulas); no hay un caso real con caracteres especiales |
| H-13 | Pantalla del grupo | Con GR-05, `/horarios` también falla, pero el grupo de prueba no tiene horarios: la prueba no puede distinguir "sin horarios" de "consulta rota" | Habría que registrar un horario en la preparación |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | Grupos del instructor 200 → entidades, pasa el id, conserva imagen, instructor y cupos | ✅ |
| 2 | U-Repo | Grupos disponibles 200 → entidad con su clave | ✅ |
| 3 | U-Repo | Grupos de un curso `200 []` → lista vacía de entidades | ✅ |
| 4 | U-Repo | 503 del instructor y 500 de los disponibles → pasan sin cambios (`same`) | ✅ |
| 5 | U-Repo | Insertar con 400 → pasa sin cambios | ✅ |
| 6 | U-Repo | La conexión lanza un `TypeError` en las tres listas → error devuelto | ❌ GR-01 |
| 7 | U-Repo | Insertar con `fechaFinalizacion` → llega al modelo | ❌ GR-02 (corregido 2026-11-04) |
| 8 | I-Local | Grupos de un curso 200: query `prmCategoria`/`prmCurso` exacta; lista con cupos y periodo | ✅ |
| 9 | I-Local | Grupos de un curso `200 []` → vacía, sin error | ✅ |
| 10 | I-Local | Grupos del instructor sin red → query con el id; el error contiene 503 | ✅ |
| 11 | I-Local | Insertar 201 → el cuerpo lleva categoría, curso, cupos, instructor, imagen y fecha de creación | ✅ |
| 12 | I-Local | Insertar 400 → llega con su código | ✅ |
| 13 | I-Local | `Fútbol & Voleibol` / `Nivel 1 + 2` llegan completos a la query | ❌ GR-03 |
| 14 | I-Local | Grupo sin `cupos` en las listas por curso e instructor → error sin lanzar | ❌ GR-04 |
| 15 | I-Local | El `POST /grupo` lleva `fechaFinalizacion` | ❌ GR-02 (corregido 2026-11-04) |
| 16 | I-Remota | El curso trae su grupo con cupos, instructor, año, iterable y fecha de creación | ✅ |
| 17 | I-Remota | Segundo grupo del mismo curso → 201 e iterable distinto | ✅ |
| 18 | I-Remota | Curso sin grupos e instructor inexistente → lista vacía sin error | ✅ |
| 19 | I-Remota | Pantalla del grupo: carga su curso, sin clases no hay error y el alumno inscrito aparece | ✅ |
| 20 | I-Remota | Grupo con 0 cupos → no se crea | ✅ |
| 21 | I-Remota | Curso inexistente o instructor inexistente → no se crea | ✅ |
| 22 | I-Remota | Categoría y curso con `&` → la lista trae su grupo | ❌ GR-03 |
| 23 | I-Remota | Pantalla de un grupo con `&` → ve su curso, su clase y su alumno | ❌ GR-05 |
| 24 | I-Remota | Alumno desvinculado → no aparece en los alumnos del grupo | ❌ GR-06 |

## Módulo 8: diagnóstico por pruebas de cursos (2026-10-29)

Plan: [plan-diagnostico-cursos.md](plan-diagnostico-cursos.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/cursoRepositorio_test.dart` (+4 casos) | 4 | — |
| U-Repo (diagnóstico) | `test/diagnostico/cursos/repositorio_diagnostico_test.dart` | — | 1 (CU-01) |
| I-Local: VM / repositorio → conexiones reales de cursos e imágenes → transporte falso | `test/integracion/cursos_integracion_test.dart` (nuevo; fixtures en `test/contratos/cursos/`) | 6 | — |
| I-Local (diagnóstico) | `test/diagnostico/cursos/integracion_diagnostico_test.dart` | — | 4 (CU-02, 03, 04, 05; CU-05 corregido y movido a la suite de integración el 2026-11-04, CU-03 el 2026-11-05) |
| I-Remota: VM → backend real | `test/remoto/viewModel/curso/vmCursoDiagnosticoTest.dart` (nuevo, en `main_test.dart`) | 5 | — |
| I-Remota (diagnóstico) | `test/diagnostico/cursos/remoto_diagnostico_test.dart` (**necesita el backend**) | — | 1 (CU-02) |

**Cambio en la infraestructura de pruebas:** `AdaptadorHttpFalso._leerCuerpo` decodificaba el cuerpo como UTF-8 estricto y fallaba con el multipart binario de una imagen. Ninguna petición con imagen llegaba al adaptador y la app recibía un `DioException` de tipo `unknown`. Ahora usa `allowMalformed: true`. No era un fallo de la app.

Resultado:
- Suite sin backend: **199 en verde** (antes 189).
- Suite remota: **87 en verde** (antes 82).
- `test/diagnostico`: 45 pruebas, de ellas 43 rojas, 1 verde (control) y 1 omitida; 6 de las rojas son de cursos.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios).

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| CU-02 | Conexión | `/cursosbycategoria` y `/curso` concatenan los títulos en la URL sin codificar. Con `Fútbol & Voleibol` el backend recibe `prmCategoria=Fútbol `, y con `Nivel 1 + 2` recibe `Nivel 1   2`. Contra el backend real, una categoría con `&` y su curso `curso & co …` dan **lista vacía** y **404 GC-0003** | `integracion_diagnostico` · CU-02 (`Actual: ['Fútbol ', 'Fútbol ', 'Nivel 1   2']`); `remoto_diagnostico` · CU-02 (`lista: []; obtener: 404`) | **Prueba** sin backend y contra el backend real. Es la misma causa que GR-05, pero en la conexión de cursos | M | app | **confirmado** |
| CU-05 | VM | Un error al listar cursos abre **dos** diálogos seguidos: "Sin datos" con el error real y después "datos inconsistentes" (código 406), porque `listarCursosDe` no sale del método tras el primer error | `integracion_diagnostico` · CU-05 (`Found 2 widgets with type "DialogError"`; títulos `[Sin datos, datos inconsistentes]`) | **Prueba** (`testWidgets` con la cadena real y un 500) | B | app | **corregido** (2026-11-04): `listarCursosDe` ya no recibe `context` ni abre diálogos; ante un error deja la lista vacía y devuelve un solo `Fallo` con el código, y `CursosView` abre un único `DialogError`. La prueba se reescribió sobre la ruta real (`AppRutas.cursos`) y pasó a `test/integracion/cursos_integracion_test.dart` |
| CU-03 | Conexión → VM | `agregarCurso` sin `imagenFile` lanza `Null check operator used on a null value` (por `curso.imagenFile!`), que atraviesa conexión, repositorio, servicio y VM: el VM no tiene `try` en `agregarCurso` | `integracion_diagnostico` · CU-03 (`lanzo: Null check operator used on a null value`) | **Prueba.** El formulario de alta exige imagen, así que hoy solo se llega llamando al VM sin archivo, por ejemplo desde un futuro modo edición. Es la versión de cursos de CAT-01 | B | app | **corregido** (2026-11-05): `agregarCurso` envuelve la llamada en `try` y devuelve la excepción como `RespuestaModelo.fromObjectError`, sin lanzar; el formulario pasa por `guardarCurso`, que exige imagen antes de enviar. La prueba pasó a `test/integracion/cursos_integracion_test.dart`. La conexión sigue haciendo `imagenFile!` (igual que CAT-01) |
| CU-04 | Conexión | Un curso sin `deporte` hace que `CursoModelo.fromJson` lance `type 'Null' is not a subtype of type 'String'`, que atraviesa la conexión y el repositorio, al listar y al obtener | `integracion_diagnostico` · CU-04 | **Prueba.** El JSON incompleto lo fabrica la prueba | B | app | **confirmado** (latente) |
| CU-01 | Repositorio | `CursoRepositorio` no tiene ningún `try`: un `TypeError` de la conexión lo atraviesa al listar, obtener y guardar | `repositorio_diagnostico` · CU-01 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; CU-03 y CU-04 demuestran que la conexión real los deja pasar | B | app | **confirmado** |
| CU-06 | VM / vista | Mientras llega la lista, `CursosView` afirma «No hay cursos aun para esta categoria»: `CursosViewModel` no tenía indicador de carga y la vista no distinguía «cargando» de «lista vacía» | `integracion` · `Listar cursos de (CursosView) - mientras carga muestra el indicador…` (`Actual: (indicador: 0, sinCursos: 1)`) | **Prueba** (`testWidgets` por la ruta real, con la respuesta retenida en el adaptador). Hallado el 2026-11-04 al revisar el criterio C3 de la auditoría de ViewModels | B | app | **corregido** (2026-11-04): `CursosViewModel` expone `cargando` (se apaga en `finally`) y la vista pinta un `CircularProgressIndicator` mientras carga. La prueba está en `test/integracion/cursos_integracion_test.dart` |
| CU-07 | Vista | Si el guardado de un curso falla, el formulario queda **vacío**: `_submitForm` llamaba a `_limpiarInputs()` antes de enviar, así que el usuario perdía lo escrito y la imagen (H-28) | `formularioCurso_integracion` · `un fallo al guardar muestra su codigo y conserva lo escrito` (`Actual: (descripcion: , nombre: )`) | **Prueba** (`testWidgets` por la ruta real, con el selector de imágenes doblado y un 500 en `POST /imagenMultipart`). Hallado el 2026-11-05 | B | app | **corregido** (2026-11-05): el envío pasa a `CursosViewModel.guardarCurso`, que aplica las reglas (deporte e imagen) y devuelve `Resultado`; la vista ya no limpia los campos (en éxito cierra la pantalla). La prueba está en `test/integracion/formularioCurso_integracion_test.dart` |
| DE-01 | Conexión | Un error del backend al pedir los deportes (por ejemplo un 500) llega a la pantalla con **código 0** y el texto de la `DioException`: `Conexiondeporteremoto` no tenía `on DioException` y el error caía en el `on Exception` genérico | `formularioCurso_integracion` · `un error al pedir los deportes se muestra en lugar del desplegable` (texto pintado: `Código: 0 - excepcion Conexion: DioException [bad response]…`) | **Prueba** (`testWidgets` por la ruta real con un 500 en `GET /deportes`). Hallado el 2026-11-05 | B | app | **corregido** (2026-11-05): la conexión captura `DioException` y responde con `RespuestaModelo.fromDioException`, que conserva el código, como las demás conexiones |

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-06 | Un curso con el mismo nombre en la misma categoría se crea dos veces | `vmCursoDiagnosticoTest` · prueba2: no da 201 y la categoría sigue con 1 curso |
| H-07 | Una categoría inexistente, o un nombre o una descripción vacíos, crean curso | prueba3: ninguno de los tres da 201 |
| H-08 | Una categoría sin cursos da error | prueba4: lista y desplegable vacíos, sin diálogo |

### Hipótesis sin verificar

| Hip. | Capa | Hipótesis | Por qué no se probó |
|---|---|---|---|
| H-09 | Vista | `FormularioCurso._submitForm` vacía el formulario **antes** de enviar: si el alta falla, el usuario pierde lo que escribió | Es de la vista |
| H-10 | Conexión | Si el `POST /curso` falla después de subir la imagen (por ejemplo, H-06 o H-07), la imagen queda huérfana en el servidor | Es consecuencia del alta en dos pasos; en la BD de pruebas las imágenes huérfanas se aceptan a propósito |
| H-11 | Pruebas | La unitaria `Listar cursos de - 406 pasa sin cambios` dice que el 406 llega con una "categoría sin cursos", pero el backend da `200 []` en ese caso. El comentario está desactualizado (la prueba sigue siendo válida) | Es una observación sobre la prueba |
| H-12 | Backend | `/v3/api-docs` documenta `POST /curso → 200` y el backend responde `201` | Es documentación del backend |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | Listar `200 []` → lista vacía de entidades | ✅ |
| 2 | U-Repo | Obtener 404 → pasa sin cambios | ✅ |
| 3 | U-Repo | Guardar con 400 → pasa sin cambios y sin entidad | ✅ |
| 4 | U-Repo | Guardar → el modelo lleva deporte, descripción e imagen existente | ✅ |
| 5 | U-Repo | La conexión lanza un `TypeError` al listar, obtener y guardar → error devuelto | ❌ CU-01 |
| 6 | I-Local | Listar 200: query `prmCategoria` exacta, lista con imagen y desplegable | ✅ |
| 7 | I-Local | Listar `200 []` → lista y desplegable vacíos | ✅ |
| 8 | I-Local | Agregar: `POST /imagenMultipart` y luego `POST /curso` con el `CursoDto` y el `idImagen` recibido; 201 → entidad | ✅ |
| 9 | I-Local | Agregar con la imagen en 500 → no se envía el curso; llega el 500 | ✅ |
| 10 | I-Local | Agregar con el curso en 400 → llega el 400 | ✅ |
| 11 | I-Local | Obtener 200 → entidad; 404 → error con `GC-0003` | ✅ |
| 12 | I-Local | Categoría y curso con `&` y `+` llegan completos a la query | ❌ CU-02 |
| 13 | I-Local | Agregar sin archivo de imagen → error, sin lanzar | ❌ CU-03 (corregido 2026-11-05) |
| 14 | I-Local | Curso sin `deporte` al listar y obtener → error, sin lanzar | ❌ CU-04 |
| 15 | I-Local | Listar con 500 → un solo `DialogError` | ❌ CU-05 (corregido 2026-11-04) |
| 16 | I-Remota | Agregar → 201 con imagen; aparece en su categoría con deporte, imagen y desplegable; obtener da sus datos | ✅ |
| 17 | I-Remota | Curso repetido → no se crea | ✅ |
| 18 | I-Remota | Categoría inexistente, nombre vacío o descripción vacía → no se crea | ✅ |
| 19 | I-Remota | Categoría sin cursos → lista vacía sin diálogo | ✅ |
| 20 | I-Remota | Curso inexistente → 404 `GC-0003` | ✅ |
| 21 | I-Remota | Categoría y curso con `&` → se listan y se obtienen | ❌ CU-02 |

## Módulo 7: diagnóstico por pruebas de categorías (2026-10-29)

Plan: [plan-diagnostico-categorias.md](plan-diagnostico-categorias.md). Las hipótesis de partida son las del anexo A del plan general (CAT-01 a CAT-12, T-01 a T-05), que hasta ahora eran **solo de lectura del código**. Un `CAT-xx` confirmado conserva su ID; las hipótesis nuevas siguen desde CAT-13. **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/categoriaRepositorio_test.dart` (+5 casos) | 5 | — |
| U-Repo (diagnóstico) | `test/diagnostico/categorias/repositorio_diagnostico_test.dart` | — | 2 (CAT-13, CAT-14; CAT-14 corregido y movido a la suite unitaria el 2026-11-04) |
| I-Local: VM → conexiones reales de categorías e imágenes → transporte falso | `test/integracion/categorias_integracion_test.dart` (nuevo; fixtures en `test/contratos/categorias/`) | 5 | — |
| I-Local (diagnóstico) | `test/diagnostico/categorias/integracion_diagnostico_test.dart` | — | 7 (CAT-01, 02, 03, 04, 05, 06, 09; CAT-05 corregido y movido a la suite de vista el 2026-11-04) |
| I-Remota: VM → backend real | `test/remoto/viewModel/categoria/vmCategoriaDiagnosticoTest.dart` (nuevo, en `main_test.dart`) | 3 (una es la observación CAT-16) | — |
| I-Remota (diagnóstico) | `test/diagnostico/categorias/remoto_diagnostico_test.dart` (**necesita el backend**) | — | 1 (CAT-03) |

Resultado:
- Suite sin backend: **209 en verde** (antes 199).
- Suite remota: **90 en verde** (antes 87).
- `test/diagnostico`: 55 pruebas, de ellas 53 rojas, 1 verde (control) y 1 omitida; 10 de las rojas son de categorías.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios).

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| CAT-03 | Conexión | **Una categoría con `&` en el título no se puede editar ni eliminar.** `PUT` y `DELETE` concatenan `?titulo=` sin codificar: el backend recibe `titulo=prueba_… Fútbol ` y responde 404 `GC-0003` ("La categoria con el titulo prueba_… Fútbol  no existe") | `integracion_diagnostico` · CAT-03 (`Actual: ['Fútbol ', 'Fútbol ']`); `remoto_diagnostico` · CAT-03 (`editar: Fallo 404 …; eliminar: Fallo 404 …`) | **Prueba** sin backend y contra el backend real. Es la misma causa que GR-03, GR-05 y CU-02 | M | app | **confirmado** |
| CAT-09 | VM | Dos cargas solapadas de la lista: si la respuesta de la primera llega después de la de la segunda, **pisa** la lista nueva (no hay contador de peticiones, a diferencia de `EstadisticasViewModel`) | `integracion_diagnostico` · CAT-09 (se esperaba `['Nueva']` y queda la lista vieja) | **Prueba.** **Inferido:** que el solape ocurra en uso real, por ejemplo la carga inicial todavía en camino cuando el formulario vuelve y la recarga | B | app | **confirmado** |
| CAT-04 | VM | `CategoriaViewModel` no usa `NotificacionSegura`: una carga que termina después de `dispose` lanza `A CategoriaViewModel was used after being disposed` | `integracion_diagnostico` · CAT-04 (`FlutterError`) | **Prueba.** Esa aserción de Flutter solo salta en modo debug | B | app | **confirmado** |
| CAT-05 | VM | `cargarCategorias(context)` muestra un error 500 en el `DialogError` **con código 204** (todos los errores llevan 204) | `integracion_diagnostico` · CAT-05 (`Expected: <500>`, `Actual: <204>`) | **Prueba** (`testWidgets`). Solo lo usa `InscripcionesGeneralesView` | B | app | **corregido** (2026-11-04): se eliminó `cargarCategorias(context)`; la pantalla carga con `listarYNotificarCategorias()`, que ahora devuelve `Resultado`, y abre el `DialogError` con el código del `Fallo`. Una lista vacía (204) ya no se muestra como error. La prueba se reescribió sobre la ruta real (`AppRutas.InscripcionesGenerales`) y pasó a `test/unitarias/vista/inscripcionesCoordinador_test.dart` |
| CAT-01 | Conexión → VM | Insertar con `idImagen` y sin archivo devuelve `Fallo(-1, "Null check operator used on a null value", origen: ViewModel)`: la conexión hace `datos.imagenFile!` y la excepción atraviesa conexión, repositorio y servicio | `integracion_diagnostico` · CAT-01 | **Prueba** con la cadena real. El formulario no llega a este camino (al crear exige imagen nueva) | B | app | **confirmado** (latente) |
| CAT-14 | Repositorio | `insertarCategoria` acepta `idImagen` como imagen suficiente (no corta con 400), pero arma el modelo **sin** `imagenId`, así que la imagen existente se pierde. Es la otra mitad de CAT-01 | `repositorio_diagnostico` · CAT-14 (`Expected: <9>`, `Actual: <null>`) | **Prueba** | B | app | **corregido** (2026-11-04): el repositorio arma el modelo con `CategoriaMapper.aModelo`, que lleva el `imagenId` (si hay archivo, la conexión lo reemplaza por el de la imagen subida). La prueba pasó a `test/unitarias/repositorio/categoriaRepositorio_test.dart`. CAT-01 sigue abierto: la conexión real aún hace `imagenFile!` |
| CAT-02 | Conexión | Un `POST /categoria` con 201 **sin cuerpo** termina en `Fallo(-1, "NoSuchMethodError: The method '[]' was called on null")`, aunque se guardó: `categoriaModelo.fromJson(null)` | `integracion_diagnostico` · CAT-02 | **Prueba.** Hoy el backend responde con cuerpo, así que no se ve en uso real | B | app | **confirmado** (latente) |
| CAT-06 | Conexión | Una categoría con `titulo: null` en `/categorias2` hace que la pantalla muestre `type 'Null' is not a subtype of type 'String'` en lugar de un error con código: `fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio lo capturan | `integracion_diagnostico` · CAT-06 | **Prueba.** El JSON incompleto lo fabrica la prueba | B | app | **confirmado** (latente) |
| CAT-13 | Repositorio | `CategoriaRepositorio` no tiene ningún `try`: un `TypeError` de la conexión lo atraviesa al listar, guardar, actualizar y eliminar | `repositorio_diagnostico` · CAT-13 (`Instance of 'TypeError'`) | **Prueba.** CAT-01, CAT-02 y CAT-06 demuestran que la conexión real los deja pasar | B | app | **confirmado** |

**Pruebas hechas para pasar (anexo A), ya con evidencia:**
- T-01, T-02 y T-03 quedan **confirmadas**. La unitaria `Guardar categoria - 201 refresca la lista` y la del repositorio insertan con `idImagen` y sin archivo, y salen verdes porque `ConexionCategoriaFalsa` acepta ese camino. Con la conexión real, el mismo camino da CAT-01. El doble no se cambió para no romper esas pruebas: el rojo de CAT-01 deja el contraste escrito.
- T-04 y CAT-12 se aplazan al módulo de autenticación.

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| CAT-15 | Se puede crear dos veces una categoría con el mismo título | `vmCategoriaDiagnosticoTest` · prueba1: la segunda da `Fallo` (409) y la lista tiene una sola |

### Hipótesis sin verificar u observaciones (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no es hallazgo |
|---|---|---|---|
| CAT-16a | Backend / cliente | **Observado:** eliminar una categoría que tiene un curso responde `Exito`, y `/cursosbycategoria` **sigue devolviendo el curso** (1). El borrado es lógico y no arrastra los cursos | Falta la regla: ¿se debe impedir eliminar una categoría con cursos, o hay que ocultarlos también? |
| CAT-16b | Backend / cliente | **Observado:** tras eliminar una categoría, crear otra con el mismo título da `409 GC-0007` "Ya existe es mismo registro", aunque no aparece en la lista. El coordinador no puede reutilizar el nombre ni ver por qué | Falta la regla de qué hacer con los títulos de categorías eliminadas |
| CAT-11 | Rutas | `route_generator.dart:30` importa `views/Categorias/CategoriasView.dart`, pero la carpeta en git es `categorias/`: en un sistema que distingue mayúsculas (Linux, CI) no compila | Confirmado leyendo el código y `git ls-files`; en Windows ninguna prueba puede ponerlo en rojo |
| CAT-07 | Modelo | `ErrorModelo.mensaje` recibe `response.data` (puede ser un `Map`) en `fromResponse` ante un 2xx inesperado | No se escribió una prueba aparte |
| CAT-10 | Vista | El botón de quitar imagen nunca se agrega al `Stack` | Es de la vista |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | Listar con 500 → pasa sin cambios | ✅ |
| 2 | U-Repo | Guardar sin archivo ni `idImagen` → 400 y 0 llamadas | ✅ |
| 3 | U-Repo | Guardar con archivo → lo pasa a la conexión; un 400 pasa sin cambios | ✅ |
| 4 | U-Repo | Actualizar con imagen nueva → pasa el archivo y conserva el id | ✅ |
| 5 | U-Repo | Eliminar → pasa el título tal cual; un 404 pasa sin cambios | ✅ |
| 6 | U-Repo | La conexión lanza un `TypeError` en los 4 métodos → error devuelto | ❌ CAT-13 |
| 7 | U-Repo | Guardar con `idImagen` sin archivo → el modelo lleva `imagenId` | ❌ CAT-14 (corregido 2026-11-04) |
| 8 | I-Local | Listar 200 → lista, desplegable e `idImagen` | ✅ |
| 9 | I-Local | Listar sin red → `Código: 503`, lista y desplegable vacíos | ✅ |
| 10 | I-Local | Crear: imagen → `POST /categoria` con el título recortado y el `imagenId` → recarga | ✅ |
| 11 | I-Local | Editar sin imagen nueva: `PUT ?titulo=` con el `imagenId` original, sin subir imagen → recarga | ✅ |
| 12 | I-Local | Eliminar 200 → `DELETE ?titulo=` y recarga; 404 → `Fallo` con `GC-0003` | ✅ |
| 13 | I-Local | Insertar con `idImagen` sin archivo → sin excepción hasta el VM | ❌ CAT-01 |
| 14 | I-Local | `POST /categoria` 201 sin cuerpo → `Exito` | ❌ CAT-02 |
| 15 | I-Local | Editar y eliminar `Fútbol & Voleibol` → el título llega completo | ❌ CAT-03 |
| 16 | I-Local | Respuesta después de `dispose` → no lanza | ❌ CAT-04 |
| 17 | I-Local | `cargarCategorias(context)` con 500 → el diálogo lleva 500 | ❌ CAT-05 (corregido 2026-11-04) |
| 18 | I-Local | Categoría con `titulo: null` → error con formato `Código: …` | ❌ CAT-06 |
| 19 | I-Local | Respuesta vieja que llega tarde → no pisa la nueva | ❌ CAT-09 |
| 20 | I-Remota | Título repetido → la segunda no se crea | ✅ |
| 21 | I-Remota | Eliminar → sale de la lista y del desplegable | ✅ |
| 22 | I-Remota | Observación CAT-16: categoría con curso eliminada, cursos que quedan y título reutilizado | ✅ (observación) |
| 23 | I-Remota | Categoría con `&` → se edita y se elimina | ❌ CAT-03 |

## Módulo 2: diagnóstico por pruebas de clases (2026-10-29)

Plan: [plan-diagnostico-clases.md](plan-diagnostico-clases.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/claseRepositorio_test.dart` (+4 casos) | 4 | — |
| U-Repo (diagnóstico) | `test/diagnostico/clases/repositorio_diagnostico_test.dart` | — | 2 (CL-03, CL-04) |
| I-Local: `Clasesviewmodel` y `DetalleGrupoViewModel` → conexiones reales → transporte falso | `test/integracion/clases_integracion_test.dart` (nuevo; fixtures en `test/contratos/clases/`) | 5 | — |
| I-Local (diagnóstico) | `test/diagnostico/clases/integracion_diagnostico_test.dart` | — | 2 (CL-05 y GR-05 en `/clasesGrupo`) |
| I-Remota: VM → backend real | `test/remoto/viewModel/clase/vmClaseDiagnosticoTest.dart` (nuevo, en `main_test.dart`) | 4 (una es la observación H-08) | — |
| I-Remota (diagnóstico) | `test/diagnostico/clases/remoto_diagnostico_test.dart` (**necesita el backend**) | — | 2 (CL-01, CL-06) |

Resultado:
- Suite sin backend: **218 en verde** (antes 209).
- Suite remota: **94 en verde** (antes 90).
- `test/diagnostico`: 61 pruebas, de ellas 59 rojas, 1 verde (control) y 1 omitida; 6 de las rojas son de clases.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios).

**Cambio del backend observado:** un grupo sin clases responde ahora `200 []`, y ya no el objeto `GC-0002` que describen `CLAUDE.md` y `DetalleGrupoViewModel`. La app maneja las dos formas; la integración local prueba ambas.

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| CL-06 | Conexión / backend | **La clase se guarda un día antes.** La app envía `fecha.toIso8601String()` con la hora local y **sin zona**; el backend la toma como UTC y guarda la fecha en UTC-5. Todo lo enviado entre las 00:00 y las 04:59 queda en el día anterior: una clase del 2026-10-26 a las 00:00 se lista como 2026-10-25. El selector de fecha del formulario (`showDatePicker` en `claseFormulario.dart`) devuelve justamente las **00:00** del día elegido | `remoto_diagnostico` · CL-06 (`enviada 2026-10-26 00:00:00.000`, `Actual: '2026-10-25'`). Confirmado a mano con 4 altas directas: 00:00 y 04:59 → día anterior; 05:00 y 23:30 → mismo día | **Prueba contra el backend real** (corrupción de la fecha guardada). **Inferido del código:** que **toda** clase cuya fecha se elige en el selector quede un día antes. La fecha por defecto (`DateTime.now()`) solo se corre si se registra antes de las 5 a. m. **Inferido:** afecta la fecha de la asistencia y el rango de las estadísticas (relacionado con ES-05) | **A** | app (enviar `yyyy-MM-dd` o la hora con zona) + backend (no suponer UTC) | **corregido** (2026-10-29): `Clasemodelo.toJson` envía el instante con zona (`fecha.toUtc().toIso8601String()`, termina en `Z`), así que el backend ya no supone UTC sobre una hora local. Verificado contra el backend real a las 00:00, 04:59, 05:00 y 23:30: la clase queda en el día elegido. Prueba: `vmClaseDiagnosticoTest.prueba3FechaSinCorrimiento`, ahora en la suite remota (`main_test.dart`). Del lado del backend sigue pendiente no suponer UTC cuando la fecha llega sin zona |
| CL-01 | Backend | **Eliminar una clase no la quita.** `DELETE /clase?id=` responde 200, el VM muestra éxito y recarga, pero la clase sigue en la pantalla del grupo con `eliminado: 0` | `remoto_diagnostico` · CL-01 (`sigue la clase 307 con eliminado 0`) | **Prueba contra el backend real.** Ya se había visto el 2026-10-21; `VmModuloGrupoTest.prueba6EliminarClase200` solo fija el 200 (señal D4). **Inferido:** que se le pueda tomar asistencia a una clase "eliminada" y que sume en estadísticas | M | backend | **confirmado** |
| CL-05 | Conexión | Una clase con `fecha: null` hace que la pantalla del grupo muestre `type 'Null' is not a subtype of type 'String'`: `Clasemodelo.fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio (la llamada está fuera de su `try`) lo capturan | `integracion_diagnostico` · CL-05 | **Prueba.** El JSON incompleto lo fabrica la prueba (las clases reales traen fecha) | B | app | **confirmado** (latente) |
| CL-04 | Repositorio / modelo | `agregarClase` con una entidad sin `fecha` o sin `horas` lanza `Null check operator used on a null value` (`Clasemodelo.fromEntidad` hace `fecha!`, `horas!` y `minutos!`; el repositorio solo captura `Exception`. Desde 2026-11-04 ese código está en `ClaseMapper.aModelo`, sin cambios) | `repositorio_diagnostico` · CL-04 | **Prueba.** El formulario valida fecha y horas antes de llamar, así que no se llega desde la pantalla | B | app | **confirmado** (latente) |
| CL-03 | Repositorio | Un `TypeError` de la conexión atraviesa el repositorio al listar, agregar y eliminar | `repositorio_diagnostico` · CL-03 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; CL-05 demuestra que la conexión real lo deja pasar | B | app | **confirmado** |

`GR-05` suma una prueba en la conexión de clases (`integracion_diagnostico` · GR-05: `/clasesGrupo` recibe `categoria=Fútbol ` y `curso=Nivel 1   2`). No es un hallazgo nuevo.

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-02 | Eliminar una clase inexistente responde 200 y se ve como éxito | `vmClaseDiagnosticoTest` · prueba5: `Fallo` |
| H-03 | Una clase con fecha de hoy se rechaza por la zona horaria | prueba2: `Exito` |

### Hipótesis sin verificar u observaciones (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no es hallazgo |
|---|---|---|---|
| H-08 | Backend / cliente | **Observado:** el backend acepta una clase de **mañana** y una de **30 horas** (`Exito` en las dos). El formulario limita el selector a `lastDate: DateTime.now()`, pero el VM no valida nada | Falta la regla (AS-13): ¿hasta cuándo se registra una clase y cuánto puede durar? |
| H-09 | Conexión | `eliminarClase` etiqueta sus errores con `metodo = "delete"` en minúsculas | Cosmético |
| H-10 | Backend | `/v3/api-docs` documenta `POST /claseGrupo → 200` y el backend responde 201 | Es documentación del backend |
| H-11 | Pruebas | `VmModuloGrupoTest.prueba6EliminarClase200` fija como esperado el 200 de un borrado que no borra (señal D4) | Se revisa al corregir CL-01: allí se debe afirmar que la lista quede vacía |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | Listar con 503 y con el 406 de lista vacía → pasan sin cambios | ✅ |
| 2 | U-Repo | Listar `200 []` → lista vacía de entidades; la conexión recibe la llave del grupo | ✅ |
| 3 | U-Repo | Agregar con 400 → pasa sin cambios | ✅ |
| 4 | U-Repo | Eliminar → pasa el id; un 500 pasa sin cambios | ✅ |
| 5 | U-Repo | La conexión lanza un `TypeError` al listar, agregar y eliminar → error devuelto | ❌ CL-03 |
| 6 | U-Repo | Agregar una entidad sin fecha o sin horas → error, sin lanzar y sin llamar a la conexión | ❌ CL-04 |
| 7 | I-Local | Cargar clases 200 → query con la llave; fecha y horas convertidas | ✅ |
| 8 | I-Local | Grupo sin clases (`200 []` y el antiguo `GC-0002`) → lista vacía sin error | ✅ |
| 9 | I-Local | Registrar → el cuerpo lleva el grupo, el instructor, la fecha elegida, las horas recortadas y `minutos: 0`; 201 → `Exito` | ✅ |
| 10 | I-Local | Registrar con 400 → `Fallo(400)`; sin red → `Fallo(503)` | ✅ |
| 11 | I-Local | Eliminar 200 → `DELETE ?id=` y recarga; 500 → `Fallo(500)` sin recargar | ✅ |
| 12 | I-Local | Clase con `fecha: null` → error con formato `Código: …` | ❌ CL-05 |
| 13 | I-Local | Grupo con `&` → la query de `/clasesGrupo` llega completa | ❌ GR-05 |
| 14 | I-Remota | Clase de ayer → aparece con código, horas, minutos, instructor y fecha | ✅ |
| 15 | I-Remota | Clase con fecha de hoy → `Exito` | ✅ |
| 16 | I-Remota | Observación H-08: clase de mañana y de 30 horas → `Exito` las dos | ✅ (observación) |
| 17 | I-Remota | Eliminar una clase inexistente → `Fallo` | ✅ |
| 18 | I-Remota | Eliminar → la clase sale de la pantalla del grupo | ❌ CL-01 |
| 19 | I-Remota | Fecha a las 00:00 (selector) y a las 23:30 → la clase queda en ese día | ❌ CL-06 → ✅ corregido (también 04:59 y 05:00) |

## Módulo 6: diagnóstico por pruebas de horarios (2026-10-29)

Plan: [plan-diagnostico-horarios.md](plan-diagnostico-horarios.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

**Límite del módulo:** el backend publica solo `GET /horarios`, no hay ninguna ruta para crearlos, y la BD de pruebas tiene **0 horarios** en sus 124 grupos. Contra el backend real solo se puede comprobar la lectura vacía. Los casos con datos usan un contrato **propuesto** (`test/contratos/horarios/`, armado a partir del esquema `HorarioEntidad`), no observado.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/horarioRepositorio_test.dart` (nuevo) | 3 | — |
| U-Repo (diagnóstico) | `test/diagnostico/horarios/repositorio_diagnostico_test.dart` | — | 2 (HO-01, HO-02; la mitad de HO-01 del repositorio se corrigió y pasó a la suite unitaria el 2026-11-04) |
| I-Local: `Horariosviewmodel` → conexión real → transporte falso | `test/integracion/horarios_integracion_test.dart` (nuevo) | 4 | — |
| I-Local (diagnóstico) | `test/diagnostico/horarios/integracion_diagnostico_test.dart` | — | 3 (HO-01, HO-03 y GR-05 en `/horarios`; HO-01 corregido y movido a la suite de integración el 2026-11-04) |
| I-Remota: VM → backend real | `test/remoto/viewModel/horario/vmHorarioDiagnosticoTest.dart` (nuevo, en `main_test.dart`) | 3 | — |

Resultado:
- Suite sin backend: **225 en verde** (antes 218).
- Suite remota: **97 en verde** (antes 94).
- `test/diagnostico`: 66 pruebas, de ellas 64 rojas, 1 verde (control) y 1 omitida; 5 de las rojas son de horarios.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios).

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| HO-01 | Modelo / repositorio | El `id` del horario se pierde en dos sitios: `HorarioModelo.fromJson` no lo lee y `Horarioentidad.fromModelo` no lo copia. Las tarjetas reciben `[null, null]` en lugar de `[15, 16]` | `integracion_diagnostico` · HO-01 (`Actual: [null, null]`); `repositorio_diagnostico` · HO-01 (`Actual: <null>`) | **Prueba** con el contrato propuesto. **Inferido:** hoy ninguna pantalla usa el id, pero sin él no se puede editar ni eliminar un horario cuando exista esa función | B | app | **corregido** (2026-11-04): `HorarioModelo.fromJson` lee el `id` y `HorarioMapper.aEntidad` lo copia. Las pruebas pasaron a `test/unitarias/repositorio/horarioRepositorio_test.dart` y `test/integracion/horarios_integracion_test.dart`. Comprobado solo con el contrato: la BD de pruebas no tiene horarios y el backend no tiene ruta para crearlos |
| HO-03 | Conexión → VM | Un horario con `dia: null` hace que la tarjeta muestre `type 'Null' is not a subtype of type 'String'` en lugar de un error con código: `fromJson` lanza y ni la conexión, ni el repositorio, ni `listarHorariosGrupo` del VM (los tres solo capturan `Exception`, o dejan la llamada fuera del `try`) lo capturan | `integracion_diagnostico` · HO-03 | **Prueba.** El JSON incompleto lo fabrica la prueba | B | app | **confirmado** (latente) |
| HO-02 | Repositorio | Un `TypeError` de la conexión atraviesa `obtenerHoariosGrupo`: la llamada a la conexión está fuera de su `try` | `repositorio_diagnostico` · HO-02 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; HO-03 demuestra que la conexión real lo deja pasar | B | app | **confirmado** |

`GR-05` suma una prueba en la conexión de horarios (`integracion_diagnostico` · GR-05: `/horarios` recibe `categoria=Fútbol ` y `curso=Nivel 1   2`). Con esto queda probada en las cuatro conexiones de la pantalla del grupo.

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-06 | Un grupo sin horarios, o inexistente, da error en lugar de lista vacía | `vmHorarioDiagnosticoTest` · prueba1 a prueba3: tarjeta y pantalla del grupo vacías y sin error; con un grupo inexistente, lista vacía |

### Hipótesis sin verificar u observaciones (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no es hallazgo |
|---|---|---|---|
| H-07 | Backend / cliente | **Funcionalidad inexistente:** no hay ninguna ruta para registrar, editar o eliminar horarios, y no existe ninguno en la BD de pruebas. Tres pantallas (grupos asignados, grupos de inscripción y pantalla del grupo) muestran una sección de horarios que hoy siempre sale vacía | No es un fallo de la app que una prueba pueda poner en rojo; es como IN-05. Hay que preguntar al cliente y al backend quién carga los horarios |
| H-05 | Modelo | La app no lee `eliminado`: si el backend devolviera horarios eliminados, se pintarían | Sin datos ni forma de crearlos, no se puede saber si el backend los filtra |
| H-08 | Contrato | El formato de `horaInicio` y `horaFin` (`HH:mm` o `HH:mm:ss`) es una suposición del contrato propuesto | No hay respuestas reales |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | `200 []` → lista vacía de entidades; la conexión recibe la llave del grupo | ✅ |
| 2 | U-Repo | Un 503 y el 406 → pasan sin cambios | ✅ |
| 3 | U-Repo | 200 → la entidad conserva llave, día, horas y escenario | ✅ |
| 4 | U-Repo | La conexión lanza un `TypeError` → error devuelto | ❌ HO-02 |
| 5 | U-Repo | El `id` del modelo llega a la entidad | ❌ HO-01 (corregido 2026-11-04) |
| 6 | I-Local | 200 → query con la llave; la tarjeta recibe sus horarios | ✅ |
| 7 | I-Local | `200 []` → tarjeta vacía y sin error | ✅ |
| 8 | I-Local | Dos grupos → una petición por grupo; sin red cada tarjeta muestra `Código: 503` | ✅ |
| 9 | I-Local | 200 con un objeto → `Código: 406` en la tarjeta | ✅ |
| 10 | I-Local | El `id` del JSON llega a la tarjeta | ❌ HO-01 (corregido 2026-11-04) |
| 11 | I-Local | Horario con `dia: null` → error con formato `Código: …` | ❌ HO-03 |
| 12 | I-Local | Grupo con `&` → la query de `/horarios` llega completa | ❌ GR-05 |
| 13 | I-Remota | Grupo nuevo → tarjeta vacía y sin error | ✅ |
| 14 | I-Remota | Grupo nuevo → sección de horarios de la pantalla del grupo vacía y sin error | ✅ |
| 15 | I-Remota | Grupo inexistente → tarjeta vacía, sin excepción | ✅ |

## Módulo 9a: diagnóstico por pruebas de alumnos (2026-10-29)

Plan: [plan-diagnostico-alumnos.md](plan-diagnostico-alumnos.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

En la app, "alumnos" es la **lista de alumnos del grupo** (`GET /alumnosGrupo`), la que carga la pantalla del grupo y a la que se le toma asistencia. El registro de alumnos pertenece al módulo de autenticación, aplazado al final. Recorrido de los 142 grupos de la BD de pruebas:
- 70 grupos sin alumnos responden `200` con el objeto `GC-0002`, nunca con el `404` documentado.
- 72 grupos traen 112 alumnos, sin nulos en los campos obligatorios.
- `codigo` e `imagen` llegan a `null` en los 112.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/alumnoRepositorio_test.dart` (nuevo) | 3 | — |
| U-Repo (diagnóstico) | `test/diagnostico/alumnos/repositorio_diagnostico_test.dart` | — | 1 (AL-02) |
| I-Local: `DetalleGrupoViewModel` (alumnos) → conexión real → transporte falso | `test/integracion/alumnos_integracion_test.dart` (nuevo; fixtures reales en `test/contratos/alumnos/`) | 3 | — |
| I-Local (diagnóstico) | `test/diagnostico/alumnos/integracion_diagnostico_test.dart` | — | 3 (AL-01, AL-03, AL-04) |
| I-Remota: VM → backend real | `test/remoto/viewModel/alumno/vmAlumnoDiagnosticoTest.dart` (nuevo, en `main_test.dart`) | 3 | — |

Resultado:
- Suite sin backend: **231 en verde** (antes 225).
- Suite remota: **100 en verde** (antes 97).
- `test/diagnostico`: 70 pruebas, de ellas 68 rojas, 1 verde (control) y 1 omitida; 4 de las rojas son de alumnos.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios).

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| AL-03 | Conexión → VM | El `404` que documenta el backend para un grupo sin alumnos ("No existen alumnos para el grupo consultado") aparece en la pantalla del grupo como **error** (`Código: 404 - …`) en lugar de lista vacía. Solo el objeto `GC-0002` se trata como vacío | `integracion_diagnostico` · AL-03 | **Prueba** con la respuesta documentada en `/v3/api-docs`. Hoy el backend responde `GC-0002` en los 70 grupos vacíos, así que no se ve en uso real | B | app + backend (contrato y comportamiento no coinciden) | **confirmado** (latente) |
| AL-01 | Modelo | `Alumnomodelo.fromJson` no lee `codigo` ni `imagen`: aunque el JSON los traiga, la pantalla del grupo recibe `[null, null]`. Es la causa de AS-05 vista desde la lista | `integracion_diagnostico` · AL-01 (`Actual: [null, null]`) | **Prueba.** Hoy el backend los manda a `null` en los 112 alumnos, así que no se pierde ningún dato real | B | app | **confirmado** (latente) |
| AL-04 | Conexión | Un alumno con `nombre: null` hace que la pantalla del grupo muestre `type 'Null' is not a subtype of type 'String'`: `fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio (llamada fuera del `try`) lo capturan | `integracion_diagnostico` · AL-04 | **Prueba.** El JSON incompleto lo fabrica la prueba; ningún alumno real tiene nulos obligatorios | B | app | **confirmado** (latente) |
| AL-02 | Repositorio | Un `TypeError` de la conexión atraviesa `listarAlumnosGrupo` | `repositorio_diagnostico` · AL-02 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; AL-04 demuestra que la conexión real lo deja pasar | B | app | **confirmado** |

Ya registrados que afectan a esta lista: **GR-05** (`/alumnosGrupo` sin codificar; confirmado contra el backend) y **GR-06** (el alumno desvinculado sigue en la lista).

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-05 | La lista no trae los datos con que se registró el alumno | `vmAlumnoDiagnosticoTest` · prueba1: nombre, correo, sexo, tipo de documento y tipo de alumno coinciden, con tres combinaciones distintas (CC/Estudiante, TI/Docente, CE/Administrativo) |
| H-06 | Un alumno de otro grupo del mismo curso aparece en este | prueba1: G1 lista solo a A y B; G2 solo a C |
| H-07 | Un grupo sin alumnos, o inexistente, da error | prueba2 y prueba3: sección vacía y sin error |

### Hipótesis sin verificar u observaciones (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no es hallazgo |
|---|---|---|---|
| H-08 | Modelo | `eliminadoestado` llega, pero ni la entidad ni el VM lo usan | No hay forma de dar de baja un alumno por la API; GR-06 muestra que un desvinculado llega con `eliminadoestado: 0` |
| AL-V1 | Vista / rutas | `AlumnosView` y `AlumnoView` son **maquetas**: 20 tarjetas "alumno N" y nombres escritos a mano. Ninguna pantalla navega a `AppRutas.alumnos`, así que no se pueden alcanzar | Es de la vista y no se llega a ellas |
| AL-V2 | Rutas | `route_generator.dart:32` importa `views/alumnos/alumnosView.dart`, pero el archivo es `AlumnosView.dart`: no compila en un sistema que distingue mayúsculas. Es el mismo caso que CAT-11 | Confirmado leyendo el código; en Windows ninguna prueba puede ponerlo en rojo |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | `200 []` → lista vacía de entidades; la conexión recibe la llave del grupo | ✅ |
| 2 | U-Repo | Un 503 y el 406 de grupo vacío → pasan sin cambios | ✅ |
| 3 | U-Repo | 200 → la entidad conserva los 8 campos del modelo | ✅ |
| 4 | U-Repo | La conexión lanza un `TypeError` → error devuelto | ❌ AL-02 |
| 5 | I-Local | 200 real → query con la llave; lista con id, nombre, tipo, sexo y tipo de documento | ✅ |
| 6 | I-Local | `GC-0002` real de grupo vacío → lista vacía sin error | ✅ |
| 7 | I-Local | Sin red → `Código: 503` | ✅ |
| 8 | I-Local | `codigo` e `imagen` del JSON llegan a la pantalla | ❌ AL-01 |
| 9 | I-Local | El 404 documentado de grupo sin alumnos → lista vacía sin error | ❌ AL-03 |
| 10 | I-Local | Alumno con `nombre: null` → error con formato `Código: …` | ❌ AL-04 |
| 11 | I-Remota | Tres alumnos registrados con datos distintos e inscritos en dos grupos → cada grupo lista solo a los suyos, con sus datos | ✅ |
| 12 | I-Remota | Grupo sin alumnos → sección vacía y sin error | ✅ |
| 13 | I-Remota | Grupo inexistente → sección vacía, sin excepción | ✅ |

## Módulo 9b: diagnóstico por pruebas de instructores y facultades (2026-10-29)

Plan: [plan-diagnostico-instructores-facultades.md](plan-diagnostico-instructores-facultades.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

En la app, las dos listas solo se leen: `GET /instructores` llena el desplegable del formulario de grupo (coordinador) y `GET /facultades` el del registro del alumno. Además, el menú del coordinador abre la pantalla "Instructores". Observado en la BD de pruebas: `/instructores` responde `200` con 1 instructor sin nulos y `/facultades` con 1 facultad. La API no permite crear ni borrar ninguno de los dos, así que el `404` documentado de "lista vacía" no se puede provocar contra el backend.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Repo | `test/unitarias/repositorio/instructoresRepositorio_test.dart` (nuevo) y `facultadesRepositorio_test.dart` (+1) | 4 | — |
| U-Repo (diagnóstico) | `test/diagnostico/facultades/repositorio_diagnostico_test.dart` | — | 1 (FA-02) |
| I-Local: VM → conexión real → transporte falso | `test/integracion/instructores_integracion_test.dart` y `facultades_integracion_test.dart` (nuevos; fixtures reales en `test/contratos/instructores/` y `test/contratos/facultades/`) | 8 | — |
| I-Local (diagnóstico) | `test/diagnostico/instructores/integracion_diagnostico_test.dart` y `test/diagnostico/facultades/integracion_diagnostico_test.dart` | — | 5 (IT-01, IT-02, FA-01, FA-03, FA-04) |
| I-Local (vista, diagnóstico): ruta real `AppRutas.instructores` | `test/diagnostico/instructores/vista_diagnostico_test.dart` | 1 (control IT-03) | 1 (IT-03) |
| I-Remota: VM → backend real | `test/remoto/viewModel/instructor/vmInstructorDiagnosticoTest.dart` (nuevo, en `main_test.dart`) | 2 | — |

Resultado:
- Suite sin backend: **243 en verde** (antes 231).
- Suite remota: **102 en verde** (antes 100).
- `test/diagnostico`: 78 pruebas, de ellas 75 rojas, 2 verdes (controles) y 1 omitida; 7 de las rojas son de este módulo.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios); los archivos nuevos solo suman infos `file_names`.

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| IT-03 | Vista | La pantalla "Instructores" del menú del coordinador muestra **20 instructores inventados** ("Instructor 0" a "Instructor 19", todos "Activo"). No pide nada al backend: el instructor real no aparece. Es una maqueta, y a diferencia de `AlumnosView` (AL-V1) **sí se llega** a ella | `vista_diagnostico` · IT-03 (`Found 1 widget with text "Instructor 0"`); su control (la ruta abre la pantalla) está en verde | **Prueba** con la ruta real y la sesión del coordinador | M | app | **confirmado** |
| IT-01 | Conexión → VM | El `404` que documenta el backend cuando no hay instructores aparece en el formulario de grupo como `Código: 404 - {"codigoError":"GC-0003","mensaje":"No existen instructores registrados"}`, con el JSON crudo, en lugar de lista vacía | `integracion_diagnostico` · IT-01 | **Prueba** con la respuesta documentada en `/v3/api-docs`. Hoy hay un instructor y no se puede vaciar la lista por la API | B | app + backend (contrato y comportamiento por confirmar) | **confirmado** (latente) |
| FA-03 | Conexión → VM | Lo mismo en el registro con el `404` documentado de "No existen facultades registradas": `Código: 404 - {"codigoError":…}` | `integracion_diagnostico` · FA-03 | **Prueba** con la respuesta documentada. Hoy hay una facultad | B | app + backend | **confirmado** (latente) |
| FA-01 | Conexión | Una facultad con `nombre: null` hace que el registro muestre `type 'Null' is not a subtype of type 'String'`: `fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio (sin `try`) lo capturan. La conexión de instructores sí captura todo (H-04 descartada) | `integracion_diagnostico` · FA-01 | **Prueba.** El JSON incompleto lo fabrica la prueba; la facultad real no tiene nulos | B | app | **confirmado** (latente) |
| FA-02 | Repositorio | Un `TypeError` de la conexión atraviesa `listarFacultades` | `repositorio_diagnostico` · FA-02 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; FA-01 demuestra que la conexión real lo deja pasar | B | app | **confirmado** |
| IT-02 | VM | `InstructoresViewModel` no usa `NotificacionSegura`: si se sale del formulario de grupo antes de que llegue la lista, lanza `A InstructoresViewModel was used after being disposed` | `integracion_diagnostico` · IT-02 (`FlutterError`) | **Prueba.** Esa aserción de Flutter solo salta en modo debug. Mismo caso que CAT-04 | B | app | **confirmado** |
| FA-04 | VM | Lo mismo con `Facultadesviewmodel` al salir del registro: `A Facultadesviewmodel was used after being disposed` | `integracion_diagnostico` · FA-04 (`FlutterError`) | **Prueba.** Solo en modo debug | B | app | **confirmado** |

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-04 | Un instructor con `id: null` muestra el texto técnico | `instructores_integracion` · instructor sin id → `Código: 0 - …`: la conexión lo captura con `catch (e)` |
| H-08 | La lista de instructores llega con campos vacíos o ids repetidos (el desplegable pinta `nombre - id`) | `vmInstructorDiagnosticoTest` · prueba1 |
| H-09 | Un alumno recién registrado aparece entre los instructores y se le podría asignar un grupo | `vmInstructorDiagnosticoTest` · prueba2: ni su id ni su correo están en la lista |

### Hipótesis sin verificar u observaciones (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no es hallazgo |
|---|---|---|---|
| H-10 | Repositorio | `Instructoresrepositorio` llama a la conexión fuera del `try`, como AL-02 | Su conexión real captura todo, así que ese camino no ocurre; un doble que lanzara aceptaría lo que la conexión real no hace |
| H-11 | Backend | Qué cuerpo trae de verdad el `404` de lista vacía (`/v3/api-docs` lo describe como un arreglo de DTO) | No se puede vaciar ninguna de las dos listas por la API; IT-01 y FA-03 usan la forma `GC-0003` de los demás 404 |
| IT-V1 | Vista / rutas | `InstructorView` (detalle) también es una maqueta: solo se llega desde la pantalla de IT-03 | Se resuelve con IT-03 |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Repo | Instructores `200 []` → lista vacía de entidades | ✅ |
| 2 | U-Repo | Instructores: un 503 y un 406 → pasan sin cambios | ✅ |
| 3 | U-Repo | Instructores 200 → la entidad conserva los 4 campos | ✅ |
| 4 | U-Repo | Facultades: un 503 y un 406 → pasan sin cambios | ✅ |
| 5 | U-Repo | Facultades: la conexión lanza un `TypeError` → error devuelto | ❌ FA-02 |
| 6 | I-Local | Instructores 200 real → 1 petición, lista con los 4 campos | ✅ |
| 7 | I-Local | Instructores `200 []` → lista vacía sin error | ✅ |
| 8 | I-Local | Instructores sin red → `Código: 503` | ✅ |
| 9 | I-Local | Instructores 200 con un objeto → `Código: 406` | ✅ |
| 10 | I-Local | Instructor con `id: null` → error con formato `Código: …` | ✅ |
| 11 | I-Local | Instructores: el 404 documentado → lista vacía sin error | ❌ IT-01 |
| 12 | I-Local | Instructores: respuesta después de `dispose` → no lanza | ❌ IT-02 |
| 13 | I-Local | Facultades 200 real → `['fiet']` | ✅ |
| 14 | I-Local | Facultades sin red → `Código: 503` | ✅ |
| 15 | I-Local | Facultades 200 con un objeto → `Código: 406` | ✅ |
| 16 | I-Local | Facultad con `nombre: null` → error con formato `Código: …` | ❌ FA-01 |
| 17 | I-Local | Facultades: el 404 documentado → lista vacía sin error | ❌ FA-03 |
| 18 | I-Local | Facultades: respuesta después de `dispose` → no lanza | ❌ FA-04 |
| 19 | I-Local (vista) | Control: la ruta `AppRutas.instructores` abre la pantalla | ✅ |
| 20 | I-Local (vista) | La pantalla "Instructores" muestra los instructores del backend y no otros | ❌ IT-03 |
| 21 | I-Remota | Cada instructor trae sus 4 campos y su id no se repite | ✅ |
| 22 | I-Remota | Un alumno recién registrado no aparece entre los instructores | ✅ |

## Módulo 6b: diagnóstico por pruebas de la escritura de horarios (2026-11-04)

Plan: [plan-diagnostico-horarios-escritura.md](plan-diagnostico-horarios-escritura.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

**Cambio del backend:** `/v3/api-docs` publica ahora `POST /horario?categoria&curso&anio&iterable`, `PUT /horario?id=` y `DELETE /horario?id=`, con cuerpo `{dia, horaInicio, horaFin, escenario}`. Eso resuelve la parte del backend de **H-07** del módulo 6 (no había forma de registrar horarios). Lo observado a mano está en `test/contratos/horarios/LEEME.md`: el backend valida campos vacíos, formato de hora y rango (400 por campo), responde 404 `GC-0003` a un grupo u horario inexistente, y un horario eliminado deja de listarse. La app sigue sin usar ninguna de las tres rutas.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| I-Local (vista, diagnóstico): pantalla del grupo con su VM y dobles, con un `NavigatorObserver` | `test/diagnostico/horarios/vista_diagnostico_test.dart` (nuevo) | 1 (control HO-04) | 2 (HO-04, HO-05) |
| I-Remota: lectura real (`Horariosviewmodel`, `DetalleGrupoViewModel`) con horarios sembrados por `POST`/`PUT`/`DELETE` directos | `test/remoto/viewModel/horario/vmHorarioDiagnosticoTest.dart` (+3 casos, en `main_test.dart`) | 3 | — |

Resultado:
- Suite sin backend: **271 en verde** (sin cambios).
- Suite remota: **107 en verde** (antes 104).
- `test/diagnostico`: 75 pruebas, de ellas 71 rojas, 3 verdes (controles) y 1 omitida; 2 de las rojas son de este módulo.
- `flutter analyze`: 0 errores y 31 warnings (sin cambios).

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| HO-04 | Vista | "AGREGAR HORARIO", en la pantalla del grupo, no abre nada (`onPressed: () {}` en `widgetListaHorarios.dart`): no hay formulario, ruta ni método en ninguna capa para crear un horario, aunque el backend ya lo permite | `vista_diagnostico` · HO-04 (`Expected: a value greater than <0>`, `Actual: <0>` pantallas abiertas); su control (pinta los horarios y el botón) está en verde | **Prueba** con la pantalla y su VM reales. **Leído en el código:** tampoco hay forma de editar un horario | M | app | **confirmado** |
| HO-05 | Vista | El botón de cerrar de la tarjeta de un horario no elimina ni pide confirmación: `MiniTarjeta.iconoAccion` solo hace `print('hola')` | `vista_diagnostico` · HO-05 (`Actual: <0>`) | **Prueba.** `MiniTarjeta` es compartida: el mismo botón muerto aparece donde se use con `existeBotonCierre: true` | M | app | **confirmado** |

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| H-10 | Un horario creado en el backend no llega completo a la app | `vmHorarioDiagnosticoTest` · prueba4: id, día, horas y escenario llegan a la tarjeta (`Horariosviewmodel`) y a la pantalla del grupo (`DetalleGrupoViewModel`) |
| H-11 | Un horario editado se sigue viendo con los datos viejos | prueba5 |
| H-12 | Un horario eliminado sigue en la lista, como pasa con las clases (CL-01) | prueba6: deja de aparecer |

### Hipótesis sin verificar u observaciones (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no es hallazgo |
|---|---|---|---|
| H-13 | Backend / cliente | El backend acepta un día que no existe (`Xyz`) y dos horarios idénticos (mismo día y horas) en el mismo grupo | Observado a mano. Qué días son válidos y si se permiten solapes es una regla del cliente |
| H-14 | Backend → vista | Las horas se devuelven como se enviaron, así que un grupo puede mostrar `08:00 - 10:00` junto a `14:00:00 - 15:30:00` | Observado a mano y fijado en prueba4. Es de presentación; conviene que la app envíe siempre `HH:mm` cuando implemente la creación |
| H-15 | Conexión → VM | Cuando la app implemente la escritura, los 400 llegan como un objeto por campo (`{"dia": "…"}`); con `fromDioException` el usuario vería el JSON crudo, como en IT-01 | No hay código que lo use todavía; queda para las pruebas de la implementación |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | I-Local (vista) | Control: la pantalla del grupo pinta los dos horarios del contrato y el botón "AGREGAR HORARIO" | ✅ |
| 2 | I-Local (vista) | Tocar "AGREGAR HORARIO" abre un formulario o un diálogo | ❌ HO-04 |
| 3 | I-Local (vista) | Tocar cerrar en la tarjeta de un horario pide confirmación | ❌ HO-05 |
| 4 | I-Remota | Dos horarios creados (`HH:mm` y `HH:mm:ss`) llegan completos a la tarjeta y a la pantalla del grupo | ✅ |
| 5 | I-Remota | Un horario editado se ve con sus datos nuevos | ✅ |
| 6 | I-Remota | Un horario eliminado deja de aparecer | ✅ |

## Seguimiento en Jira (2026-10-29)

Los 57 hallazgos abiertos del 2026-10-29, más HO-04 y HO-05 (módulo 6b, 2026-11-04), están en el backlog del proyecto **SCRUMBAN** (DEPORTE PARA TODOS; la clave era SCRUM hasta el 2026-11-05 y Jira redirige las claves viejas), como tareas de la Epic [SCRUMBAN-39](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-39) «MP — Corrección de hallazgos del diagnóstico por pruebas». Cada tarea lleva las etiquetas `backlog`, `diagnostico`, el módulo y su ID (más `latente` o `backend` cuando aplica). La prioridad sale de la severidad: M → Medium, B → Low. Al corregir un hallazgo, se cierra también su tarea.

| ID | Jira | ID | Jira | ID | Jira |
|---|---|---|---|---|---|
| X-01 | [SCRUMBAN-40](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-40) | AS-01 | [SCRUMBAN-41](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-41) | AS-02 | [SCRUMBAN-42](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-42) |
| AS-03 | [SCRUMBAN-43](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-43) | AS-06 | [SCRUMBAN-44](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-44) | AS-07 | [SCRUMBAN-45](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-45) |
| AS-08 | [SCRUMBAN-46](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-46) | AS-12 | [SCRUMBAN-47](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-47) | IN-08 | [SCRUMBAN-48](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-48) |
| IN-09 | [SCRUMBAN-49](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-49) | IN-10 | [SCRUMBAN-50](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-50) | IN-11 | [SCRUMBAN-51](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-51) |
| IN-12 | [SCRUMBAN-52](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-52) | IN-13 | [SCRUMBAN-53](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-53) | ES-01 | [SCRUMBAN-54](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-54) |
| ES-02 | [SCRUMBAN-55](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-55) | ES-03 | [SCRUMBAN-56](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-56) | ES-04 | [SCRUMBAN-57](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-57) |
| ES-05 | [SCRUMBAN-58](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-58) | GR-01 | [SCRUMBAN-59](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-59) | GR-02 | [SCRUMBAN-60](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-60) |
| GR-03 | [SCRUMBAN-61](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-61) | GR-04 | [SCRUMBAN-62](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-62) | GR-05 | [SCRUMBAN-63](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-63) |
| GR-06 | [SCRUMBAN-64](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-64) | CU-01 | [SCRUMBAN-65](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-65) | CU-02 | [SCRUMBAN-66](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-66) |
| CU-03 | [SCRUMBAN-67](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-67) | CU-04 | [SCRUMBAN-68](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-68) | CU-05 | [SCRUMBAN-69](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-69) |
| CAT-01 | [SCRUMBAN-70](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-70) | CAT-02 | [SCRUMBAN-71](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-71) | CAT-03 | [SCRUMBAN-72](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-72) |
| CAT-04 | [SCRUMBAN-73](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-73) | CAT-05 | [SCRUMBAN-74](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-74) | CAT-06 | [SCRUMBAN-75](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-75) |
| CAT-09 | [SCRUMBAN-76](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-76) | CAT-13 | [SCRUMBAN-77](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-77) | CAT-14 | [SCRUMBAN-78](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-78) |
| CL-01 | [SCRUMBAN-79](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-79) | CL-03 | [SCRUMBAN-80](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-80) | CL-04 | [SCRUMBAN-81](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-81) |
| CL-05 | [SCRUMBAN-82](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-82) | HO-01 | [SCRUMBAN-83](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-83) | HO-02 | [SCRUMBAN-84](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-84) |
| HO-03 | [SCRUMBAN-85](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-85) | AL-01 | [SCRUMBAN-86](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-86) | AL-02 | [SCRUMBAN-87](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-87) |
| AL-03 | [SCRUMBAN-88](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-88) | AL-04 | [SCRUMBAN-89](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-89) | IT-01 | [SCRUMBAN-90](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-90) |
| IT-02 | [SCRUMBAN-91](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-91) | IT-03 | [SCRUMBAN-92](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-92) | FA-01 | [SCRUMBAN-93](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-93) |
| FA-02 | [SCRUMBAN-94](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-94) | FA-03 | [SCRUMBAN-95](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-95) | FA-04 | [SCRUMBAN-96](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-96) |
| HO-04 | [SCRUMBAN-97](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-97) | HO-05 | [SCRUMBAN-98](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-98) |  |  |
| CU-06 | [SCRUMBAN-99](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-99) | CU-07 | [SCRUMBAN-100](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-100) | DE-01 | [SCRUMBAN-101](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-101) |
| GR-07 | [SCRUMBAN-102](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-102) | GR-08 | [SCRUMBAN-103](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-103) |  |  |

**Cerradas en Jira (Finalizado, 2026-11-05):** las seis corregidas que estaban abiertas, GR-02 (SCRUMBAN-60), HO-01 (SCRUMBAN-83), CAT-14 (SCRUMBAN-78), CAT-05 (SCRUMBAN-74), CU-05 (SCRUMBAN-69) y CU-03 (SCRUMBAN-67); y las cinco halladas y corregidas el 2026-11-04 y 05 (CU-06, CU-07, DE-01, GR-07, GR-08), creadas en la Epic ya cerradas. Antes de cerrar se comprobó que ninguna de las seis tiene prueba de diagnóstico en rojo y que los 53 hallazgos abiertos siguen con la suya en rojo. Quedan 53 tareas en «Por hacer».
