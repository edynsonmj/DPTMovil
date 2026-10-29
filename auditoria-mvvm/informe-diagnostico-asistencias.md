# Informe de diagnóstico: módulo de toma de asistencias

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias` · Plan: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md) · Evidencia detallada: [registro-bugs.md](registro-bugs.md)

Los hallazgos están separados en dos partes:
- la **parte A** recoge solo lo **confirmado por pruebas ejecutadas** (unitarias, de widget e integración local, con dobles o con el adaptador HTTP falso);
- la **parte B** recoge lo que **se infiere** y hay que comprobar con el backend o preguntar al cliente.

Ninguna prueba corrió contra el backend real. Por eso la parte A describe lo que la app **hace o envía**, no lo que haría el servidor.

## 1. Conclusión

- **Confirmado contra el backend:** la toma de asistencias no se puede usar hoy en ningún entorno. El backend no tiene los endpoints para listar ni para registrar (AS-B01).
- **Confirmado por pruebas:** 10 fallos de la app (parte A). Con lo que las pruebas demuestran, todos son de severidad **media o baja**. Ninguno queda probado como pérdida de datos: esa consecuencia depende del backend.
- **Por comprobar:** 4 de esos fallos (AS-02, AS-04, AS-05 y AS-07) **pueden ser graves** según cómo se comporte el backend cuando exista (parte B).
- **El camino normal funciona con dobles:** cargar, marcar, guardar, avisar y volver, incluidos los errores de red y del servidor. Lo comprueban 3 pruebas de integración local y 23 unitarias, en verde.
- **Decisión del equipo:** roles y autenticación se tratan **al final** (AS-01, O-01).

## 2. Qué se hizo

| Fase | Resultado |
|---|---|
| 0. Línea base | 82 pruebas en verde; `flutter analyze` con 0 errores y 31 warnings; el backend publica 33 rutas y ninguna es de asistencias |
| 1. Infraestructura | Transporte HTTP falso para Dio, contrato propuesto en JSON, etiqueta `diagnostico`, registro de bugs |
| 2. Limpieza de pruebas existentes | De las 12 pruebas que había, 6 se apoyaban en datos inventados por el doble y 1 dejaba en verde un 404. Ahora usan el contrato o están etiquetadas como bug |
| 3. Unitarias nuevas | 23 pruebas, todas en verde (conexión, modelos, repositorio, ViewModel, pantalla) |
| 4. Diagnóstico | 17 en rojo, 1 de control en verde, 1 omitida |
| 5. Integración local | 3 en verde (flujo real con las rutas de la app) y 2 en rojo (AS-07 y AS-02 de punta a punta) |

**Estado final:**
- Suite sin backend + integración: **113 pruebas en verde**.
- `test/diagnostico`: **19 en rojo**. Son las 10 fallas de la parte A y AS-09, una funcionalidad propuesta que está en la parte B.
- `flutter analyze`: sin warnings nuevos.

## 3. Parte A: confirmados por pruebas

Solo lo que la prueba observó. La severidad corresponde a **lo probado**, no a la peor consecuencia posible; la columna "Ver parte B" indica cuándo podría subir.

| ID | Lo que la prueba demostró | Pruebas (todas en rojo) | Sev. | Ver parte B |
|---|---|---|---|---|
| AS-02 | Dos toques a "Guardar" mientras el primer envío sigue en camino producen **2 POST** | `vista_diagnostico` AS-02; `integracion_diagnostico` AS-02 | M | B-01 |
| AS-04 | Con la categoría `Fútbol & Voleibol`, la URL del GET lleva `categoria=Fútbol `: el `&` sin codificar corta el valor | `conexion_diagnostico` AS-04 | M | B-02 |
| AS-05 | Al registrar, la app envía cada alumno con `codigo: null` e `imagen: null` aunque los recibió con valor, y un alumno con `eliminadoestado: 1` sale con `0`. Las causas están en `Alumnomodelo.fromJson`/`toJson` y `Alumnoentidad`, no en el repositorio (su prueba está en verde) | `conexion_diagnostico` AS-05 ×2, con la cadena real completa | M | B-03 |
| AS-07 | Si el POST responde **201** sin cuerpo, la conexión lanza un `TypeError` y el usuario ve "Error al registrar atenciones" con el texto `type 'Null' is not a subtype of type 'String'`. Si responde **204**, la conexión devuelve un error. En ambos casos el ViewModel devuelve `Fallo` | `conexion_diagnostico` AS-07 ×2; `viewModel_diagnostico` AS-07 ×2; `integracion_diagnostico` AS-07 | M | B-04 |
| AS-03 | Tras una carga que falló con 500, "Guardar" sigue activo y muestra "No hay alumnos para registrar", no el error de carga | `vista_diagnostico` AS-03 | M | — |
| AS-06 | Un JSON con `estaAtendido: null` provoca un `TypeError` que **sale** de la conexión en vez de devolverse como error. El JSON lo fabrica la prueba | `conexion_diagnostico` AS-06 | M | B-05 |
| AS-01 | Montando **directamente** la pantalla del grupo con sesión de alumno o sin sesión, se ven "AGREGAR CLASE" y eliminar, y se abre la toma de asistencia. Ni esa pantalla ni la ruta `clase` comprueban el rol. La prueba de control (instructor del grupo) está en verde. **No** prueba que se pueda llegar a esa pantalla: en el emulador, el alumno se queda en la lista de cursos (O-01). **Aplazado** a roles y autenticación | `vista_diagnostico` AS-01 ×2 | M | B-11 |
| AS-08 | Una atención con `idClase: 999` dentro de un registro de la clase 210 llega a la red sin validarse. La entrada la fabrica la prueba; la pantalla actual siempre envía el mismo `idClase` | `viewModel_diagnostico` AS-08 | B | B-06 |
| AS-12 | Un `receiveTimeout` se reporta con código 0 en vez de 408 | `conexion_diagnostico` AS-12 | B | — |
| X-01 | `DialogError` no muestra el código del error en ninguna de sus dos formas. El diálogo se usa en toda la app | `dialogError_diagnostico` ×2 | B | — |

**Confirmado fuera de las pruebas de la app:**
- **AS-B01**, endpoints inexistentes: se comprobó en `/v3/api-docs` del backend levantado y con la prueba remota existente, que da 404.

**Comportamiento probado como correcto** (verde), para no confundirlo con fallos:
- carga y registro con 200;
- errores 400, 404, 500 y sin red, con su mensaje;
- lista vacía;
- se envía la última marca de cada alumno;
- tras un fallo, la pantalla conserva las marcas;
- tras un éxito, avisa y vuelve atrás.

## 4. Parte B: inferencias por comprobar

Nada de esta parte está demostrado por una prueba. Cada fila dice cómo se confirmaría.

### Con el backend (cuando existan los endpoints)

Las preguntas correspondientes están en [entregables/contrato-atenciones-backend.md](entregables/contrato-atenciones-backend.md).

| ID | Inferencia | Cómo se confirma | Si se confirma |
|---|---|---|---|
| B-01 | El segundo POST de AS-02 **duplica** las asistencias en la base de datos (y en estadísticas) | Pregunta 2 del contrato; prueba remota que registra dos veces la misma clase y cuenta los registros | AS-02 sube a **A** |
| B-02 | Con el valor cortado de AS-04, el backend devuelve **la lista de otra clase o ninguna**, y el instructor podría registrar sobre una lista equivocada | Prueba remota con una categoría o un curso que tenga `&`, `+` o `#` en el nombre | AS-04 sube a **A** |
| B-03 | El backend **guarda el alumno anidado** del POST, así que los `null` de AS-05 **borran** `codigo` e `imagen` y reactivan alumnos retirados | Pregunta 3 del contrato; prueba remota que registra y vuelve a leer el alumno | AS-05 sube a **A** |
| B-04 | El backend responderá **201 o 204** al POST. Entonces el usuario verá error tras un registro exitoso y **reintentará** (lo que lleva a B-01) | Pregunta 1 del contrato. Si responde 200, AS-07 no se ve en uso real, aunque el código sigue siendo frágil | AS-07 sube a **A** |
| B-05 | El backend puede enviar `estaAtendido` o `idClase` **nulos** (AS-06) | Revisar el modelo del backend o una respuesta real | Confirma que AS-06 ocurre en la práctica |
| B-06 | Qué hace el backend con un `idClase` del cuerpo distinto de `?idclase=` (AS-08) | Pregunta 4 del contrato | Define si basta con la validación en la app |
| B-07 | El GET incluye alumnos **retirados** (`eliminadoestado: 1`) (AS-11) | Pregunta 5 del contrato | Junto con la regla del cliente (C-04) |
| B-08 | El GET de una clase ya registrada devuelve **las marcas guardadas** | Pregunta 6 del contrato | Define qué se ve al volver a abrir una clase |
| B-09 | **El contrato en general** (rutas, nombres de campo, forma del JSON) coincide con lo que el backend implemente. Lo deduje de lo que la app envía hoy | Comparar la primera respuesta real con `test/contratos/atenciones/` | Cada diferencia es un hallazgo nuevo AS-C-xx |

### Con el cliente

Las preguntas están en [entregables/preguntas-cliente-asistencias.md](entregables/preguntas-cliente-asistencias.md).

| ID | Pregunta (resumen) | Hallazgo que resuelve |
|---|---|---|
| C-01 | ¿Quién toma asistencia: solo el instructor del grupo, también el coordinador, cualquier instructor? | AS-01c (B-11) |
| C-02 | ¿Se puede corregir una asistencia ya guardada? ¿Hasta cuándo? | AS-13 |
| C-03 | ¿Se puede registrar una clase futura? | AS-13 |
| C-04 | ¿Los alumnos retirados aparecen en la lista? | AS-11 (con B-07) |
| C-05 | Al volver a abrir una clase, ¿se ven las marcas guardadas? | con B-08 |
| C-06 | Si sale sin guardar, ¿avisar, perder las marcas o guardar automáticamente? | AS-10 |
| C-07 | ¿Quién abre el detalle de un curso desde el catálogo? Hoy solo el coordinador; para los demás la tarjeta reacciona al toque y no pasa nada | O-01 |
| C-08 | Tras un registro fallido, ¿hay que indicar que las marcas no están guardadas? | AS-09: su prueba está en rojo porque pide `hayCambiosSinGuardar`, una funcionalidad **propuesta por mí** y no acordada. Probado (en verde) solo que la pantalla conserva las marcas tras el fallo |

### Pendientes de prueba en la app (solo lectura del código)

- **B-10:** `Clasemodelo.fromJson` con una `fecha` nula. AS-14 se descartó por los tipos, pero el riesgo pasa a la lectura del JSON de clases (módulo de clases).
- **B-11:** comprobación de rol en pantallas y rutas (AS-01, AS-01c), con roles y autenticación al final.
- **Categorías:** CAT-01 a CAT-12 y T-01 a T-05, en el anexo A del plan. Ninguna tiene prueba todavía.

## 5. Orden de corrección propuesto

Criterio: primero lo que **la prueba ya demostró y depende solo de la app**, empezando por lo que podría volverse grave (parte B). Después, lo que se arregla una vez y beneficia a todas las conexiones. Por último, lo que espera al backend o al cliente. Cada corrección se da por terminada cuando su prueba de diagnóstico pasa a verde y se mueve a la suite normal.

| Lote | Hallazgos | Corrección prevista | Pruebas que deben pasar a verde | Tamaño |
|---|---|---|---|---|
| **1. Doble envío** | AS-02 | Estado `guardando` en el ViewModel que deshabilita "Guardar" y muestra el indicador de carga | `vista_diagnostico` AS-02; `integracion_diagnostico` AS-02 | S |
| **2. Datos que se envían mal** | AS-04, AS-05 | `queryParameters` de Dio en lugar de interpolar la URL. `Alumnomodelo.fromJson` lee `codigo` e `imagen`; `Alumnoentidad` conserva `eliminadoestado` y `toJson` no lo fuerza | `conexion_diagnostico` AS-04 y AS-05 ×2 | S |
| **3. Respuestas mal interpretadas (transversal)** | AS-07, AS-06, AS-12 | En `RespuestaModelo` y las conexiones: aceptar cualquier 2xx como éxito; `ErrorModelo.mensaje` tolera cuerpos nulos o JSON; capturar también `Error` (`TypeError`) con `fromObjectError`; `receiveTimeout` → 408. **Se hace una vez y beneficia a todas las conexiones** | `conexion_diagnostico` AS-06, AS-07 ×2, AS-12; `viewModel_diagnostico` AS-07 ×2; `integracion_diagnostico` AS-07 | M |
| **4. Mensajes en pantalla** | AS-03, AS-08, X-01 | "Guardar" deshabilitado si la carga falló; validar `idClase` en el repositorio; `DialogError` muestra el código | `vista_diagnostico` AS-03; `viewModel_diagnostico` AS-08; `dialogError_diagnostico` ×2 | S |
| **5. Backend** | AS-B01, B-01 a B-09 | El backend implementa los endpoints según el contrato acordado; después, pruebas remotas que confirman o descartan la parte B | Fase 7: pruebas remotas | — |
| **6. Reglas del cliente** | C-02 a C-08 (AS-09, AS-10, AS-11, AS-13, O-01) | Según las respuestas | AS-09 (ya escrita) y las que se escriban | — |
| **7. Roles y autenticación (al final, por decisión)** | AS-01, C-01 (AS-01c), O-01 | La pantalla del grupo y la ruta `clase` comprueban la sesión y el rol | `vista_diagnostico` AS-01 ×2 (+ AS-01c al conocer la regla) | M |

Los lotes 1 a 4 no dependen del backend ni del cliente y se pueden hacer ya. Corregir AS-02, AS-04, AS-05 y AS-07 antes de que exista el backend evita que la parte B llegue a ocurrir, sea cual sea su respuesta.

## 6. Cómo reproducir

```bash
flutter test test/unitarias test/raiz_composicion_test.dart test/integracion
flutter test test/diagnostico
```

El primer comando debe salir en verde (113 pruebas). El segundo sale en rojo a propósito: 19 pruebas en rojo, 1 en verde y 1 omitida, y cada prueba roja lleva en su nombre el ID del hallazgo.

## 7. Límites del diagnóstico

- **Sin backend real:** ninguna prueba corrió contra el backend en el flujo de asistencias, porque los endpoints no existen. Todo lo que dependa del servidor está en la parte B.
- **Contrato propuesto:** lo deduje de lo que la app envía hoy (B-09).
- **Sesgo de búsqueda:** las pruebas de diagnóstico se escribieron a partir de hipótesis sacadas del código. Un rojo confirma lo que se buscó; no garantiza que no haya otros fallos.
- **Módulos vecinos con dobles:** grupos, horarios, curso, alumnos y clases entraron con dobles. Sus propios bugs se diagnostican en sus módulos.
- **Solo Windows:** el import con mayúsculas de `route_generator.dart` (CAT-11) puede impedir compilar en Linux o en CI.
