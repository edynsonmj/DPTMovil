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
- Las hipótesis de categorías (CAT-01 a CAT-12, T-01 a T-05, en el anexo A del plan) son **solo de lectura del código**: todavía no tienen prueba.

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
| AS-B01 | Backend | No existen `GET /atencionesporclase` ni `POST /atenciones` (404); la funcionalidad no se puede usar en ningún entorno | `/v3/api-docs` del 2026-10-28; `VmAtencionTest.prueba4BackendSinEndpoint` | **API del backend.** La lista de rutas de `/v3/api-docs` y la prueba remota existente, que da 404 contra el backend real | A | backend | **confirmado** |
| AS-01 | Navegación / roles | **Si llegan a la pantalla del grupo**, un alumno y un usuario sin sesión ven "AGREGAR CLASE" y el botón de eliminar clase, y abren la toma de asistencia: ni esa pantalla ni la ruta `clase` comprueban el rol. En la app (2026-10-29) el alumno **no llega** a esa pantalla: por el catálogo se queda en la lista de cursos, porque tocar un curso solo navega para el coordinador ([cursos.dart:184](../lib/presentation/view/views/curso/cursos.dart), ver O-01); en inscripciones solo ve los cursos a los que puede inscribirse; y el menú lateral muestra "grupos asignados" solo al instructor. Lo mismo vale sin sesión. Lo que falta es la comprobación en la pantalla y en la ruta (defensa en profundidad), no un camino abierto conocido. Que coordinador e instructor vean "AGREGAR CLASE" es lo esperado | `vista_diagnostico` · AS-01 alumno y AS-01 sin sesión (control en verde) | **Prueba + emulador.** La prueba monta la pantalla del grupo **directamente**, sin pasar por la navegación: demuestra lo que hace la pantalla, no que se pueda llegar a ella. Que no se llega sale de lo que observó el usuario en el emulador y de leer `cursos.dart` | A → **M** (no hay camino conocido en la interfaz) | app | **confirmado, aplazado por decisión**: roles y autenticación se tratan al final de la corrección de hallazgos. El caso del instructor ajeno al grupo espera la regla 3.4-1. Sus pruebas siguen en rojo como evidencia |
| AS-02 | Vista | Dos toques a "Guardar" mientras el primer envío sigue en camino → **2** registros enviados | `vista_diagnostico` · AS-02 (`Expected: <1>`, `Actual: <2>`); `integracion_diagnostico` · AS-02 (2 POST en la red) | **Prueba** (pantalla y de punta a punta). **Inferido:** que se dupliquen los registros en la base de datos depende de si un segundo POST reemplaza o agrega (pregunta 2 del contrato) | M (A si se confirma B-01) | app | **confirmado** |
| AS-03 | Vista / VM | Tras una carga con 500, "Guardar" sigue activo y muestra "No hay alumnos para registrar", lo que oculta el error real | `vista_diagnostico` · AS-03 | **Prueba** | M | app | **confirmado** |
| AS-04 | Conexión | Con categoría `Fútbol & Voleibol` el backend recibe `categoria=Fútbol ` (el `&` corta el valor), así que se pide otra clase | `conexion_diagnostico` · AS-04 | **Prueba** (la URI que sale de la app). **Inferido:** que el backend responda con otra clase o con ninguna; no hay backend con el que comprobarlo | M (A si se confirma B-02) | app | **confirmado** |
| AS-05 | Modelo | Al registrar, cada alumno se reenvía con `codigo: null` (había `'104619011001'`) e `imagen: null`, y un alumno retirado (`eliminadoestado: 1`) se reenvía como activo (`0`). Causas: `Alumnomodelo.fromJson` no lee `codigo` ni `imagen`, `toJson` fija `eliminadoestado: 0` y `Alumnoentidad` no tiene ese campo. El repositorio no es la causa (E-02 en verde) | `conexion_diagnostico` · AS-05 ×2 (cadena real completa) | **Prueba** (el JSON que la app envía). **Inferido:** que se borren datos o se reactiven alumnos depende de si el backend guarda el alumno que va dentro de cada asistencia (pregunta 3 del contrato). La causa (qué línea pierde cada campo) sale de leer el código | M (A si se confirma B-03) | app + backend | **confirmado**. El daño real depende de si el backend guarda el alumno que va dentro de cada asistencia (pregunta 3 del contrato) |
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
| Confirmado por prueba (con dobles o con el adaptador falso) | — | 7 (AS-01, 02, 03, 04, 05, 06, 07) | 3 (AS-08, 12, X-01) | 10 |
| Confirmado contra el backend | 1 (AS-B01) | — | — | 1 |
| Requisito propuesto o regla del cliente | — | 3 (AS-09, 11, 13) | 1 (AS-10) | 4 |
| Descartado | — | 1 (AS-14) | — | 1 |

AS-02, AS-04, AS-05 y AS-07 suben a **A** si se confirman B-01, B-02, B-03 y B-04, respectivamente.

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
| IN-06 | Modelo / formulario de grupo | `fechaCreacion` la fija la app con la fecha del día ([GrupoFormulario.dart:243](../lib/presentation/view/views/grupo/GrupoFormulario.dart)). `fechaFinalizacion` existe en `GrupoModelo` y se lee del backend, pero el formulario no la pide y `toJson` no la envía ([grupoModelo.dart:59-70](../lib/data/models/grupoModelo.dart)): la app no puede fijar cuándo termina un grupo. Ninguna de las dos es una fecha de inscripción | — | **Código** | B | app | hipótesis (prueba U-Con o U-Modelo: el JSON del POST `/grupo` no lleva `fechaFinalizacion`) |
| IN-07 | Conexión | **Confirmado el 2026-10-29.** El backend cambió `GET /validarInscripcion`: ahora exige `alumnoId`, `categoria`, `curso`, `anio` e `iterable` como **parámetros de query** (`/v3/api-docs`). La app los sigue mandando en el **cuerpo del GET** ([ConexionInscripcionRemoto.dart:47-51](../lib/data/api/conexion/remoto/ConexionInscripcionRemoto.dart)); el backend responde `400 MissingServletRequestParameterException` y `Inscripcionviewmodel.validarInscripcion` lo convierte en `false`. Efecto: tras inscribirse con éxito, la pantalla del alumno sigue mostrando "Matricular" | `VmGruposInscripcionTest.prueba4CicloInscripcion` (remota): inscribir → `Exito`, pero validar después → `false` (`Expected: true`, `Actual: false`). Petición manual: con cuerpo y sin query → 400; con query → 200 | **Prueba (remota) + API del backend.** **Inferido:** que el alumno, al ver "Matricular", vuelva a intentarlo y reciba el 409 de "ya está inscrito" (según la descripción del endpoint; no probado) | M | app | **corregido** (2026-10-29): `validarInscripcion` envía la inscripción con `queryParameters`, sin cuerpo, y una respuesta que no es booleana se devuelve como error. Pruebas: `test/unitarias/conexion/conexionInscripcionRemoto_test.dart` (4) y el ciclo remoto otra vez en verde (suite remota 65/65) |

Relacionados ya registrados: estas dos pantallas cargan las categorías con `cargarCategorias(context)`, de estilo antiguo (CAT-04 y CAT-05 en el anexo A del plan).
