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
| O-02 | Vista `Grupo` | **Observación (2026-11-19, sin prueba roja):** el encabezado de la pantalla del grupo es una maqueta: la tarjeta del instructor muestra siempre «Edynson Muñoz Jimenez», su botón de cerrar no hace nada (desde AS-01 solo lo ve el coordinador), y el buscador «buscar instructor...» y «FINALIZAR GRUPO» tampoco hacen nada. Mismo caso que IT-03 | — | Lectura de `grupo.dart` | M | app | observación |
| X-01 | Widget `DialogError` | El parámetro `codigo` no se pinta en ninguna de las dos formas del diálogo ([dialogError.dart](../lib/presentation/view/widgets/dialogError.dart)). Un 503 (sin red) y un 500 (servidor) se ven igual salvo por el texto | `dialogError_diagnostico_test` ×2: no aparece `503` | **Prueba** | B | app | **confirmado**; **corregido** (2026-11-19): las dos formas del diálogo muestran «Código: N» debajo del mensaje (no si el código es 0 o negativo, que no viene del servidor). Prueba en `unitarias/vista/dialogError_test.dart` |

## Módulo 1: Toma de asistencias

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| AS-B01 | Backend | No existían `GET /atencionesporclase` ni `POST /atenciones` (404); la funcionalidad no se podía usar en ningún entorno. El 2026-10-29 el backend publicó `GET`/`POST /asistenciasClase?idClase=` con otra forma (`{alumno, asistio}` al leer, `{idPerfil, asistio}` al registrar) y la app se adaptó: conexión, modelo y contrato en `test/contratos/atenciones/` | `/v3/api-docs` del 2026-10-29; `VmAtencionTest.prueba4ClaseInexistente` (404 `GC-0003` para una clase que no existe); ciclo cargar → marcar → guardar → recargar comprobado a mano contra la clase 207 de la BD de pruebas | **API del backend + prueba remota** | A | backend + app | **corregido** (2026-10-29). **Reabierto como BK-02 el 2026-11-05:** el backend nuevo ya no publica `/asistenciasClase` |
| AS-01 | Navegación / roles | **Si llegan a la pantalla del grupo**, un alumno y un usuario sin sesión ven "AGREGAR CLASE" y el botón de eliminar clase, y abren la toma de asistencia: ni esa pantalla ni la ruta `clase` comprueban el rol. En la app (2026-10-29) el alumno **no llega** a esa pantalla: por el catálogo se queda en la lista de cursos, porque tocar un curso solo navega para el coordinador ([cursos.dart:184](../lib/presentation/view/views/curso/cursos.dart), ver O-01); en inscripciones solo ve los cursos a los que puede inscribirse; y el menú lateral muestra "grupos asignados" solo al instructor. Lo mismo vale sin sesión. Lo que falta es la comprobación en la pantalla y en la ruta (defensa en profundidad), no un camino abierto conocido. Que coordinador e instructor vean "AGREGAR CLASE" es lo esperado | `vista_diagnostico` · AS-01 alumno y AS-01 sin sesión (control en verde) | **Prueba + emulador.** La prueba monta la pantalla del grupo **directamente**, sin pasar por la navegación: demuestra lo que hace la pantalla, no que se pueda llegar a ella. Que no se llega sale de lo que observó el usuario en el emulador y de leer `cursos.dart` | A → **M** (no hay camino conocido en la interfaz) | app | **corregido** (2026-11-19) para alumno y sin sesión: la pantalla del grupo muestra «AGREGAR CLASE», eliminar clase y la toma de asistencia solo a quien dicta la clase (coordinador e instructor), y el botón de la tarjeta del instructor solo al coordinador; las rutas `grupo`, `clase` y `formularioClase` exigen esos roles (`AccesoRutas` + `RutaProtegida`). **Sigue pendiente** el instructor ajeno al grupo: espera la regla 3.4-1 (su caso sigue omitido en `unitarias/vista/grupoRoles_test.dart`) |
| AS-02 | Vista | Dos toques a "Guardar" mientras el primer envío sigue en camino → **2** registros enviados | `vista_diagnostico` · AS-02 (`Expected: <1>`, `Actual: <2>`); `integracion_diagnostico` · AS-02 (2 POST en la red) | **Prueba** (pantalla y de punta a punta). **Inferido:** que se dupliquen los registros en la base de datos depende de si un segundo POST reemplaza o agrega (pregunta 2 del contrato) | M (A si se confirma B-01) | app | **corregido** (2026-11-06): `Atencionviewmodel` ignora un segundo envío mientras hay uno en camino y la vista deshabilita «Guardar» (`puedeRegistrar`). Prueba en `unitarias/vista/claseGuardar_test.dart` y `integracion/atencionesErrores_integracion_test.dart` |
| AS-03 | Vista / VM | Tras una carga con 500, "Guardar" sigue activo y muestra "No hay alumnos para registrar", lo que oculta el error real | `vista_diagnostico` · AS-03 | **Prueba** | M | app | **corregido** (2026-11-06): «Guardar» queda deshabilitado si la carga falló, está cargando o no hay alumnos, y el vm devuelve el error de carga en vez de «No hay alumnos para registrar». Prueba en `unitarias/vista/claseGuardar_test.dart` |
| AS-04 | Conexión | Con categoría `Fútbol & Voleibol` el backend recibe `categoria=Fútbol ` (el `&` corta el valor), así que se pide otra clase | `conexion_diagnostico` · AS-04 | **Prueba** (la URI que sale de la app). **Inferido:** que el backend responda con otra clase o con ninguna; no hay backend con el que comprobarlo | M (A si se confirma B-02) | app | **corregido** (2026-10-29): con `/asistenciasClase` la app solo envía `idClase`, ya no viaja texto en la query. Su prueba salió del diagnóstico; `conexionAtencionesRemoto_test` fija la query `{idClase}` |
| AS-05 | Modelo | Al registrar, cada alumno se reenvía con `codigo: null` (había `'104619011001'`) e `imagen: null`, y un alumno retirado (`eliminadoestado: 1`) se reenvía como activo (`0`). Causas: `Alumnomodelo.fromJson` no lee `codigo` ni `imagen`, `toJson` fija `eliminadoestado: 0` y `Alumnoentidad` no tiene ese campo. El repositorio no es la causa (E-02 en verde) | `conexion_diagnostico` · AS-05 ×2 (cadena real completa) | **Prueba** (el JSON que la app envía). **Inferido:** que se borren datos o se reactiven alumnos depende de si el backend guarda el alumno que va dentro de cada asistencia (pregunta 3 del contrato). La causa (qué línea pierde cada campo) sale de leer el código | M (A si se confirma B-03) | app + backend | **descartado** (2026-10-29): el contrato real (`RegistroAsistenciaDto`) solo recibe `{idPerfil, asistio}`, así que el alumno ya no se reenvía y no hay datos que perder. Sus dos pruebas salieron del diagnóstico. La pérdida de `codigo`/`imagen` en `Alumnomodelo` sigue existiendo, pero ya no afecta a la asistencia |
| AS-06 | Conexión | Un JSON con `estaAtendido: null` provoca un `TypeError` (`'Null' is not a subtype of type 'bool'`) que **escapa** de la conexión | `conexion_diagnostico` · AS-06 | **Prueba.** El JSON incompleto lo fabrica la prueba; no se sabe si el backend real lo enviaría alguna vez | M | app | **corregido** (2026-11-06): la conexión captura cualquier error (no solo `Exception`) y lo devuelve con código. Prueba en `unitarias/conexion/conexionAtencionesErrores_test.dart` |
| AS-07 | Conexión → VM | **201 sin cuerpo:** la conexión lanza un `TypeError` (`'Null' is not a subtype of type 'String'`, al armar `ErrorModelo.mensaje`). **204:** la conexión devuelve un error. En ambos casos el VM devuelve `Fallo`, así que el usuario ve un error **aunque la asistencia se guardó** | `conexion_diagnostico` · AS-07 ×2; `viewModel_diagnostico` · AS-07 ×2; `integracion_diagnostico` · AS-07 (el usuario ve `type 'Null' is not a subtype of type 'String'`) | **Prueba** (lo que hace la app ante 201 y 204). **Supuesto:** que el backend responda 201 o 204; los endpoints no existen y el código de éxito está por acordar (pregunta 1 del contrato). Si responde 200, el fallo no se ve en uso real | M (A si se confirma B-04) | app + backend | **corregido** (2026-11-06): la conexión y el vm tratan cualquier 2xx como éxito. Pruebas en `conexionAtencionesErrores_test.dart`, `atencionErrores_test.dart` y `atencionesErrores_integracion_test.dart` |
| AS-08 | Repositorio | Una atención con `idClase: 999` en un registro de la clase 210 llega a la red (1 llamada) | `viewModel_diagnostico` · AS-08 | **Prueba.** La entrada inconsistente la fabrica la prueba; la pantalla actual siempre envía el mismo `idClase` | B | app | **corregido** (2026-11-06): `registrarAtencionesClase` del repositorio rechaza, sin llamar a la red, una atención cuya `idClase` no es la de la petición. Prueba en `unitarias/viewModel/atencionErrores_test.dart` |
| AS-09 | VM | Tras un registro fallido, el VM no puede indicar que hay cambios sin guardar: no existe `hayCambiosSinGuardar` (`NoSuchMethodError`) | `viewModel_diagnostico` · AS-09 | **Prueba** de que la funcionalidad falta. **Propuesta:** el nombre y el comportamiento de `hayCambiosSinGuardar` son míos, no un requisito acordado | M | cliente | **requisito propuesto**: espera la respuesta C-08 del cliente; la prueba pide una API sugerida por el diagnóstico, no acordada |
| AS-10 | Vista | "Cancelar" o atrás descartan las marcas sin avisar | — | **Código + regla pendiente.** Leído en `claseView.dart`; sin prueba hasta conocer la regla del cliente | B | cliente | hipótesis (espera la regla 3.4-6) |
| AS-11 | Modelo / VM | Se listan alumnos eliminados o retirados | — | **Código + regla pendiente.** El VM no filtra por `eliminadoestado`; sin prueba | M | backend + cliente | hipótesis (espera la regla 3.4-4) |
| AS-12 | Conexión | `receiveTimeout` se reporta con código 0 en vez de 408 | `conexion_diagnostico` · AS-12 (`Actual: <0>`) | **Prueba** | B | app | **corregido** (2026-11-06): `RespuestaModelo.fromDioException` responde 408 también para `receiveTimeout` (todas las conexiones). Prueba en `conexionAtencionesErrores_test.dart` |
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
| U-Repo (diagnóstico) | `test/diagnostico/inscripciones/repositorio_diagnostico_test.dart` | — | 2 (IN-12; corregido el 2026-11-05: pasaron a `unitarias/repositorio/`, archivo eliminado) |
| I-Local: VM → conexión real → transporte falso | `test/integracion/inscripcion_integracion_test.dart` (nuevo) | 4 | — |
| I-Local (diagnóstico) | `test/diagnostico/inscripciones/integracion_diagnostico_test.dart` | — | 4 (IN-08, 09, 10, 11; los cuatro corregidos y movidos a la suite de integración el 2026-11-05, archivo eliminado) |
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
| IN-11 | Modelo / conexión | Una inscripción con `fechaInscripcion` no se puede enviar: el VM devuelve `Fallo(0, "null")`. Causa probable: `Inscripcionmodelo.toJson` pone el `DateTime` sin convertir y el JSON no se puede codificar | `integracion_diagnostico` · IN-11 (`Fallo 0 null (POST …/inscripcion)`) | **Prueba.** La entrada con fecha la fabrica la prueba: la pantalla actual **nunca** pone fechas, así que hoy no se ve en uso real. La causa sale de leer el código | B | app | **corregido** (2026-11-05): `Inscripcionmodelo.toJson` envía las dos fechas con `toIso8601String()`; una fecha ausente sigue yendo nula. Contra el backend real, una fecha ISO da 201, pero el backend la ignora y pone la suya. La prueba pasó a `test/integracion/inscripcion_integracion_test.dart`, con un caso nuevo para `fechaDesvinculacion` |
| IN-12 | Repositorio | Un `TypeError` lanzado por la conexión **escapa** del repositorio (`agregarInscripcion` y `eliminarInscripcion` solo capturan `Exception`), cuando la regla del proyecto es devolver los errores | `repositorio_diagnostico` · IN-12 ×2 (`Instance of 'TypeError'`) | **Prueba.** El `TypeError` lo lanza el doble. **Inferido:** la conexión real puede lanzarlo ante un 2xx distinto del esperado y sin cuerpo (mismo mecanismo que AS-07); el VM lo atrapa y lo muestra como mensaje técnico (`Fallo(-1, …)`). **Comprobado al corregir:** la conexión real lo lanza ante un 2xx distinto del esperado con cuerpo JSON (`fromResponse` pone el mapa como mensaje) | B | app | **corregido** (2026-11-05): `agregarInscripcion` y `eliminarInscripcion` de la conexión ya capturan cualquier error, como `validarInscripcion`, y el repositorio también en sus tres métodos. Las dos pruebas pasaron a `unitarias/repositorio/inscripcionRepositorio_test.dart`, y `unitarias/conexion/conexionInscripcionRemoto_test.dart` suma dos casos con la conexión real. Sigue latente el arreglo de `fromResponse`, que comparte con BK-08 |
| IN-13 | Backend → VM | Desvincular a un alumno que no está inscrito da `404` con el **cuerpo vacío** y el `Fallo` llega con `mensaje: ''`. El alumno vería un diálogo de error sin texto (y sin código, X-01) | `remoto_diagnostico` · IN-13 (`Expected: non-empty`, `Actual: ''`; `Fallo 404  (POST …)`) | **Prueba contra el backend real.** Que el diálogo salga vacío se deduce de `DialogError` (pinta `mensaje`); no hay prueba de widget | M | backend (404 sin cuerpo) + app (sin texto por defecto cuando el mensaje viene vacío) | **corregido por el backend** (revisado 2026-11-05): el backend nuevo responde 404 `GC-0003` con cuerpo. La prueba pasó a verde sin tocar la app y se movió a la suite remota (`VmInscripcionTest.prueba8MensajeDelRechazo`). El mismo síntoma sigue en el 401 (IN-17), y el cuerpo llega como JSON crudo (IN-16) |

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

## Módulo 4: revisión contra el backend nuevo (2026-11-05)

Informe: [informe-diagnostico-inscripciones-backend-nuevo.md](informe-diagnostico-inscripciones-backend-nuevo.md). Backend arriba (`/v3/api-docs`, 66 rutas). Las tres rutas que usa la app (`POST /inscripcion`, `PUT /desvincularInscripcion`, `GET /validarInscripcion`) existen y aceptan lo que envía `Conexioninscripcionremoto`, incluida la clave `eliminado`, que el DTO ignora. Las pruebas de diagnóstico remotas ahora actúan con el JWT del alumno, como la pantalla.

| Suite | Resultado |
|---|---|
| Sin backend | 351 en verde |
| `test/diagnostico/inscripciones` | 14 en rojo, 2 controles en verde |
| `main_test` · Inscripcion del alumno remota | 5 en verde, 3 en rojo (5 en rojo en la primera corrida, por BK-09) |
| `main_test` · Grupos asignados e inscripcion remotos | 2 en verde, 2 en rojo |
| `main_test` · Periodo de inscripcion remoto | 7 en verde |

### Reclasificación

| ID | Estado | Motivo |
|---|---|---|
| IN-01 a IN-03 | **siguen corregidos** | Sus pruebas siguen en verde |
| IN-04 | **sin cambio** | Las rutas `PUT` ya no existen (BK-01). `PATCH /grupo/periodo` acepta varios grupos; no se comprobó si eso cierra la decisión D1 |
| IN-05 | **por comprobar** | El backend guarda las fechas por grupo; falta que el cliente confirme que no van por curso |
| IN-06 | **sigue corregido** | Sustituido por GR-02 |
| IN-07 a IN-10 | **siguen corregidos** | Sus pruebas siguen en verde, también contra el backend real |
| IN-11, IN-12 | **siguen** (corregidos después, el 2026-11-05) | Seguían en rojo. Ambos latentes: la pantalla no pone fechas y el backend responde 201 y 200 como espera la conexión |
| IN-13 | **corregido por el backend** | La prueba quedó en verde sin tocar la app |
| H-06, H-08 | **siguen descartadas** | Desvincular sin inscripción da 404; reactivar funciona (control de BK-09) |
| H-07 | **reabierta** | Era cierta con el backend anterior; hoy son BK-06 y BK-07 |
| H-09 | **reabierta en parte** | Grupo inexistente: 404. Alumno inexistente: 500 (BK-07) |
| H-12 | **descartada** | Los rechazos de `POST /inscripcion` traen cuerpo; el 404 de un grupo inexistente trae `GC-0003` |

### Hallazgos nuevos (prueba en rojo)

| ID | Capa | Síntoma observable | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| IN-14 | Backend | Un alumno inscrito que repite la inscripción con el grupo lleno **pierde el cupo**: pasa a `EN_ESPERA`, responde 201 y la app dice «Te has inscrito». `inscribir()` reactiva por `existsById` sin mirar si la fila ya está activa. Quedó el cupo libre y sin promover a nadie (`cuposDisponibles: 1`, `tamanoListaEspera: 1`) | `remoto_diagnostico` · BUG IN-14 (`Expected: true`, `Actual: <false>`) | **Prueba contra el backend real.** **Inferido:** que pase desde la pantalla, porque BK-09 muestra «Matricular» justo después de inscribirse; no se probó tocando el botón dos veces | A | backend | **corregido por el backend y en la app** (2026-11-06): el backend responde `409 GC-0007` «El alumno ya está inscrito en este grupo» (o «ya está en la lista de espera») al repetir, y ya no quita el cupo; comprobado con un grupo de cupo 1. La app además no envía la repetición (`Inscripcionviewmodel`). Pruebas: `unitarias/viewModel/gruposInscripcionViewModel_test.dart` y `VmInscripcionTest.prueba12RepetirConGrupoLleno` |
| IN-15 | Vista / VM | Un alumno en lista de espera ve «Matricular» y no tiene cómo saber que está en la lista ni cómo salir: `validarInscripcion` solo cuenta `INSCRITO`. Si pulsa, recibe 409 `GC-0007`. El backend sí deja desvincularlo y `/inscripcion/misCursos` trae el estado, pero la app no llama esa ruta | `inscripciones/vista_diagnostico` · BUG IN-15 (`Found 1 widget with text "Matricular"`) | **Prueba** de pantalla con los cuerpos observados; el 409 y el desvincular, por petición directa al backend | M | app | **corregido** (2026-11-06): `cargarEstados` pide `GET /inscripcion/misCursos` una vez y `enEspera(grupo)` lo expone. La tarjeta muestra «En lista de espera» con «Salir de la lista», que usa `PUT /desvincularInscripcion`. Si esa consulta falla y el alumno no aparece inscrito, muestra «Reintentar», no «Matricular». Comprobado contra el backend real en `prueba4CupoLleno` |
| IN-16 | Conexión → vista | Todo rechazo llega como la respuesta JSON entera: `Fallo.mensaje` es `{"codigoError":…}` y `DialogError` pinta cada clave, con `codigoHttp`, `url` y `metodo`. Afecta a grupo cerrado, límite de cursos, público del curso y lista de espera. Misma causa que IT-01 (`fromDioException`) | `remoto_diagnostico` · BUG IN-16 (`Expected: not contains 'codigoError'`); `vista_diagnostico` · BUG IN-16 (`Found 1 widget with text containing codigoError`) | **Prueba** (backend real y pantalla) | M | app | **corregido** (2026-11-06): `fromDioException` entrega solo el `mensaje` del backend, en todas las conexiones. Un 400 por campo sigue como JSON porque `DialogError` lista cada campo. Pruebas en `unitarias/modelo/respuestaModelo_test.dart`, `integracion/listaEspera_integracion_test.dart` y `VmInscripcionTest.prueba9RechazoLegible` |
| IN-17 | Conexión → vista | Con el token vencido, el 401 no trae cuerpo y `DialogError` se abre en blanco. Es el síntoma de IN-13 en otra respuesta | `remoto_diagnostico` · BUG IN-17 (`Expected: non-empty`, `Actual: ''`); `vista_diagnostico` · BUG IN-17 | **Prueba** (backend real y pantalla). **Inferido:** que ocurra en uso normal; depende de la vigencia del JWT | M | app | **corregido** (2026-11-06): un 401 sin cuerpo da «Tu sesión no está activa. Inicia sesión de nuevo.», un 403 da «No tienes permiso para realizar esta acción.» y otro código da un texto con el código. Pruebas en los mismos archivos y `VmInscripcionTest.prueba10SesionVencida` |

### Hipótesis sin verificar (no son hallazgos)

| Hip. | Capa | Hipótesis | Por qué no es hallazgo |
|---|---|---|---|
| H-IN-01 | Backend / cliente | El catálogo debería ocultar los grupos cuyo curso no va dirigido al alumno. Observado: `/gruposInscripcion` los lista y al inscribirse da 422 `GC-0030` | Falta la regla del cliente; no hay comportamiento correcto contra el cual poner una prueba en rojo |
| H-IN-02 | Cliente | El alumno debería saber antes de pulsar que llegó al límite de 3 cursos. Observado: la cuarta inscripción da 422 `GC-0014` | Falta la regla; el mensaje crudo ya es IN-16 |
| H-IN-03 | App | Editar un curso desde la app vuelve `publico` a `MIXTO`: `CursoModelo` no tiene ese campo y el backend toma el ausente como `MIXTO` | Solo lectura; es del módulo de cursos |
| H-IN-04 | App / cliente | Rutas sin pantalla: `/inscripcion/listaEspera`, `/inscripcion/promover`, `/inscripcion/disponibilidad`, `/inscripcion/tieneInscritos` | Falta saber si el cliente las quiere en la app móvil |
| H-IN-05 | Backend | Un alumno en lista de espera que se inscribe con un cupo libre pasa a `INSCRITO` sin respetar la cola | Solo lectura de `inscribir()` |
| H-IN-06 | Backend | BK-09 afecta a cerca de la mitad de las inscripciones | Se deduce del redondeo; no se midió |

---

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
| ES-01 | Repositorio | `EstadisticasRespositorio` no tiene ningún `try`: un `TypeError` de la conexión lo atraviesa en las tres rutas | `repositorio_diagnostico` · ES-01 (`Instance of 'TypeError'`) | **Prueba.** El `TypeError` lo lanza el doble; ES-02 demuestra que la conexión real también lo deja pasar | B | app | **corregido** (2026-11-06): las tres rutas del repositorio pasan por un solo método con `try` que devuelve cualquier error con `fromObjectError`. Prueba en `unitarias/repositorio/estadisticasRepositorioErrores_test.dart` |
| ES-02 | Modelo / conexión | Una fila con `leyenda1: null` hace que la sección muestre el texto de la excepción (`type 'Null' is not a subtype of type 'String'`) en lugar de un error con código: `fromJson` lanza un `TypeError`, la conexión solo captura `Exception`, el repositorio no captura nada (ES-01) y lo atrapa el `catch` del VM | `integracion_diagnostico` · ES-02 (`Expected: a string starting with 'Código: '`) | **Prueba.** La fila incompleta la fabrica la prueba: el backend real siempre manda `leyenda1` | B | app | **corregido** (2026-11-06): la conexión de estadísticas captura todo (no solo `Exception`) y devuelve el error con código. Prueba en `integracion/estadisticasErrores_integracion_test.dart` |
| ES-03 | Modelo | Un número entero en el JSON (`"clases": 2` en vez de `2.0`) rompe la sección con `type 'int' is not a subtype of type 'double'`: `fromJson` asigna `json['clases']` (y `horas`, `minutos`, `duracion`) directamente a un `double` | `integracion_diagnostico` · ES-03 (`Expected: null`, `Actual: "type 'int' is not a subtype of type 'double'"`) | **Prueba.** Hoy el backend manda `1.0`; si cambia a `Integer`, o un serializador omite el `.0`, las tres gráficas fallan | B | app | **corregido** (2026-11-06): `EstadisticaModelo.fromJson` convierte con `(valor as num).toDouble()`, así que `2` y `2.0` valen igual. Prueba en `integracion/estadisticasErrores_integracion_test.dart` |
| ES-04 | VM | El orden "de mayor a menor" solo mira `horas`: 1 h 10 min queda **delante** de 1 h 50 min (`_ordenarPorHoras` compara `b.horas` con `a.horas`) | `integracion_diagnostico` · ES-04 (`at location [0] is 'Una hora y diez' instead of 'Una hora y cincuenta'`) | **Prueba** | B | app | **corregido** (2026-11-06): el VM ordena por `duracion` (minutos totales), no solo por `horas`. Prueba en `integracion/estadisticasErrores_integracion_test.dart` |
| ES-05 | Backend | **El último día del rango no cuenta.** Una clase del 2026-10-28 (`fecha` guardada `2026-10-28`) da 0 clases con el rango `[2026-10-28, 2026-10-28]` y también con `[2026-10-27, 2026-10-28]`; con `[2026-10-28, 2026-10-29]` cuenta 1 clase y 120 min. El coordinador que pide "octubre" (hasta el 31) no ve las clases del 31 | `remoto_diagnostico` · ES-05 (`Expected: <1>`, `Actual: <0.0>`); confirmado a mano con las tres peticiones al backend | **Prueba contra el backend real.** **Inferido:** la causa probable es que se compara un *date-time* con `fin` a las 00:00; no se ha visto el código del backend | M | backend (o la app, enviando `fin + 1 día`, si se acuerda así) | **corregido por el backend** (revisado 2026-11-05): `cls_fecha` se compara con `between` y el rango `[ayer, ayer]` ya cuenta la clase. La prueba quedó en verde sin tocar la app y se movió a la suite remota (`VmEstadisticasAsistenciaTest.prueba3UltimoDiaDelRango`) |

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

## Módulo 5: revisión contra el backend nuevo (2026-11-05)

Informe: [informe-diagnostico-estadisticas-backend-nuevo.md](informe-diagnostico-estadisticas-backend-nuevo.md). Backend arriba. Las tres rutas que usa la app (`/estadisticas/{categorias,cursos,grupos}`) no cambiaron: mismos parámetros, misma forma, y solo las puede pedir el coordinador, igual que el menú.

**Cambio de siembra:** `VmEstadisticasAsistenciaTest` marcaba la asistencia con `POST /asistenciasClase`, que ya no existe (BK-02), y por eso su `setUpAll` fallaba. Ahora usa `PUT /clase/{codigo}/asistencia`. No se cambió ninguna aserción. Un caso nuevo con el ID BK-02 conserva la evidencia de ese bug.

| Suite | Resultado |
|---|---|
| Sin backend | 351 en verde |
| `test/diagnostico/estadisticas` | 9 en rojo |
| `main_test` · Estadisticas generales remotas | 4 en verde |
| `main_test` · Estadisticas con asistencias remotas | 6 en verde (antes no corría) |

### Reclasificación

| ID | Estado | Motivo |
|---|---|---|
| ES-01 a ES-04 | **siguen** | Siguen en rojo. ES-01, ES-02 y ES-03 son latentes: el backend siempre manda `leyenda1` y números con `.0`. ES-04 se ve con grupos de horario partido (ver ES-06) |
| ES-05 | **corregido por el backend** | La prueba quedó en verde sin tocar la app |
| H-06 a H-09 | **siguen descartadas** | Sus pruebas corren de nuevo y salen en verde |
| H-10, H-11 | **sin cambio** | Sigue faltando la regla. Rango invertido observado: 200 con todo en cero |
| H-12 | **sin cambio, ahora con la causa** | La consulta lee `tbl_clase` y no toca asistencias: mide clases dictadas |
| H-13 | **observado, falta la regla** | Una clase sin asistencia confirmada sumó igual: 2 clases y 240 min en lugar de 1 y 120. Petición directa, sin prueba |
| H-14, H-15 | **sin cambio** | El backend tampoco publica rutas de facultades o programas |

### Hallazgos nuevos (prueba en rojo)

| ID | Capa | Síntoma observable | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| ES-06 | Backend → vista | Los minutos no se pasan a horas: tres clases de 1 h 30 llegan como `horas: 3.0`, `minutos: 90.0`, `duracion: 270.0`. La gráfica solo pinta `horas`, así que muestra 3 en lugar de 4,5, y ese grupo queda detrás de uno de 4 h justas. Con horarios partidos el error crece con cada clase | `remoto_diagnostico` · BUG ES-06 (`Expected: <4>`, `Actual: <3.0>`); `integracion_diagnostico` · BUG ES-06 (`Expected: 'Tres clases de 1 h 30'`, `Actual: 'Cuatro horas justas'`) | **Prueba** (backend real y cadena local con la forma observada). Las pruebas anteriores no lo veían porque `horas × 60 + minutos == duracion` se sigue cumpliendo | M | backend (normalizar) o app (calcular desde `duracion`) | **corregido** (2026-11-06) en la app: `EstadisticaMapper` calcula `horas` y `minutos` desde la `duracion` total, y las gráficas pintan `duracion / 60` (4 h 30 = 4,5). Pruebas: `integracion/estadisticasErrores_integracion_test.dart` y, contra el backend real, `VmEstadisticasAsistenciaTest.prueba7MinutosAcumulados`. El backend sigue sumando horas y minutos por separado; normalizarlo allá es opcional |
| ES-07 | Conexión → VM | Con el token vencido, las tres secciones muestran `Código: 401 - ` sin texto. Misma causa que IN-17 | `remoto_diagnostico` · BUG ES-07 (`Expected: non-empty`, `Actual: ''`); `integracion_diagnostico` · BUG ES-07 | **Prueba** (backend real y cadena local). **Inferido:** que ocurra en uso normal; depende de la vigencia del JWT | B | app | **corregido** (2026-11-06) con IN-17: las secciones muestran `Código: 401 - Tu sesión no está activa…`. Pruebas en `integracion/estadisticas_integracion_test.dart` y `VmEstadisticasAsistenciaTest.pruebaSesionVencida` |

### Hipótesis sin verificar (no son hallazgos)

| Hip. | Capa | Hipótesis | Por qué no es hallazgo |
|---|---|---|---|
| H-ES-01 | Backend / cliente | Una clase con novedad `NO_REALIZADA` sigue sumando horas. Observado: siguió en 2 clases y 240 min. `contarFaltasPorGrupo` sí excluye esas fechas, así que el backend no las trata igual en todas partes | Falta la regla. Petición directa, sin prueba |
| H-ES-02 | Backend / cliente | Un grupo eliminado sigue apareciendo con sus horas. Observado: conservó 2 clases y 180 min, porque la consulta no filtra `meta_eliminado` del grupo | Puede ser histórico a propósito. Petición directa, sin prueba |
| H-ES-03 | App | El Excel hereda ES-06: escribe `horas` y `minutos` tal como llegan | Solo lectura de `excel.dart` |
| H-ES-04 | App / cliente | `/estadisticas/alumnos` e `/estadisticas/instructores` no tienen pantalla | Falta saber si el cliente las quiere en la app móvil |

**Para el módulo de clases:** `DELETE /clase` ahora responde con `eliminado: 1` y las estadísticas bajaron de 3 a 2 clases. CL-01 parece corregido; se confirma al revisar ese módulo.

---

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
| GR-06 | Backend | **La lista de alumnos del grupo incluye a un alumno desvinculado.** Después de inscribir a A y B y desvincular a B, `/alumnosGrupo` devuelve los dos, con `eliminadoestado: 0`, aunque `validarInscripcion` dice que B **no** está inscrito (`false`). Esa lista es la que ve la pantalla del grupo y la de la toma de asistencia | `remoto_diagnostico` · GR-06 (`Expected: [A]`, `Actual: [A, B]`); confirmado a mano con `/alumnosGrupo` y `/validarInscripcion` | **Prueba contra el backend real.** **Inferido:** que se le pueda tomar asistencia a un alumno retirado y que cuente en estadísticas; tiene relación con AS-11 | M | backend | **corregido por el backend** (revisado 2026-11-05): `/alumnosGrupo` ya no incluye al desvinculado. La prueba quedó en verde sin tocar la app y pasó a la suite remota (`VmGrupoDiagnosticoTest.prueba8AlumnoDesvinculado`) |
| GR-03 | Conexión | `/gruposCurso` concatena categoría y curso en la URL sin codificar. Con `Fútbol & Voleibol` el backend recibe `prmCategoria=Fútbol ` y la lista del curso sale **vacía** aunque el grupo existe | `integracion_diagnostico` · GR-03 (`Actual: 'Fútbol '`); `remoto_diagnostico` · GR-03 (categoría y curso con `&` creados en la corrida → `Actual: []`) | **Prueba** sin backend y contra el backend real | M | app | **corregido** (2026-11-06): `/gruposCurso`, `/gruposInstructor` y las demás consultas del módulo mandan sus datos en `queryParameters`, que Dio codifica. Pruebas: `integracion/gruposErrores_integracion_test.dart` y, contra el backend real, `VmGrupoDiagnosticoTest.prueba9GruposConAmpersand` |
| GR-05 | Conexiones de la pantalla del grupo | En un grupo cuya categoría o curso llevan `&`, la pantalla del grupo no ve **nada**: el curso da `404 GC-0003` y las clases y los alumnos salen vacíos y **sin error**, aunque el grupo tiene 1 clase y 1 alumno inscrito. `/curso`, `/clasesGrupo`, `/alumnosGrupo` y `/horarios` concatenan la llave igual que GR-03 | `remoto_diagnostico` · GR-05 (`curso: null (Código: 404 …); clases: 0; alumnos: 0`) | **Prueba contra el backend real.** Que el vacío no muestre error se debe a que el backend responde `GC-0002` y la app lo toma por lista vacía | M | app | **corregido** (2026-11-06): además de grupos, clases y horarios, `/curso` y `/alumnosGrupo` mandan la llave en `queryParameters`. Contra el backend real, `VmGrupoDiagnosticoTest.prueba10PantallaConAmpersand` pasa a verde; pruebas sin backend en `integracion/clasesErrores_integracion_test.dart` y `horariosErrores_integracion_test.dart`. Quedan sin codificar, fuera del módulo, `/categoria`, `/cursosbycategoria`, `/login` y `/estadisticas/*` |
| GR-02 | Repositorio / modelo | Al crear un grupo se pierde `fechaFinalizacion`: `GrupoModelo.fromEntidad` no la copia y `toJson` no la envía, aunque `GrupoDto` la acepta (antes IN-06, sin prueba) | `repositorio_diagnostico` · GR-02 (`Actual: <null>`); `integracion_diagnostico` · GR-02 (el JSON del `POST /grupo` no la lleva) | **Prueba.** El formulario actual no pide esa fecha, así que hoy solo se pierde si otra pantalla la pone | B | app | **corregido** (2026-11-04): `GrupoMapper.aModelo` copia todos los campos y `GrupoModelo.toJson` envía `fechaFinalizacion` cuando la hay (opcional en `GrupoDto`; sin fecha el POST no cambia). Las pruebas pasaron a `test/unitarias/repositorio/grupoRepositorio_test.dart` y `test/integracion/grupos_integracion_test.dart`. Verificado contra el backend real: `vmGrupoDiagnosticoTest.prueba7FechaFinalizacion` (suite remota) crea el grupo con 201 y la fecha vuelve en `/gruposCurso` |
| GR-04 | Conexión | Las listas por curso e instructor solo capturan `Exception`: un grupo sin `cupos` hace que `GrupoModelo.fromJson` lance `type 'Null' is not a subtype of type 'int'`, que atraviesa la conexión y el repositorio. `/gruposNoEliminados` sí lo captura | `integracion_diagnostico` · GR-04 (`lanzo: type 'Null' is not a subtype of type 'int'`) | **Prueba.** El JSON incompleto lo fabrica la prueba: los 55 grupos reales tienen todos sus campos obligatorios | B | app | **corregido** (2026-11-06): la conexión captura todo (no solo `Exception`) y devuelve el error; el `TypeError` de `fromJson` ya no atraviesa las capas. Prueba en `integracion/gruposErrores_integracion_test.dart` |
| GR-01 | Repositorio | `Gruporepositorio` no tiene `try` en las listas: un `TypeError` de la conexión lo atraviesa (por curso, por instructor y disponibles) | `repositorio_diagnostico` · GR-01 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; GR-04 demuestra que la conexión real lo deja pasar | B | app | **corregido** (2026-11-06): las cuatro listas de `Gruporepositorio` capturan cualquier error y lo devuelven con `fromObjectError`. Prueba en `unitarias/repositorio/grupoRepositorioErrores_test.dart` |
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
| CU-02 | Conexión | `/cursosbycategoria` y `/curso` concatenan los títulos en la URL sin codificar. Con `Fútbol & Voleibol` el backend recibe `prmCategoria=Fútbol `, y con `Nivel 1 + 2` recibe `Nivel 1   2`. Contra el backend real, una categoría con `&` y su curso `curso & co …` dan **lista vacía** y **404 GC-0003** | `integracion_diagnostico` · CU-02 (`Actual: ['Fútbol ', 'Fútbol ', 'Nivel 1   2']`); `remoto_diagnostico` · CU-02 (`lista: []; obtener: 404`) | **Prueba** sin backend y contra el backend real. Es la misma causa que GR-05, pero en la conexión de cursos | M | app | **corregido** (2026-11-06): `/cursosbycategoria` y `/curso` mandan sus datos en `queryParameters`, así que `&` y `+` en los títulos no los cortan. Pruebas: `integracion/cursosErrores_integracion_test.dart` y, contra el backend real, `VmCursoDiagnosticoTest.prueba6CursosConAmpersand` |
| CU-05 | VM | Un error al listar cursos abre **dos** diálogos seguidos: "Sin datos" con el error real y después "datos inconsistentes" (código 406), porque `listarCursosDe` no sale del método tras el primer error | `integracion_diagnostico` · CU-05 (`Found 2 widgets with type "DialogError"`; títulos `[Sin datos, datos inconsistentes]`) | **Prueba** (`testWidgets` con la cadena real y un 500) | B | app | **corregido** (2026-11-04): `listarCursosDe` ya no recibe `context` ni abre diálogos; ante un error deja la lista vacía y devuelve un solo `Fallo` con el código, y `CursosView` abre un único `DialogError`. La prueba se reescribió sobre la ruta real (`AppRutas.cursos`) y pasó a `test/integracion/cursos_integracion_test.dart` |
| CU-03 | Conexión → VM | `agregarCurso` sin `imagenFile` lanza `Null check operator used on a null value` (por `curso.imagenFile!`), que atraviesa conexión, repositorio, servicio y VM: el VM no tiene `try` en `agregarCurso` | `integracion_diagnostico` · CU-03 (`lanzo: Null check operator used on a null value`) | **Prueba.** El formulario de alta exige imagen, así que hoy solo se llega llamando al VM sin archivo, por ejemplo desde un futuro modo edición. Es la versión de cursos de CAT-01 | B | app | **corregido** (2026-11-05): `agregarCurso` envuelve la llamada en `try` y devuelve la excepción como `RespuestaModelo.fromObjectError`, sin lanzar; el formulario pasa por `guardarCurso`, que exige imagen antes de enviar. La prueba pasó a `test/integracion/cursos_integracion_test.dart`. La conexión sigue haciendo `imagenFile!` (igual que CAT-01) |
| CU-04 | Conexión | Un curso sin `deporte` hace que `CursoModelo.fromJson` lance `type 'Null' is not a subtype of type 'String'`, que atraviesa la conexión y el repositorio, al listar y al obtener | `integracion_diagnostico` · CU-04 | **Prueba.** El JSON incompleto lo fabrica la prueba | B | app | **corregido** (2026-11-06): la conexión de cursos captura todo (no solo `Exception`) y devuelve el error con código al listar y al obtener. Prueba en `integracion/cursosErrores_integracion_test.dart` |
| CU-01 | Repositorio | `CursoRepositorio` no tiene ningún `try`: un `TypeError` de la conexión lo atraviesa al listar, obtener y guardar | `repositorio_diagnostico` · CU-01 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; CU-03 y CU-04 demuestran que la conexión real los deja pasar | B | app | **corregido** (2026-11-06): `listarCursosDe`, `obtenerCurso` y `guardaCurso` del repositorio capturan cualquier error y lo devuelven con `fromObjectError`. Prueba en `unitarias/repositorio/cursoRepositorioErrores_test.dart` |
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
| CAT-03 | Conexión | **Una categoría con `&` en el título no se puede editar ni eliminar.** `PUT` y `DELETE` concatenan `?titulo=` sin codificar: el backend recibe `titulo=prueba_… Fútbol ` y responde 404 `GC-0003` ("La categoria con el titulo prueba_… Fútbol  no existe") | `integracion_diagnostico` · CAT-03 (`Actual: ['Fútbol ', 'Fútbol ']`); `remoto_diagnostico` · CAT-03 (`editar: Fallo 404 …; eliminar: Fallo 404 …`) | **Prueba** sin backend y contra el backend real. Es la misma causa que GR-03, GR-05 y CU-02 | M | app | **corregido** (2026-11-06): `PUT` y `DELETE /categoria` mandan `titulo` en `queryParameters`. Pruebas: `integracion/categoriasErrores_integracion_test.dart` y, contra el backend real, `VmCategoriaDiagnosticoTest.prueba4TituloConAmpersand` |
| CAT-09 | VM | Dos cargas solapadas de la lista: si la respuesta de la primera llega después de la de la segunda, **pisa** la lista nueva (no hay contador de peticiones, a diferencia de `EstadisticasViewModel`) | `integracion_diagnostico` · CAT-09 (se esperaba `['Nueva']` y queda la lista vieja) | **Prueba.** **Inferido:** que el solape ocurra en uso real, por ejemplo la carga inicial todavía en camino cuando el formulario vuelve y la recarga | B | app | **corregido** (2026-11-06): `listarYNotificarCategorias` numera cada carga y descarta la respuesta que llega después de una más nueva. Prueba en `integracion/categoriasErrores_integracion_test.dart` |
| CAT-04 | VM | `CategoriaViewModel` no usa `NotificacionSegura`: una carga que termina después de `dispose` lanza `A CategoriaViewModel was used after being disposed` | `integracion_diagnostico` · CAT-04 (`FlutterError`) | **Prueba.** Esa aserción de Flutter solo salta en modo debug | B | app | **corregido** (2026-11-06): `CategoriaViewModel` usa `NotificacionSegura`, así que una carga que llega tras `dispose` no notifica. Prueba en `integracion/categoriasErrores_integracion_test.dart` |
| CAT-05 | VM | `cargarCategorias(context)` muestra un error 500 en el `DialogError` **con código 204** (todos los errores llevan 204) | `integracion_diagnostico` · CAT-05 (`Expected: <500>`, `Actual: <204>`) | **Prueba** (`testWidgets`). Solo lo usa `InscripcionesGeneralesView` | B | app | **corregido** (2026-11-04): se eliminó `cargarCategorias(context)`; la pantalla carga con `listarYNotificarCategorias()`, que ahora devuelve `Resultado`, y abre el `DialogError` con el código del `Fallo`. Una lista vacía (204) ya no se muestra como error. La prueba se reescribió sobre la ruta real (`AppRutas.InscripcionesGenerales`) y pasó a `test/unitarias/vista/inscripcionesCoordinador_test.dart` |
| CAT-01 | Conexión → VM | Insertar con `idImagen` y sin archivo devuelve `Fallo(-1, "Null check operator used on a null value", origen: ViewModel)`: la conexión hace `datos.imagenFile!` y la excepción atraviesa conexión, repositorio y servicio | `integracion_diagnostico` · CAT-01 | **Prueba** con la cadena real. El formulario no llega a este camino (al crear exige imagen nueva) | B | app | **corregido** (2026-11-06): `guardarCategoria` de la conexión usa el `imagenId` que ya viene cuando no hay archivo y solo sube la imagen si hay `imagenFile`; ya no hace `imagenFile!`. Prueba en `integracion/categoriasErrores_integracion_test.dart` |
| CAT-14 | Repositorio | `insertarCategoria` acepta `idImagen` como imagen suficiente (no corta con 400), pero arma el modelo **sin** `imagenId`, así que la imagen existente se pierde. Es la otra mitad de CAT-01 | `repositorio_diagnostico` · CAT-14 (`Expected: <9>`, `Actual: <null>`) | **Prueba** | B | app | **corregido** (2026-11-04): el repositorio arma el modelo con `CategoriaMapper.aModelo`, que lleva el `imagenId` (si hay archivo, la conexión lo reemplaza por el de la imagen subida). La prueba pasó a `test/unitarias/repositorio/categoriaRepositorio_test.dart`. CAT-01 sigue abierto: la conexión real aún hace `imagenFile!` |
| CAT-02 | Conexión | Un `POST /categoria` con 201 **sin cuerpo** termina en `Fallo(-1, "NoSuchMethodError: The method '[]' was called on null")`, aunque se guardó: `categoriaModelo.fromJson(null)` | `integracion_diagnostico` · CAT-02 | **Prueba.** Hoy el backend responde con cuerpo, así que no se ve en uso real | B | app | **corregido** (2026-11-06): la conexión acepta un 201 sin cuerpo (datos nulos) y el VM trata 201 y 204 como éxito al crear y al actualizar. Prueba en `integracion/categoriasErrores_integracion_test.dart` |
| CAT-06 | Conexión | Una categoría con `titulo: null` en `/categorias2` hace que la pantalla muestre `type 'Null' is not a subtype of type 'String'` en lugar de un error con código: `fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio lo capturan | `integracion_diagnostico` · CAT-06 | **Prueba.** El JSON incompleto lo fabrica la prueba | B | app | **corregido** (2026-11-06): la conexión de categorías captura todo (no solo `Exception`) y devuelve el error con código. Prueba en `integracion/categoriasErrores_integracion_test.dart` |
| CAT-13 | Repositorio | `CategoriaRepositorio` no tiene ningún `try`: un `TypeError` de la conexión lo atraviesa al listar, guardar, actualizar y eliminar | `repositorio_diagnostico` · CAT-13 (`Instance of 'TypeError'`) | **Prueba.** CAT-01, CAT-02 y CAT-06 demuestran que la conexión real los deja pasar | B | app | **corregido** (2026-11-06): los cuatro métodos del repositorio de categorías capturan cualquier error y lo devuelven con `fromObjectError`. Prueba en `unitarias/repositorio/categoriaRepositorioErrores_test.dart` |

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
| CAT-07 | Modelo | `ErrorModelo.mensaje` recibe `response.data` (puede ser un `Map`) en `fromResponse` ante un 2xx inesperado | No se escribió una prueba aparte. **Corregido** (2026-11-05) con BK-08: `fromResponse` ya no pone un `Map` como mensaje |
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
| CL-01 | Backend | **Eliminar una clase no la quita.** `DELETE /clase?id=` responde 200, el VM muestra éxito y recarga, pero la clase sigue en la pantalla del grupo con `eliminado: 0` | `remoto_diagnostico` · CL-01 (`sigue la clase 307 con eliminado 0`) | **Prueba contra el backend real.** Ya se había visto el 2026-10-21; `VmModuloGrupoTest.prueba6EliminarClase200` solo fija el 200 (señal D4). **Inferido:** que se le pueda tomar asistencia a una clase "eliminada" y que sume en estadísticas | M | backend | **corregido por el backend** (revisado 2026-11-05): `DELETE /clase` marca `eliminado: 1` y la clase sale de la lista. La prueba quedó en verde sin tocar la app y pasó a la suite remota (`VmClaseDiagnosticoTest.prueba6EliminarClase`) |
| CL-05 | Conexión | Una clase con `fecha: null` hace que la pantalla del grupo muestre `type 'Null' is not a subtype of type 'String'`: `Clasemodelo.fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio (la llamada está fuera de su `try`) lo capturan | `integracion_diagnostico` · CL-05 | **Prueba.** El JSON incompleto lo fabrica la prueba (las clases reales traen fecha) | B | app | **corregido** (2026-11-06): la conexión de clases captura todo y devuelve el error con código. Prueba en `integracion/clasesErrores_integracion_test.dart` |
| CL-04 | Repositorio / modelo | `agregarClase` con una entidad sin `fecha` o sin `horas` lanza `Null check operator used on a null value` (`Clasemodelo.fromEntidad` hace `fecha!`, `horas!` y `minutos!`; el repositorio solo captura `Exception`. Desde 2026-11-04 ese código está en `ClaseMapper.aModelo`, sin cambios) | `repositorio_diagnostico` · CL-04 | **Prueba.** El formulario valida fecha y horas antes de llamar, así que no se llega desde la pantalla | B | app | **corregido** (2026-11-06): `agregarClase` captura el `TypeError` del mapper y lo devuelve como error, sin llamar a la conexión. Prueba en `unitarias/repositorio/claseRepositorioErrores_test.dart` |
| CL-03 | Repositorio | Un `TypeError` de la conexión atraviesa el repositorio al listar, agregar y eliminar | `repositorio_diagnostico` · CL-03 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; CL-05 demuestra que la conexión real lo deja pasar | B | app | **corregido** (2026-11-06): el repositorio de clases captura cualquier error al listar, agregar y eliminar. Prueba en `unitarias/repositorio/claseRepositorioErrores_test.dart` |

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
| HO-03 | Conexión → VM | Un horario con `dia: null` hace que la tarjeta muestre `type 'Null' is not a subtype of type 'String'` en lugar de un error con código: `fromJson` lanza y ni la conexión, ni el repositorio, ni `listarHorariosGrupo` del VM (los tres solo capturan `Exception`, o dejan la llamada fuera del `try`) lo capturan | `integracion_diagnostico` · HO-03 | **Prueba.** El JSON incompleto lo fabrica la prueba | B | app | **corregido** (2026-11-06): la conexión de horarios captura todo y devuelve el error con código. Prueba en `integracion/horariosErrores_integracion_test.dart` |
| HO-02 | Repositorio | Un `TypeError` de la conexión atraviesa `obtenerHoariosGrupo`: la llamada a la conexión está fuera de su `try` | `repositorio_diagnostico` · HO-02 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; HO-03 demuestra que la conexión real lo deja pasar | B | app | **corregido** (2026-11-06): la llamada a la conexión quedó dentro del `try` del repositorio, que captura cualquier error. Prueba en `unitarias/repositorio/horarioRepositorioErrores_test.dart` |

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
| AL-03 | Conexión → VM | El `404` que documenta el backend para un grupo sin alumnos ("No existen alumnos para el grupo consultado") aparece en la pantalla del grupo como **error** (`Código: 404 - …`) en lugar de lista vacía. Solo el objeto `GC-0002` se trata como vacío | `integracion_diagnostico` · AL-03 | **Prueba** con la respuesta documentada en `/v3/api-docs`. Hoy el backend responde `GC-0002` en los 70 grupos vacíos, así que no se ve en uso real | B | app + backend (contrato y comportamiento no coinciden) | **confirmado** (latente); **corregido** (2026-11-19): `Conexionalumnosremoto` convierte el 404 en `200 []`. Prueba en `integracion/alumnos_integracion_test.dart` |
| AL-01 | Modelo | `Alumnomodelo.fromJson` no lee `codigo` ni `imagen`: aunque el JSON los traiga, la pantalla del grupo recibe `[null, null]`. Es la causa de AS-05 vista desde la lista | `integracion_diagnostico` · AL-01 (`Actual: [null, null]`) | **Prueba.** Hoy el backend los manda a `null` en los 112 alumnos, así que no se pierde ningún dato real | B | app | **confirmado** (latente); **corregido** (2026-11-19): `Alumnomodelo.fromJson` lee `codigo` e `imagen`. Prueba en `integracion/alumnos_integracion_test.dart` |
| AL-04 | Conexión | Un alumno con `nombre: null` hace que la pantalla del grupo muestre `type 'Null' is not a subtype of type 'String'`: `fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio (llamada fuera del `try`) lo capturan | `integracion_diagnostico` · AL-04 | **Prueba.** El JSON incompleto lo fabrica la prueba; ningún alumno real tiene nulos obligatorios | B | app | **confirmado** (latente); **corregido** (2026-11-19): la conexión captura cualquier error (`fromObjectError`), no solo `Exception`. Prueba en `integracion/alumnos_integracion_test.dart` |
| AL-02 | Repositorio | Un `TypeError` de la conexión atraviesa `listarAlumnosGrupo` | `repositorio_diagnostico` · AL-02 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; AL-04 demuestra que la conexión real lo deja pasar | B | app | **confirmado**; **corregido** (2026-11-19): la llamada a la conexión va dentro del `try` del repositorio. Prueba en `unitarias/repositorio/alumnoRepositorio_test.dart` |

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
| I-Local (diagnóstico) | `test/diagnostico/instructores/integracion_diagnostico_test.dart` y `test/diagnostico/facultades/integracion_diagnostico_test.dart` | — | 5 (IT-01, IT-02, FA-01, FA-03, FA-04; FA-04 corregido y movido a la suite de integración el 2026-11-05) |
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
| IT-03 | Vista | La pantalla "Instructores" del menú del coordinador muestra **20 instructores inventados** ("Instructor 0" a "Instructor 19", todos "Activo"). No pide nada al backend: el instructor real no aparece. Es una maqueta, y a diferencia de `AlumnosView` (AL-V1) **sí se llega** a ella | `vista_diagnostico` · IT-03 (`Found 1 widget with text "Instructor 0"`); su control (la ruta abre la pantalla) está en verde | **Prueba** con la ruta real y la sesión del coordinador | M | app | **corregido** (2026-11-19): la ruta crea `InstructoresViewModel` y pide la lista; la pantalla pinta carga, error con «Reintentar», lista vacía o los instructores reales. Se quitaron el filtro de categoría y el botón «AGREGAR INSTRUCTOR», que no hacían nada. Prueba en `unitarias/vista/instructoresView_test.dart` |
| IT-01 | Conexión → VM | El `404` que documenta el backend cuando no hay instructores aparece en el formulario de grupo como `Código: 404 - {"codigoError":"GC-0003","mensaje":"No existen instructores registrados"}`, con el JSON crudo, en lugar de lista vacía | `integracion_diagnostico` · IT-01 | **Prueba** con la respuesta documentada en `/v3/api-docs`. Hoy hay un instructor y no se puede vaciar la lista por la API | B | app + backend (contrato y comportamiento por confirmar) | **confirmado** (latente); **corregido** (2026-11-19): `Conexioninstructoresremoto` convierte el 404 en `200 []`. Prueba en `integracion/instructores_integracion_test.dart` |
| FA-03 | Conexión → VM | Lo mismo en el registro con el `404` documentado de "No existen facultades registradas": `Código: 404 - {"codigoError":…}` | `integracion_diagnostico` · FA-03 | **Prueba** con la respuesta documentada. Hoy hay una facultad | B | app + backend | **confirmado** (latente); **corregido** (2026-11-19): `Conexionfacultadremoto` convierte el 404 de `/facultades` en `200 []`. Prueba en `integracion/facultades_integracion_test.dart` |
| FA-01 | Conexión | Una facultad con `nombre: null` hace que el registro muestre `type 'Null' is not a subtype of type 'String'`: `fromJson` lanza y ni la conexión (solo captura `Exception`) ni el repositorio (sin `try`) lo capturan. La conexión de instructores sí captura todo (H-04 descartada) | `integracion_diagnostico` · FA-01 | **Prueba.** El JSON incompleto lo fabrica la prueba; la facultad real no tiene nulos | B | app | **confirmado** (latente); **corregido** (2026-11-19): la conexión captura cualquier error en `/facultades` y `/programas`. Prueba en `integracion/facultades_integracion_test.dart` |
| FA-02 | Repositorio | Un `TypeError` de la conexión atraviesa `listarFacultades` | `repositorio_diagnostico` · FA-02 (`Instance of 'TypeError'`) | **Prueba.** El error lo lanza el doble; FA-01 demuestra que la conexión real lo deja pasar | B | app | **confirmado**; **corregido** (2026-11-19): `listarFacultades` tiene `try`. Prueba en `unitarias/repositorio/facultadesRepositorio_test.dart` |
| IT-02 | VM | `InstructoresViewModel` no usa `NotificacionSegura`: si se sale del formulario de grupo antes de que llegue la lista, lanza `A InstructoresViewModel was used after being disposed` | `integracion_diagnostico` · IT-02 (`FlutterError`) | **Prueba.** Esa aserción de Flutter solo salta en modo debug. Mismo caso que CAT-04 | B | app | **corregido** (2026-11-19): `InstructoresViewModel` usa `NotificacionSegura`. Prueba en `integracion/instructores_integracion_test.dart` |
| FA-04 | VM | Lo mismo con `Facultadesviewmodel` al salir del registro: `A Facultadesviewmodel was used after being disposed` | `integracion_diagnostico` · FA-04 (`FlutterError`) | **Prueba.** Solo en modo debug | B | app | **corregido** (2026-11-05): `Facultadesviewmodel` usa `NotificacionSegura` (lo pedía la carga de programas del registro). La prueba pasó a `test/integracion/facultades_integracion_test.dart` |

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
| 18 | I-Local | Facultades: respuesta después de `dispose` → no lanza | ❌ FA-04 (✅ desde 2026-11-05) |
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
| HO-04 | Vista | "AGREGAR HORARIO", en la pantalla del grupo, no abre nada (`onPressed: () {}` en `widgetListaHorarios.dart`): no hay formulario, ruta ni método en ninguna capa para crear un horario, aunque el backend ya lo permite | `vista_diagnostico` · HO-04 (`Expected: a value greater than <0>`, `Actual: <0>` pantallas abiertas); su control (pinta los horarios y el botón) está en verde | **Prueba** con la pantalla y su VM reales. **Leído en el código:** tampoco hay forma de editar un horario | M | app | **corregido** (2026-11-06): «AGREGAR HORARIO» abre un diálogo (día, hora de inicio y fin, escenario); `DetalleGrupoViewModel.agregarHorario` valida, hace `POST /horario` por interfaz → conexión → repositorio → servicio y recarga la sección. No se puede editar (el `PUT` sigue sin uso). Pruebas en `unitarias/vista/horariosGrupoView_test.dart`, `unitarias/viewModel/detalleGrupoViewModel_test.dart` y `unitarias/conexion/conexionHorariosRemoto_test.dart`. No comprobado en el emulador ni contra el backend real |
| HO-05 | Vista | El botón de cerrar de la tarjeta de un horario no elimina ni pide confirmación: `MiniTarjeta.iconoAccion` solo hace `print('hola')` | `vista_diagnostico` · HO-05 (`Actual: <0>`) | **Prueba.** `MiniTarjeta` es compartida: el mismo botón muerto aparece donde se use con `existeBotonCierre: true` | M | app | **corregido** (2026-11-06): la tarjeta recibe `alCerrar`; en horarios pide confirmación, llama a `DELETE /horario?id=` y recarga. `MiniTarjeta` ya no imprime «hola»: donde no se le da `alCerrar` el botón queda inactivo (alumnos e instructores siguen sin función). Mismas pruebas que HO-04 |

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

## Módulo 10: diagnóstico por pruebas de la autenticación (2026-11-05)

Plan: [plan-diagnostico-autenticacion.md](plan-diagnostico-autenticacion.md). **Regla:** solo es hallazgo lo que demuestra una prueba **en rojo**. Lo demás va a hipótesis.

**Cambio del backend (2026-11-05):** el backend que corre en `localhost:8082` responde `401` (`WWW-Authenticate: Bearer`, cuerpo vacío) a **toda** ruta sin JWT: `/login`, `/categorias2`, etc. Solo `/v3/api-docs` sigue abierto. `/v3/api-docs` publica `POST /auth/token`, que cambia un Google ID Token por un JWT propio. El repositorio del backend en disco (`BackDeporteParaTodos`, `main`, `fecf216`) **no** tiene esa seguridad, así que el backend en marcha sale de otro código. Por eso no se pudo hacer la parte I-Remota, y los fixtures de `test/contratos/autenticacion/` son los documentados, no observados.

| Nivel | Archivo | Verdes | Rojas |
|---|---|---|---|
| U-Conexión: conexión real → transporte falso | `test/unitarias/conexion/conexionAutenticacionRemoto_test.dart` (nuevo) | 5 | — |
| U-Conexión (diagnóstico) | `test/diagnostico/autenticacion/conexion_diagnostico_test.dart` | — | 5 (AU-01 ×2, AU-02, AU-03 ×2; AU-02 corregido y movido a la suite unitaria el 2026-11-05) |
| U-VM (diagnóstico) | `test/diagnostico/autenticacion/viewModel_diagnostico_test.dart` | — | 1 (AU-04) |
| U-Vista: `CategoriasView` | `test/unitarias/vista/categoriasView_test.dart` (+1) | 1 | — |
| I-Local: menú lateral y rutas reales → cadena real → transporte falso (montaje `test/integracion/montajeAutenticacion.dart`) | `test/integracion/autenticacion_integracion_test.dart` (nuevo) | 5 | — |
| I-Local (diagnóstico) | `test/diagnostico/autenticacion/vista_diagnostico_test.dart` (borrado el 2026-11-19: todo pasó a la suite de integración) | 1 (control AU-10) | 8 (AU-05 a AU-09, AU-10 ×3; AU-07 corregido y movido a la suite de integración el 2026-11-05) |
| I-Remota | `test/remoto/viewModel/autenticacion/vmLoginTest.dart` (ya existía) | — | 1 (AU-B01) |

Resultado:
- Suite sin backend: **308 en verde** (antes 297).
- Suite remota: **no se pudo correr**. El backend responde `401` a todo; `VmLoginTest.prueba1` da `Expected: <404>`, `Actual: <401>`.
- `test/diagnostico`: 81 pruebas, de ellas 76 rojas, 4 verdes (controles) y 1 omitida; 14 de las rojas son de este módulo.
- `flutter analyze`: 0 errores y 30 warnings (sin cambios).

### Hallazgos (prueba en rojo)

| ID | Capa | Síntoma observable (evidencia del rojo) | Prueba que lo demuestra | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| AU-B01 | Backend ↔ app | Por la cadena real de la app, `GET /login` responde **401** en lugar de 404 o 200: el backend exige un JWT (`Authorization: Bearer`) y la app no envía ninguno. Con curl, `/categorias2` y `/instructores` dan lo mismo. **Con este backend nadie puede iniciar sesión ni cargar ninguna pantalla** | `main_test` · `VmLoginTest` prueba1 (`Expected: <404>`, `Actual: <401>`) | **API del backend** (2026-11-05). **Por confirmar:** si es el backend que se va a desplegar o una rama en desarrollo; el repositorio en disco no tiene esta seguridad | A | app | **corregido en la app el 2026-11-05, sin verificar contra el backend real**: `GoogleSignIn` pide el ID Token con el client ID web (`ConfigApi.googleServerClientId`), `login()` lo cambia en `/auth/token` y `InterceptorToken` envía el JWT en cada petición (pruebas en `unitarias/conexion/interceptorToken_test.dart`, `conexionAutenticacionRemoto_test.dart` y `integracion/autenticacion_integracion_test.dart`). Falta probarlo en el emulador con una cuenta real. El inicio solo con correo sigue usando `GET /login` y recibe 401 (AU-08). Antes: confirmado contra el backend. Desde el 2026-11-05 se trabaja con este backend (`E:/2026-1/Practica/BackDeporteParaTodos (Nuevo)`, `main` `151a38d`). Revisión del flujo: `POST /auth/token` recibe el Google ID Token en `Authorization: Bearer`, lo valida con las claves públicas de Google y devuelve `{token, perfil}` (404 si el correo no está registrado). Ese token va como Bearer en el resto de rutas; el rol viaja en el claim `rol`. Solo son públicos `POST /RegistroPerfilAlumno`, `GET /facultades` y `GET /programas`. **La app hoy no puede obtener un ID Token:** `GoogleSignIn` no tiene `serverClientId` ni hay `default_web_client_id` (sin `google-services.json`), y en Android el plugin solo pide el ID Token con uno de los dos |
| AU-09 | Vista / navegación | Al cerrar sesión, el menú hace `pushNamed(categorias)` **encima** de lo que había: la pantalla de inscripciones del coordinador sigue en la pila y "atrás" vuelve a ella sin sesión | `vista_diagnostico` · AU-09 (`Found 1 widget with text "configuracion general"` fuera de pantalla, con `perfilSesion` ya en `null`) | **Prueba** con el menú y las rutas reales. **Inferido:** las acciones de esa pantalla siguen disponibles; las rutas no miran el rol (AU-10) | M | app | **corregido** (2026-11-19): al cerrar sesión el menú abre categorías con `pushNamedAndRemoveUntil` y deja la pila vacía debajo. Prueba en `integracion/autenticacion_integracion_test.dart` |
| AU-06 | Vista | Un `409` del registro ("El perfil ya existe") **cierra el formulario** con `pop(false)`. El menú cierra la sesión y muestra "Ha fallado el registro, intenta nuevamente": no dice el motivo y el alumno pierde lo que llenó. Lo mismo pasa con cualquier respuesta distinta de 201 | `vista_diagnostico` · AU-06 (`Expected: [1, true]`, `Actual: [0, false]`) | **Prueba** con el 409 documentado | M | app | **confirmado**; **corregido** (2026-11-19): el formulario ya se quedaba abierto, pero el motivo iba en un SnackBar que se va a los 4 s y, sin `mensaje` legible, decía «Ya existe un perfil…» genérico. Ahora `mensajeErrorRegistro` devuelve el `mensaje` del backend con cualquier código y la pantalla lo deja escrito sobre los botones hasta el siguiente intento. Prueba en `integracion/autenticacion_integracion_test.dart` |
| AU-05 | Vista | En el registro por correo, al escribir el nombre y elegir después cualquier desplegable, el campo "Nombre completo" **desaparece** y queda un texto fijo: ya no se puede corregir. `onChanged` guarda `_nombre` sin `setState`, y el siguiente `setState` decide que el nombre "vino de Google" | `vista_diagnostico` · AU-05 (`Found 0 widgets with type "TextFormField"`) | **Prueba.** Con Google el nombre ya llega y el campo no se muestra, así que solo afecta al registro por correo | M | app | **confirmado**; **corregido** (2026-11-19): si el nombre llegó con la sesión se decide una sola vez al abrir (`_nombreDeSesion`); lo escrito a mano ya no cambia el campo por un texto. Prueba en `integracion/autenticacion_integracion_test.dart` |
| AU-08 | Vista | Un login fallido que no sea 404 muestra `Error: <código>`. Con el backend de hoy, todo login muestra **"Error: 401"** | `vista_diagnostico` · AU-08 (`Found 1 widget with text "Error: 401"`) | **Prueba** con el `401` sin cuerpo que responde hoy el backend (AU-B01) | B | app | **confirmado**; **corregido** (2026-11-19): el menú muestra `AutenticacionViewModel.mensajeErrorLogin`; un 401 sin cuenta de Google dice que el servidor ya no permite entrar solo con el correo y sugiere «Continuar con Google» (la opción sigue, BK-11). Prueba en `integracion/autenticacion_integracion_test.dart` |
| AU-10 | Rutas | Las rutas del coordinador no comprueban el rol: con sesión de alumno, de instructor o sin sesión, `AppRutas.InscripcionesGenerales` abre la pantalla. Solo el menú lateral esconde la opción. Es el mismo caso que AS-01 en la ruta `clase` | `vista_diagnostico` · AU-10 ×3; su control (el coordinador la abre) está en verde | **Prueba** que abre la ruta **directamente**: demuestra lo que hace la ruta, no que se pueda llegar a ella. No hay un camino conocido en la interfaz | B | app | **confirmado**; **corregido** (2026-11-19): `config/routes/accesoRutas.dart` dice qué rol abre cada ruta, siguiendo lo que la interfaz ya ofrece a cada uno; `generateRoute` envuelve esas rutas en `RutaProtegida`, que sin el rol muestra «Acceso restringido» y no crea el vm de la pantalla (no sale ninguna petición). Pruebas en `integracion/autenticacion_integracion_test.dart` y `unitarias/rutas/accesoRutas_test.dart` |
| AU-07 | Vista | GUARDAR no se deshabilita mientras se envía el registro: dos toques mandan **dos** `POST /RegistroPerfilAlumno` | `vista_diagnostico` · AU-07 (`Expected: <1>`, `Actual: <2>`) | **Prueba** con el transporte retenido. **Inferido:** el backend respondería 409 al segundo | B | app | **corregido** (2026-11-05): GUARDAR queda deshabilitado mientras se envía el registro. La prueba pasó a `test/integracion/autenticacion_integracion_test.dart` |
| AU-04 | VM | Si `signOut` de Google lanza (p. ej. un `PlatformException`), `logout` deja escapar la excepción hasta el menú y **no borra la sesión** | `viewModel_diagnostico` · AU-04 (`PlatformException(sign_out_failed)`) | **Prueba.** El fallo lo lanza el doble; no se ha visto en el emulador | B | app | **corregido** (2026-11-19): `logout` captura el fallo de `signOut` y borra la sesión local igual. Prueba en `unitarias/viewModel/autenticacionLogout_test.dart` |
| AU-01 | Conexión | El correo va sin codificar en `/login?email=$email`: `ana+deporte@…` llega como `ana deporte@…` y `ana&b@…` parte la query en `email=ana`. Mismo caso que GR-05 | `conexion_diagnostico` · AU-01 ×2 | **Prueba.** **Inferido:** ese usuario recibiría 404 y se le pediría registrarse. Los correos institucionales no suelen llevar `+` ni `&` | B | app | **confirmado** (latente) |
| AU-02 | Modelo | `Perfilmodelo.fromJson` no lee `facultad`: la sesión nunca la conoce | `conexion_diagnostico` · AU-02 (`Actual: <null>`) | **Prueba** con el `PerfilDto` documentado. Hoy nada lee `perfilSesion.facultad` | B | app | **corregido** (2026-11-05): `Perfilmodelo.fromJson` lee `facultad`, `programa`, `alumnoCodigo` y `dependencia`. La prueba pasó a `test/unitarias/conexion/conexionAutenticacionRemoto_test.dart` |
| AU-03 | Conexión | Un perfil con un campo obligatorio nulo, o un 201 sin cuerpo, lanza `TypeError` o `NoSuchMethodError` desde `fromJson`. La conexión solo captura `Exception`, así que el error atraviesa todas las capas hasta el `onTap` del menú. Mismo caso que AL-04 | `conexion_diagnostico` · AU-03 ×2 | **Prueba.** El JSON incompleto lo fabrica la prueba | B | app | **confirmado** (latente) |

### Hipótesis descartadas (su prueba salió verde)

| Hip. | Qué se temía | Prueba en verde |
|---|---|---|
| CAT-12 / T-04 | `perfilSesion` cambia sin notificar y la opción del coordinador no aparece al iniciar sesión | `categoriasView_test` · "iniciar sesion de coordinador muestra agregar sin recargar" e `autenticacion_integracion_test` · "Login - 200 …": `login()` notifica, y el menú y la pantalla cambian solos. El `notifyListeners()` a mano del caso viejo (T-04) ya no hace falta, pero se conserva |

### Hipótesis sin verificar u observaciones (no son hallazgos)

| Hip. | Capa | Hipótesis / observación | Por qué no es hallazgo |
|---|---|---|---|
| AU-H1 | Seguridad / cliente | El inicio "con correo" no pide ninguna credencial: quien escriba el correo de un coordinador entra con su rol. Que el backend exija ahora un JWT obtenido con Google (AU-B01) apunta a que el equipo del backend lo quiere cerrar | Es de diseño y lo decide el cliente; posible severidad A |
| AU-H2 | Backend | Si la respuesta 201 del registro no trae `role`, el alumno recién registrado no ve "Inscripciones" en el menú hasta volver a iniciar sesión | `PerfilDto.role` es opcional; no se pudo observar por AU-B01 |
| AU-H3 | Vista / cliente | El registro solo ofrece CC y TI, aunque el backend acepta CE, PP, PEP y DIE (comentario en la vista). Tampoco ofrece "Contratista" como tipo de alumno, que `AlumnoRequest` sí admite | Regla del cliente: ¿pueden registrarse extranjeros o contratistas? |
| AU-H4 | VM | Si el login con Google funciona pero el backend falla (que no sea 404), `cuenta` queda asignada: `verificarSesion` no reintenta al volver a categorías | Solo lectura del código; el usuario puede volver a iniciar sesión desde el menú |
| AU-O1 | Vista | El aviso "Te has registrado exitosamente" espera en cola unos 4 s, detrás de "Valores aceptados", que el registro muestra antes de enviar | Observado en `autenticacion_integracion_test`; es cosmético |
| AU-H5 | Backend (seguridad) | `googleJwtDecoder` (`SecurityConfig`) solo comprueba la firma y la vigencia del ID Token: no valida `aud` (el client ID de la app) ni `iss`. Un ID Token emitido por Google para **cualquier** otra aplicación serviría para obtener un JWT del sistema con el rol de ese correo | Solo lectura del código del backend; no se probó con un token real. Responsable: backend |
| AU-O2 | Modelo | `PerfilDto` trae `alumnoCodigo`, `programa` y `dependencia`, que la app no lee | Nada los usa todavía |

### Escenarios implementados

| # | Nivel | Escenario | Resultado |
|---|---|---|---|
| 1 | U-Conexión | Login 200 → perfil con su rol; el correo va en la query | ✅ |
| 2 | U-Conexión | Login 404 → 404 | ✅ |
| 3 | U-Conexión | Login sin red → 503 sin lanzar | ✅ |
| 4 | U-Conexión | Registro → cuerpo igual al contrato; 201 → perfil | ✅ |
| 5 | U-Conexión | Registro 409 → 409 sin lanzar | ✅ |
| 6 | U-Conexión | Correo con `+` y con `&` llega sin cambios | ❌ AU-01 ×2 |
| 7 | U-Conexión | La facultad del perfil llega al modelo | ❌ AU-02 (✅ desde 2026-11-05) |
| 8 | U-Conexión | Perfil con `tipoId: null` y 201 sin cuerpo → error devuelto, sin lanzar | ❌ AU-03 ×2 |
| 9 | U-VM | `signOut` de Google falla → la sesión se borra igual, sin lanzar | ❌ AU-04 |
| 10 | U-Vista | Iniciar sesión de coordinador por el VM muestra "Agregar categoria" sin notificar a mano | ✅ (CAT-12 descartada) |
| 11 | I-Local | Menú → login 200 → "Email autenticado" y opciones del coordinador | ✅ |
| 12 | I-Local | Menú → login 404 → abre el registro con el correo y pide las facultades | ✅ |
| 13 | I-Local | Registro completo → `POST` igual al contrato → se cierra, avisa y deja la sesión del alumno | ✅ |
| 14 | I-Local | Cancelar el registro → sin sesión ni `POST` | ✅ |
| 15 | I-Local | Cerrar sesión → borra la sesión, sale de Google y abre categorías | ✅ |
| 16 | I-Local | Nombre escrito y luego un desplegable → el nombre sigue editable | ❌ AU-05 |
| 17 | I-Local | Registro 409 → el formulario sigue abierto con el motivo | ❌ AU-06 |
| 18 | I-Local | Dos toques en GUARDAR → un solo `POST` | ❌ AU-07 (✅ desde 2026-11-05) |
| 19 | I-Local | Login 401 → mensaje legible, no `Error: 401` | ❌ AU-08 |
| 20 | I-Local | Cerrar sesión desde una pantalla del coordinador → esa pantalla no queda en la pila | ❌ AU-09 |
| 21 | I-Local | `InscripcionesGenerales` por ruta: el coordinador la abre (control); alumno, instructor y sin sesión no | ✅ control · ❌ AU-10 ×3 |
| 22 | I-Remota | Correo no registrado → 404 | ❌ AU-B01 (`401`) |

## Módulos restantes: revisión contra el backend nuevo (2026-11-05)

Plan y resultado: [plan-diagnostico-backend-nuevo.md](plan-diagnostico-backend-nuevo.md). Inscripciones y estadísticas tienen su propia sección. **Regla:** solo cambia de estado lo que una prueba unitaria o remota demuestra. Lo visto por petición directa se anota como observación.

| Suite | Resultado |
|---|---|
| Sin backend | 351 en verde |
| `test/main_test.dart` (remota) | 105 en verde, 7 en rojo: BK-05 ×2, BK-06, BK-07 ×2, BK-08 y la expectativa vieja de `VmGruposInscripcionTest` · prueba3 |
| `test/diagnostico` | 94 en rojo, 7 en verde (controles y `setUpAll`), 1 omitida |

La autorización por rol quedó comprobada con los JWT de cada rol: alumno, instructor y coordinador leen lo que sus pantallas piden. Alumno recibe 403 en `/clasesGrupo`, `/alumnosGrupo` y `/gruposInstructor`, que el menú no le ofrece. Anónimo recibe 401 en todo salvo facultades, programas y registro.

### Resueltos con el backend nuevo

| ID | Evidencia |
|---|---|
| CL-01 | Prueba remota en verde sin tocar la app |
| GR-06 | Prueba remota en verde sin tocar la app |
| ES-05, IN-13 | Ver sus secciones |
| AS-11 (desvinculados) | La prueba de GR-06 cubre a los desvinculados; los alumnos eliminados siguen sin comprobarse |

### Reabiertos o cambiados

| ID | Cambio |
|---|---|
| AS-B01 | Reabierto como BK-02 |
| AS-04, AS-05 | Se decidieron sobre `/asistenciasClase`, que ya no existe. Hay que revisarlos al reescribir la conexión |
| AU-B01 | Sigue sin verificar: `/auth/token` exige un ID Token firmado por Google. Solo se comprobó que uno inválido da 401 |

### Sin cambio

Estos dependen del código de la app y siguen en rojo:

- **Asistencias:** AS-01 a AS-03, AS-06 a AS-09 y AS-12. AS-07 queda pendiente de la conexión nueva.
- **Clases:** CL-03 a CL-05.
- **Grupos:** GR-01, GR-03 a GR-05.
- **Horarios:** HO-02 a HO-05. HO-04 y HO-05 ya tienen rutas de escritura en el backend.
- **Categorías:** CAT-01 a CAT-04, CAT-06, CAT-09, CAT-13.
- **Cursos:** CU-01, CU-02, CU-04.
- **Alumnos:** AL-01 a AL-04.
- **Instructores y facultades:** IT-01 a IT-03, FA-01 a FA-03.
- **Autenticación:** AU-01, AU-03 a AU-06, AU-08 a AU-10.
- **Transversal:** X-01.

AL-03, IT-01 y FA-03 prueban un 404 de lista vacía. **Observado:** un grupo sin alumnos responde 200 con `GC-0002`, que la app ya trata como vacío, así que AL-03 no se da hoy. Las listas de instructores y facultades no se pueden vaciar por la API.

### Observaciones por petición directa (no son hallazgos)

| ID | Observado el 2026-11-05 | Falta |
|---|---|---|
| H-08 (clases) | Una clase futura ya da 422 `GC-0018` | Prueba propia |
| H-07 (horarios) | Ya existen `POST`, `PUT` y `DELETE /horario`; la falta es de la app (HO-04, HO-05) | Decidir quién carga los horarios |
| H-13 (instructores) | Sigue igual: acepta el día `Xyz` y un horario duplicado | Regla del cliente |
| CAT-16a | Sigue igual, y además los grupos de la categoría eliminada siguen en `/gruposInscripcion` | Regla del cliente |
| CAT-16b | Sigue igual: recrear el título da 409 | Regla del cliente |
| AU-H1 | Sin JWT, `/login` da 401, así que el correo solo ya no abre sesión (BK-11) | Nada, salvo quitar la opción |
| AU-H2 | Descartada en lo observado: el 201 trae `role: Alumno` | — |
| H-RN-01 | El 201 del registro de un docente trae `facultad: null`, aunque se envió | Ver si se guarda |
| H-RN-02 | `PATCH /curso/estado` no se probó: la app no lo usa y no hay forma de reactivar un curso desde ella | Decidir con el cliente |
| H-RN-03 | Facultades y programas siguen con doble codificación (`EconÃ³micas`) | Backend |

---

## Compatibilidad con el backend nuevo (2026-11-05)

Backend en uso: `E:/2026-1/Practica/BackDeporteParaTodos (Nuevo)`. La suite remota volvió a correr firmando sus propios JWT (`test/remoto/jwtPruebas.dart`, coordinador por defecto). Lo que era de siembra se ajustó en `test/remoto/datosPruebas.dart`. Lo demás **no se ajustó**: las pruebas siguen en rojo como evidencia. Las rojas viven en `main_test.dart`, no en `remoto_diagnostico_test.dart`, hasta decidir qué hacer con cada una.

Al revisar estadísticas (2026-11-05) los 4 casos sin correr volvieron a correr, en verde, porque la siembra ya no depende de `/asistenciasClase`.

Resultado al corregir grupos (BK-01 y BK-03, 2026-11-05): **93 en verde, 11 en rojo, 4 sin correr** (su `setUpAll` falla por BK-02). `flutter test test/unitarias test/raiz_composicion_test.dart test/integracion`: 351 en verde.

| ID | Módulo | Síntoma observable | Prueba | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| BK-01 | Grupos | La app llama a `PUT /abrirInscripcionesGrupo` y `/cerrarInscripcionesGrupo`, que ya no existen (404 de Spring, sin `GC-0003`). El coordinador no puede abrir ni cerrar inscripciones. El backend usa `PATCH /grupo/periodo` y `PATCH /grupo/inscripciones?cerradas=` | `VmPeriodoInscripcionTest` ×7 | **API del backend** + `/v3/api-docs` | M | app | **corregido** (2026-11-05): abrir usa `PATCH /grupo/periodo`, cerrar usa `PATCH /grupo/inscripciones?cerradas=true` y, si el grupo estaba cerrado a mano, abrir aplica el periodo y luego lo reabre. El cierre ahora es obligatorio al abrir y al programar; la app lee `inscripcionesCerradasManual`. Comprobado contra el backend real con `VmPeriodoInscripcionTest` (7 en verde), incluido cerrar y reabrir. Falta probarlo en pantalla, en el emulador |
| BK-02 | Asistencias | `/asistenciasClase` ya no existe: la toma de asistencia recibe 404, tanto al listar como al registrar. El backend publica `PUT /clase/{codigo}/asistencia`, `POST /atenciones` y `GET /atencionesporclase` | `transversal/remoto_backend_nuevo` · BUG BK-02 (lista de una clase real, `Actual: 'Código: 404 - …NoResourceFoundException…'`); `estadisticas/remoto_diagnostico` · BUG BK-02 (registro, `Expected: <200>`, `Actual: <404>`). `VmAtencionTest.prueba4ClaseInexistente` sigue en verde por casualidad: su 404 es el de la ruta, no el de la clase | **Prueba contra el backend real** + `/v3/api-docs` | A | app | **corregido** (2026-11-06): la lista sale de `GET /alumnosGrupo` unida con `GET /atencionesporclase?claseid=` (un `GC-0002` es «sin marcas») y se confirma con `PUT /clase/{codigo}/asistencia` `{asistencias:[{idPerfil, estaAtendido}], confirmaTodosAusentes:false}`. Comprobado contra el backend real: leer, marcar, confirmar y releer. Leer una clase inexistente ya no da 404 (lista vacía); el 404 llega al confirmar. Pruebas en `unitarias/conexion/conexionAtencionesRemoto_test.dart` e `integracion/atenciones_integracion_test.dart` |
| BK-03 | Grupos | `POST /grupo` exige `fechaIncripcionCierre` (422 `GC-0015`) y el formulario de grupo no la pide: desde la app no se puede crear un grupo. `GrupoModelo.toJson` ya la envía si existe; falta el campo en el formulario y en `registrarGrupo` | `VmModuloGrupoTest` (rojo antes de sembrar la fecha) | **API del backend** + lectura de `registrarGrupo` | M | app | **corregido** (2026-11-05): el formulario pide el cierre (obligatorio) y la apertura (opcional; sin ella las inscripciones abren al crear el grupo). `registrarGrupo` valida ambas. Probado en `formularioGrupo_integracion_test` sobre el transporte falso; no se creó un grupo real desde el formulario |
| BK-04 | Clases | `POST /claseGrupo` en un día sin horario exige `justificacion` (422 `GC-0021`) y la app no tiene cómo enviarla: el formulario y `registrarClase` no la piden. Con horario, el backend ignora las horas enviadas y las calcula | `transversal/remoto_backend_nuevo` · BUG BK-04 (`NoSuchMethodError`: `registrarClase` no acepta `justificacion`) y su control (422) | **Prueba contra el backend real** + `ClaseServicio` | M | app | **corregido** (2026-11-18, verde contra el backend el 2026-11-19): el formulario carga los horarios del grupo y, si ese dia no hay, pide la justificacion (10 a 500 caracteres, recortada); `registrarClase` acepta `justificacion` y `Clasemodelo` la envia solo si hay. Con horario no se muestra ni se envia. Si los horarios fallan, queda opcional y decide el backend. Pruebas en `integracion/claseJustificacion_integracion_test.dart`; la remota pasó a `VmClaseDiagnosticoTest.prueba8Justificacion` |
| BK-05 | Horarios | Un grupo sin horarios responde `200` con un objeto `GC-0002`, no `[]`: la app muestra `Código: 406 - se esperaba una lista` en lugar de una lista vacía. Clases y alumnos dan la misma forma, pero su conexión o su VM ya la tratan como lista vacía | `transversal/remoto_backend_nuevo` · BUG BK-05; `VmModuloGrupoTest` · prueba3, `VmHorarioDiagnosticoTest` · prueba1 | **Prueba contra el backend real** | M | app | **corregido** (2026-11-06): la conexión de horarios convierte el objeto `GC-0002` en `200 []`. Contra el backend real pasan `VmModuloGrupoTest` prueba3 y `VmHorarioDiagnosticoTest` prueba1 |
| BK-06 | Inscripciones | Un grupo sin cupos ya no da 409: responde 201 con `estado: EN_ESPERA`. La conexión descarta el cuerpo y la pantalla dice «Te has inscrito al grupo» aunque el alumno quedó en lista de espera | `inscripciones/vista_diagnostico` · BUG BK-06 (`Found 1 widget with text "Te has inscrito al grupo"`; su control con `INSCRITO` en verde); `remoto_diagnostico` · BUG BK-06 (`Expected: contains 'EN_ESPERA'`, `Actual: 'null'`); `VmInscripcionTest` · prueba4 | **Prueba** (pantalla sobre transporte falso con el cuerpo observado, y backend real) | A | app | **corregido** (2026-11-06): la conexión devuelve el `estado` del 201 y `agregarIncripcion` responde `Exito<bool>`; la pantalla avisa «El grupo no tiene cupos: quedaste en la lista de espera». Pruebas en `integracion/listaEspera_integracion_test.dart`, `conexionInscripcionRemoto_test.dart` y `VmInscripcionTest.prueba4CupoLleno`, reescrita porque el 409 ya no existe |
| BK-07 | Inscripciones | **Revisado el 2026-11-05.** (a) Repetir una inscripción activa con cupos responde 201 y reescribe `fechaInscripcion`, no 409. (b) Un alumno inexistente da 500 con la traza completa de Spring en el cuerpo, no 404. **Corrección:** un grupo inexistente **sí** da 404 `GC-0003`; antes no se veía porque `prueba5` se detiene en la primera aserción. (c) El grupo cerrado da 422 (`GC-0012` si es a mano, `GC-0016` por fechas, este último leído en el código), no 409: es regla nueva, no bug; la app lo trata como cualquier rechazo y solo falla la expectativa vieja de `VmGruposInscripcionTest` · prueba3 | `remoto_diagnostico` · BUG BK-07 ×2 (`Expected: Fallo`, `Actual: Exito`; `Expected: <404>`, `Actual: <500>`); `VmInscripcionTest` · prueba1 y prueba5 | **Prueba contra el backend real.** (b) no se alcanza desde la pantalla: con rol alumno y otro id la respuesta es 403 antes | M | backend | **corregido** (2026-11-06): (a) el backend rechaza repetir una inscripción activa con `409 GC-0007` y la app tampoco la envía; (b) un alumno inexistente da `404 GC-0003`, ya no `500` con la traza (comprobado contra el backend real). (c) descartado. Prueba (b) en `test/diagnostico/inscripciones/remoto_diagnostico_test.dart`, que ahora pasa a verde y puede moverse a la suite remota |
| BK-08 | Clases | Registrar una clase en una fecha que ya tiene clase da `Fallo -1 type '_Map<String, dynamic>' is not a subtype of type 'String'`. **Causa probada:** el backend reutiliza la clase y responde 200 con ella; la conexión solo acepta 201, `RespuestaModelo.fromResponse` pone el mapa como mensaje y salta el `TypeError` (como CAT-07). Por eso falla `prueba3FechaSinCorrimiento`: registra cuatro horas de un mismo día. Afecta CL-06 solo en esa prueba; no significa que CL-06 volviera | `transversal/remoto_backend_nuevo` · BUG BK-08 (`Fallo -1 type…`); `VmClaseDiagnosticoTest` · prueba3 | **Prueba contra el backend real** + `ClaseRest` | M | app | **corregido** (2026-11-05): `RespuestaModelo.fromResponse` siempre produce texto, la conexión acepta 200 y 201, y `registrarClase` devuelve `Exito<bool>`: con `false` la pantalla avisa «Ya existía una clase en esa fecha; no se creó otra», porque las horas enviadas no se guardan. Pruebas en `integracion/clases_integracion_test.dart`, `unitarias/modelo/respuestaModelo_test.dart` y `VmClaseDiagnosticoTest.prueba7FechaConClase` (backend real). `prueba3FechaSinCorrimiento` pasó a usar un día por hora y sigue en rojo por CL-07 |
| BK-09 | Inscripciones | Después de inscribir con éxito, `validarInscripcion` devuelve `false` y la tarjeta vuelve a «Matricular», sin error. Se pasa solo en menos de un segundo, pero la pantalla ya no vuelve a consultar | `remoto_diagnostico` · BUG BK-09 (envío entre .600 y .850 del segundo: `Expected: true`, `Actual: <false>`, 3 de 3) y su control (envío entre .050 y .350: verde, 3 de 3). Efecto secundario en `VmInscripcionTest` · prueba1, prueba2 y prueba7 y `VmGruposInscripcionTest` · prueba4 | **Prueba contra el backend real.** **Causa:** `fechaInscripcion` se guarda sin fracción de segundo y redondeada hacia arriba, y `existeInscripcionActiva` exige `fechaInscripcion <= CURRENT_TIMESTAMP`. Observado: el POST devolvió `21:20:46.624` y la fila quedó en `21:20:47.000`. Lo anterior sobre la zona de Bogotá queda descartado como causa. **Por confirmar:** el tipo de la columna, en el esquema | M | backend | **corregido por el backend** (2026-11-06): quitó la condición `fechaInscripcion <= CURRENT_TIMESTAMP` de `existeInscripcionActiva`; el POST en la segunda mitad del segundo ya valida `true` de inmediato (comprobado a .658 y .710). La mitigación de la app (`recienInscrito`) se conserva, es inocua. Prueba contra el backend sin pasar por el VM: `VmInscripcionTest.prueba14BackendValidaAlInstante` |
| BK-10 | Categorías / transversal | Sin sesión, todas las rutas de lectura dan 401 sin cuerpo y la app abre en categorías: la pantalla inicial muestra `Código: 401 - ` en lugar de pedir que se inicie sesión | `transversal/remoto_backend_nuevo` · BUG BK-10 (`Actual: 'Código: 401 - '`) | **Prueba contra el backend real.** **Por decidir con el cliente:** si un visitante debe poder ver el catálogo; eso exigiría abrir esas rutas en el backend | M | app + cliente | **corregido en el mensaje** (2026-11-06) con IN-17: la pantalla inicial dice que hay que iniciar sesión, con el prefijo `Código: 401 -`. Sigue **por decidir con el cliente** si un visitante debe ver el catálogo. Prueba en `integracion/categorias_integracion_test.dart` |
| BK-11 | Autenticación | «Continuar con correo» ya no puede funcionar: `GET /login` exige un JWT que solo se obtiene después de entrar. `VmLoginTest` · prueba1 sigue en verde porque la suite sí manda un token | `transversal/remoto_backend_nuevo` · BUG BK-11 (`Expected: not <401>`, `Actual: <401>`) | **Prueba contra el backend real** | M | app (quitar la opción) | **confirmado** |

Con BK-01 cambió una regla de la app: ya no existe "abrir sin fecha límite". `VmPeriodoInscripcionTest` · prueba1 y prueba2 se reescribieron para eso. Un grupo sin ninguna fecha sigue mostrándose "Sin abrir", aunque para el backend está abierto: solo puede ser un grupo viejo.

Ninguna prueba actúa todavía con rol de alumno o instructor. Hay ayudantes (`actuarComoAlumno`, `actuarComoInstructor`), pero los permisos por rol siguen sin probarse. Observado con un token de alumno: `GET /instructores` responde 200.

**HO-06 (confirmado y corregido el 2026-11-19):** el formulario de horarios (`widgetListaHorarios.dart`) guarda `Miércoles` y `Sábado` con tilde, y el backend (`CalculadoraDuracionClase`) compara el día con `equalsIgnoreCase` contra `MIERCOLES` y `SABADO`. Un horario del miércoles creado desde la app no cuenta: la clase de ese día responde 422 `GC-0021` pidiendo justificación (`El grupo no tiene horario asignado ese dia`). Con `MIERCOLES` sin tilde se registra.

- Evidencia: `transversal/remoto_backend_nuevo` · BUG HO-06 (`Fallo 422 ... debe indicar una justificacion`) y su control `control HO-06` (sin tilde) en verde.
- Efecto inferido, no probado: el instructor no puede registrar la clase de esos días (`DiaFueraDeHorarioExcepcion`) y la duración no sale del horario.
- Severidad M · responsable app · **corregido**: `DiaSemana` (`domain/entities/diaSemana.dart`) traduce entre el código del backend (`MIERCOLES`) y la etiqueta (`Miércoles`). `DetalleGrupoViewModel.agregarHorario` envía siempre el código (un día que no existe no se envía), el formulario ofrece las etiquetas y las pantallas muestran la etiqueta, también de los horarios viejos guardados con tilde. Esos horarios viejos **siguen sin contar** para el backend: hay que borrarlos y crearlos de nuevo (o corregirlos en la base). La prueba pasó a la suite remota (`VmClaseDiagnosticoTest.prueba9DiaConTilde`); unitarias en `dominio/diaSemana_test.dart`, `viewModel/detalleGrupoViewModel_test.dart` y `vista/horariosGrupoView_test.dart`.

**Siembras de la suite remota (2026-11-19):** el `setUpAll` de Grupos y Alumnos no fallaba por BK-04 sino porque reusaba un mismo `Inscripcionviewmodel` para varios alumnos: el vm recuerda el estado por grupo y bloquea al segundo (409 de la propia app). Ahora usan un vm por inscripción, como en la app. La suite remota queda en verde: 129 (130 con HO-06).

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

| IN-14 | [SCRUMBAN-105](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-105) | IN-15 | [SCRUMBAN-106](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-106) | IN-16 | [SCRUMBAN-107](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-107) |
| IN-17 | [SCRUMBAN-108](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-108) | ES-06 | [SCRUMBAN-109](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-109) | ES-07 | [SCRUMBAN-110](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-110) |
| BK-02 | [SCRUMBAN-111](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-111) | BK-04 | [SCRUMBAN-112](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-112) | BK-05 | [SCRUMBAN-113](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-113) |
| BK-06 | [SCRUMBAN-114](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-114) | BK-07 | [SCRUMBAN-115](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-115) | BK-08 | [SCRUMBAN-116](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-116) |
| BK-09 | [SCRUMBAN-117](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-117) | BK-10 | [SCRUMBAN-118](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-118) | BK-11 | [SCRUMBAN-119](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-119) |
| AU-09 | [SCRUMBAN-120](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-120) | AU-06 | [SCRUMBAN-121](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-121) | AU-05 | [SCRUMBAN-122](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-122) |
| AU-08 | [SCRUMBAN-123](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-123) | AU-10 | [SCRUMBAN-124](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-124) | AU-04 | [SCRUMBAN-125](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-125) |
| AU-01 | [SCRUMBAN-126](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-126) | AU-03 | [SCRUMBAN-127](https://unicauca-team-nqfpise2.atlassian.net/browse/SCRUMBAN-127) |  |  |

**Cerradas en Jira (Finalizado, 2026-11-05):** las seis corregidas que estaban abiertas, GR-02 (SCRUMBAN-60), HO-01 (SCRUMBAN-83), CAT-14 (SCRUMBAN-78), CAT-05 (SCRUMBAN-74), CU-05 (SCRUMBAN-69) y CU-03 (SCRUMBAN-67); y las cinco halladas y corregidas el 2026-11-04 y 05 (CU-06, CU-07, DE-01, GR-07, GR-08), creadas en la Epic ya cerradas. Antes de cerrar se comprobó que ninguna de las seis tiene prueba de diagnóstico en rojo y que los 53 hallazgos abiertos siguen con la suya en rojo. Quedan 53 tareas en «Por hacer».

**Revisión contra el backend nuevo (2026-11-05):**

- **Cerradas en Jira, con un comentario que explica la corrección:** IN-13 (SCRUMBAN-53), ES-05 (SCRUMBAN-58), GR-06 (SCRUMBAN-64) y CL-01 (SCRUMBAN-79). Las cuatro las corrigió el backend y sus pruebas están en verde.
- **Creadas en la Epic, en «Por hacer»:** los 15 hallazgos confirmados contra el backend nuevo que no tenían tarea. La severidad A se pasó a prioridad High.
- **Creadas después, en «Por hacer»:** los ocho hallazgos abiertos de autenticación (AU-01, AU-03 a AU-06, AU-08 a AU-10).
- **Cerrada después:** FA-04 (SCRUMBAN-96), que estaba corregida en la app y seguía abierta en Jira.
- **Sin tarea:** BK-01 y BK-03, ya corregidos, y AU-B01, corregido en la app y pendiente de probar con una cuenta real.

**Sprint 1 (SCRUM Sprint 1, 2026-11-05):** se revisaron sus seis tareas contra el backend nuevo. IN-08, IN-09, IN-10 e IN-13 siguen resueltas; IN-09 e IN-10 se comprobaron también contra el backend real (401 real y sin conexión; POST 201 real con revalidación 401 real). IN-11 (SCRUMBAN-51) e IN-12 (SCRUMBAN-52) se corrigieron y se cerraron. Sin backend: 357 en verde. Queda abierto fuera del sprint BK-09 (SCRUMBAN-117), que deja el mismo síntoma visible de IN-10 por otra causa: el backend responde `false` sin error. La suite remota dio 13 rojos a las 23:09: los 7 de la tabla, 3 de BK-09 según la corrida, y 3 de clases y estadísticas sin explicar (se sospecha de la hora, por el cambio de día en UTC; sin comprobar).

**Corrección de BK-08 (2026-11-05):** sin backend, 365 en verde. La suite remota da 100 en verde y 13 en rojo a las 23:45: BK-05 ×2, la expectativa vieja de prueba3, BK-06, BK-07 ×2, 3 según la corrida por BK-09, y 4 de clases y estadísticas que aparecen desde las 19:00 hora local (CL-07; en estadísticas, inferido). La tarea SCRUMBAN-116 sigue abierta en Jira.

**Corrección de CL-07 (2026-11-05, 23:43):** sin backend, 366 en verde. Remota: 106 en verde y 7 en rojo: BK-05 ×2, la expectativa vieja de prueba3, BK-06, BK-07 ×2 y `Cargar estados`, que varía según la corrida por BK-09.

| ID | Módulo | Síntoma observable | Prueba | Origen de la evidencia | Sev. | Resp. | Estado |
|---|---|---|---|---|---|---|---|
| CL-07 | Clases | Desde las 19:00 hora local, la fecha de la clase salta al día siguiente. Con la fecha por defecto del formulario (`DateTime.now()`), registrar la clase de hoy da 422 `GC-0018`: «La fecha de la clase (2026-11-06) no puede ser posterior a hoy (2026-11-05)». Causa: `Clasemodelo.toJson` envía `fecha.toUtc()` (corrección de CL-06), y el backend nuevo recibe `fecha` como `LocalDate` y toma la parte de fecha tal cual. La corrección de CL-06 era válida para el backend anterior | `VmClaseDiagnosticoTest` · prueba1 (`Expected: '2026-11-04'`, `Actual: '2026-11-05'`), prueba2 (el 422 citado) y prueba3 (caso 23:30). Corrida a las 23:37 | **Prueba contra el backend real** + `ClaseDto.java`. **Inferido al registrarlo, comprobado al corregir:** el rojo de estadísticas «un rango de un solo día» venía de lo mismo. El selector de fecha entrega 00:00, así que elegir un día a mano no se veía afectado | A | app | **corregido** (2026-11-05): `Clasemodelo.toJson` envía solo el día local (`yyyy-MM-dd`), sin hora ni zona. Esto reemplaza la corrección de CL-06. A las 23:43, contra el backend real, prueba1, prueba2, prueba3 y estadísticas pasaron a verde; un caso nuevo en `integracion/clases_integracion_test.dart` fija 23:30. Sin tarea en Jira |

**Corrección de BK-06 e IN-15 (2026-11-06):** sin backend, 375 en verde. Remota: 106 en verde y 7 en rojo: BK-05 ×2, la expectativa vieja de `VmGruposInscripcionTest` · prueba3, BK-07 ×2 y 2 que dependen de BK-09 según la corrida. `VmInscripcionTest.prueba7CargarEstados` espera a que pase el segundo para no mezclarse con BK-09. Las tareas SCRUMBAN-114 y SCRUMBAN-106 siguen abiertas en Jira. No se probó en un dispositivo.

**Corrección de IN-16 e IN-17 (2026-11-06):** el cambio está en `RespuestaModelo.fromDioException`, así que alcanza a las 15 conexiones y también deja en verde ES-07 y BK-10. `mensajeErrorRegistro` se ajustó porque leía ese JSON. Las once aserciones que buscaban `GC-xxxx` en el mensaje ahora comprueban el motivo. El código `GC-xxxx` ya no llega a `ErrorModelo`. IT-01 sigue abierto: el JSON crudo ya no aparece, pero el 404 aún no se trata como lista vacía. Sin backend, 384 en verde. Remota: 109 en verde y 7 en rojo: BK-05 ×2, la expectativa vieja de `VmGruposInscripcionTest` · prueba3, BK-07 ×2 y 2 según la corrida por BK-09. En Jira siguen abiertas SCRUMBAN-107, SCRUMBAN-108, SCRUMBAN-110 y SCRUMBAN-118. No se probó en un dispositivo.
