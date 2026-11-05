# Plan de diagnóstico por pruebas unitarias y de integración

Fecha: 2026-10-28 · Rama: `refactor/inyeccion-dependencias` (tras f2141e5)
Versión 2: el orden de los módulos se decide por **valor para el cliente**. El módulo 1 es la **toma de asistencias**. La versión 1 empezaba por categorías; sus hallazgos se conservan en el anexo A.

Objetivo: usar pruebas para **encontrar y documentar** bugs, módulo por módulo, antes de corregirlos.
Una prueba de diagnóstico afirma el comportamiento **correcto**; si sale roja, el bug queda probado y registrado.
La corrección viene después, y esa misma prueba pasa a verde como prueba de regresión.

---

## 1. Criterios para detectar pruebas "hechas para pasar"

Una prueba está hecha para pasar cuando su verde no aporta evidencia sobre la aplicación real.

| Código | Señal | Por qué engaña |
|---|---|---|
| **D1** | El doble acepta entradas que la implementación real rechaza o con las que revienta | La prueba recorre un camino que en producción no existe |
| **D2** | Lo que se afirma es lo que el doble devuelve, o un contrato inventado por el propio doble | Se comprueba el doble, no la lógica ni la integración |
| **D3** | La prueba entra por un método distinto al que usa la vista y se salta sus validaciones | La regla de negocio queda sin probar |
| **D4** | Prueba de caracterización que fija como "esperado" un comportamiento defectuoso o inexistente | El bug queda en verde y se vuelve invisible |
| **D5** | La prueba fuerza a mano algo que la app debería hacer sola (p. ej. `notifyListeners()`) | Tapa un defecto de reactividad |
| **D6** | Solo hay camino feliz; las ramas de error no se ejecutan nunca | Verde por omisión |
| **D7** | Una capa entera sin pruebas propias | Sus defectos solo se verían contra el backend |

---

## 2. Infraestructura y convenciones (se montan una vez, en el módulo 1)

### 2.1 Niveles de prueba

| Nivel | Qué se arma | Sin backend | Dónde |
|---|---|---|---|
| **U-Repo** | `Repositorio(doble)` | sí | `test/unitarias/repositorio/` |
| **U-VM** | `VM(Servicio(Repositorio(doble)))` | sí | `test/unitarias/viewModel/` |
| **U-Con** *(nuevo)* | `ConexionXRemoto(Dio con adaptador HTTP falso)` | sí | `test/unitarias/conexion/` |
| **U-Vista** | pantalla + providers de la ruta + dobles | sí | `test/unitarias/vista/` |
| **I-Local** *(nuevo)* | cadena completa `VM → … → ConexionXRemoto → Dio(adaptador falso)` | sí | `test/integracion/` |
| **I-Contrato** *(nuevo)* | fixtures JSON del contrato acordado con el backend, usadas por U-Con e I-Local | sí | `test/contratos/<modulo>/*.json` |
| **I-Remota** | cadena completa contra el backend real | no | `test/remoto/` (vía `main_test.dart`) |

- **Adaptador HTTP falso.** Archivo `test/dobles/adaptadorHttpFalso.dart`. Implementa `HttpClientAdapter` de Dio, sin paquetes nuevos y con el estilo programable de los demás dobles:
  - `respuestas[ruta] = (codigo, cuerpoJson)`
  - `peticiones` (método, URI, cuerpo), para afirmar qué salió por la red
  - opción para lanzar `DioException` de tipo `connectionError`, `receiveTimeout`, etc.
- **Fidelidad de los dobles (contra D1).** Cada `Conexion*Falsa` rechaza lo mismo que la conexión real.
- **Contrato (contra D2).** La forma del JSON deja de vivir escondida en el doble. Pasa a un archivo de fixtures que se revisa con el equipo del backend. Si el backend implementa algo distinto, la diferencia queda escrita.

### 2.2 Pruebas que destapan bugs

- Carpeta `test/diagnostico/<modulo>/`, con la etiqueta `diagnostico` declarada en un `dart_test.yaml` nuevo. Se ejecutan aparte con `flutter test test/diagnostico`. **Se espera que salgan rojas** mientras el bug exista; la suite `test/unitarias` sigue verde.
- Nombre: `'$capa - diagnostico - $metodo - BUG <ID> - <comportamiento correcto esperado>'`.
- Al corregir el bug, la prueba se mueve a `test/unitarias` o `test/integracion`, se le quita la etiqueta y queda como regresión. Si sale verde desde el principio, la hipótesis se registra como **descartada** y la prueba se mueve igual.

### 2.3 Registro

`auditoria-mvvm/registro-bugs.md`, una fila por hallazgo:

`ID | Módulo | Capa | Síntoma observable | Prueba que lo demuestra | Severidad | Estado`

- **Severidad:** A = pérdida o corrupción de datos, crash o acceso indebido; M = operación que falla o mensaje incorrecto; B = cosmético o de mantenimiento.
- **Estado:** hipótesis → confirmado → corregido, o descartado.
- Columna extra **Responsable**: app, backend o cliente (regla de negocio sin definir).

---

## 3. Módulo 1: Toma de asistencias (detallado)

### 3.1 Alcance y flujo

```
Categorías → Cursos → Grupo (widgetListaGrupos)  ┐
Grupos asignados (instructor) → Grupo            ┴→ lista de clases (widgetListaClases)
  → AppRutas.clase (ClaseGrupoargumentos) → Claseview
     → Atencionviewmodel.cargarAtenciones → Servicioatencion → Atencionesrepositorio
        → Conexionatencionesremoto  GET  /atencionesporclase?categoria&curso&anio&iterable&claseid
     → marcarAsistencia (checkbox)
     → registrarAtenciones          POST /atenciones?idclase=X   (cuerpo: lista de Atencionmodelo)
```

Archivos:
- [claseView.dart](../lib/presentation/view/views/clase/claseView.dart)
- [atencionViewModel.dart](../lib/presentation/viewmodels/atencionViewModel.dart)
- [atencionesRepositorio.dart](../lib/data/repositories/atencionesRepositorio.dart)
- [ConexionAtencionesRemoto.dart](../lib/data/api/conexion/remoto/ConexionAtencionesRemoto.dart)
- [atencionModelo.dart](../lib/data/models/atencionModelo.dart)
- [alumnoModelo.dart](../lib/data/models/alumnoModelo.dart)

**Bloqueo conocido.** El backend no tiene ninguno de los dos endpoints; responde 404, según se vio el 2026-10-23 en `/v3/api-docs`. Hay que volver a comprobarlo al empezar: el 2026-10-28 el backend no estaba levantado. Mientras siga así, el diagnóstico del módulo se hace con I-Contrato e I-Local, y la I-Remota queda pendiente.

### 3.2 Pruebas existentes y su valor como evidencia

Estado al 2026-10-28: las 8 pruebas sin backend pasan; las 4 remotas no se ejecutaron porque el backend no estaba levantado.

| # | Prueba | Valor | Señal |
|---|---|---|---|
| E-01 | Repo: listar 200 → entidades | Parcial: la conversión es real, pero el JSON de entrada es inventado | D2 |
| E-02 | Repo: registrar envía modelos y `idClase` | Parcial: no comprueba los campos del alumno que se pierden (AS-05) | D2, D6 |
| E-03 | VM: cargar 200 | Parcial | D2 |
| E-04 | VM: marcar asistencia cambia uno y notifica | **Sí**: lógica propia del VM | — |
| E-05 | VM: registrar 200 envía lo marcado | Parcial: el 200 como código de éxito es una suposición | D2 |
| E-06 | VM: `dispose` antes de la respuesta no revienta | **Sí** | — |
| E-07 | Vista: pinta los alumnos | Parcial | D2 |
| E-08 | Vista: marcar y guardar → diálogo de éxito | Parcial: solo el camino feliz | D2, D6 |
| E-09 | Remota: registrar sin cargar → `Fallo` del VM | **Sí** (no llega a la red) | — |
| E-10 | Remota: clase sin código → error pintable | **Sí** | — |
| E-11 | Remota: marcar sin lista o con índice inválido | **Sí** | — |
| E-12 | Remota: backend sin endpoint → 404 | Fija una funcionalidad inexistente | **D4** |

Capas sin ninguna prueba: la conexión (D7) y los modelos `fromJson`/`toJson`. Ninguna prueba ejecuta un error al cargar o al registrar (D6).

### 3.3 Hipótesis de bugs (encontradas al leer el código)

| ID | Capa | Hipótesis | Sev. | Resp. |
|---|---|---|---|---|
| **AS-01** | Navegación / roles | Ninguna pantalla del camino `curso → grupo → clase` comprueba el rol (no hay `Roles.` en `views/grupo/` ni en `widgetListaGrupos`). La app arranca en categorías sin sesión, así que **un alumno o un usuario sin sesión puede abrir una clase y registrar asistencia**. [widgetListaClases.dart](../lib/presentation/view/views/grupo/widgetListaClases.dart) también muestra "AGREGAR CLASE" y eliminar a cualquiera, y nada comprueba que el instructor en sesión sea el del grupo (`idInstructor`). | A | app |
| **AS-14** | Vista (lista de clases) | `FormatDate.fechaACadena(clase.fecha!, ...)` (líneas 86 y 120): una clase con `fecha` nula **revienta la lista de clases** y no se puede llegar a tomar asistencia de ninguna clase del grupo. | M | app |
| **AS-02** | Vista | El botón "Guardar" no se deshabilita mientras se envía: un doble toque manda **dos POST** y puede duplicar registros. Tampoco hay indicador de carga. | A | app |
| **AS-03** | Vista / VM | "Guardar" está activo también cuando la carga falló. El VM deja `atenciones = []` y responde "No hay alumnos para registrar", un mensaje que **oculta el error real** (red, 404, 500). | M | app |
| **AS-04** | Conexión | Categoría y curso van **sin codificar** en la query de `/atencionesporclase`. Nombres con espacios, `&`, `+`, `#` o tildes hacen que se pida otra clase o ninguna. | A | app |
| **AS-05** | Modelo | `Alumnomodelo.fromJson` **descarta** `codigo` e `imagen`, y `toJson` fuerza `eliminadoestado: 0`. Al registrar se reenvía cada alumno con `codigo: null`, `imagen: null` y como activo. Si el backend guarda el alumno anidado, **borra datos o reactiva alumnos eliminados**. | A | app + backend |
| **AS-06** | Conexión | `Atencionmodelo.fromJson` con `estaAtendido` o `idClase` nulos o de otro tipo lanza `TypeError`, que no es `Exception`, así que **escapa** de la conexión y del repositorio y rompe la regla de devolver errores. En el VM termina como un mensaje técnico. | M | app |
| **AS-07** | Conexión → VM | Solo el **200** cuenta como éxito al registrar. Si el backend responde **201 o 204** (lo habitual en un POST), Dio no lanza excepción, `fromResponse` lo trata como error y el usuario ve un fallo **aunque la asistencia se guardó**. Si reintenta, duplica. | A | app + backend |
| **AS-08** | Repositorio | Cada atención lleva su propio `idClase` y además va `?idclase=X` en la URL; nadie comprueba que coincidan. | B | app |
| **AS-09** | VM | `marcarAsistencia` modifica la entidad en sitio. Si el registro falla, la pantalla muestra marcas que **no están guardadas** y no hay nada que lo indique. | M | app |
| **AS-10** | Vista | "Cancelar" o el botón atrás descartan las marcas sin avisar. | B | cliente |
| **AS-11** | Modelo / VM | No se sabe si la lista trae alumnos **eliminados** (`eliminadoestado`). El VM no los filtra. | M | backend + cliente |
| **AS-12** | Conexión | `receiveTimeout` se reporta con código 0 en vez de 408 (afecta a todas las conexiones; ver CAT-08 en el anexo A). | B | app |
| **AS-13** | Reglas | No hay validación de **fecha**: se puede tomar asistencia de una clase futura o de hace meses, y editarla sin límite. | M | **cliente** |

### 3.4 Reglas de negocio que hay que confirmar con el cliente

Sin estas respuestas, varias hipótesis no se pueden clasificar como bug o como comportamiento esperado:

1. ¿Quién puede tomar asistencia: solo el instructor del grupo, también el coordinador? (AS-01)
2. ¿Se puede corregir una asistencia ya guardada? ¿Hasta cuándo? (AS-13)
3. ¿Se puede registrar una clase futura? (AS-13)
4. ¿Los alumnos retirados o eliminados aparecen en la lista? (AS-11)
5. ¿Al volver a abrir una clase se deben ver las marcas guardadas? Esto define el contrato del GET.
6. ¿Hace falta avisar al salir con cambios sin guardar? (AS-10)

### 3.5 Contrato propuesto para el backend (I-Contrato)

Se escribe como fixtures en `test/contratos/atenciones/` y se envía al equipo del backend para que lo valide:

- `GET /atencionesporclase?...` → `200 [ {alumno:{...}, idClase, estaAtendido} ]`. Lista vacía: ¿`200 []`? Clase inexistente: ¿404?
- `POST /atenciones?idclase=X` → código de éxito (¿200 o 201?) y respuesta ante una clase inexistente, un alumno que no está inscrito en el grupo y un registro repetido.
- Si el contrato acordado difiere de lo que hace la app hoy (ruta, nombres de campo, código de éxito), cada diferencia es un hallazgo **AS-C-xx**.

### 3.6 Pruebas a escribir

**a) Saneamiento de lo existente**

1. E-12: renombrarla a `... - BUG AS-B01 - backend sin endpoints (fija el 404)`, para que se vea que es un hallazgo y no un comportamiento aceptado. Se reemplaza cuando existan los endpoints.
2. `ConexionatencionesFalsa`: cargar sus respuestas por defecto desde las fixtures de contrato (3.5), en lugar de modelos armados en el propio doble.
3. E-02: afirmar **todos** los campos del alumno enviado (`codigo`, `imagen`, `eliminadoestado`) → pasa a ser la prueba de AS-05.

**b) Unitarias nuevas (comportamiento correcto que se espera que ya se cumpla)**

| Capa | Caso |
|---|---|
| U-VM | Cargar con 404, 500, 503 o 0 → `error` con código, `cargando == false`, lista vacía |
| U-VM | Cargar con 200 y lista vacía → sin error, `atenciones` vacía |
| U-VM | Registrar con 400, 404 o 500 → `Fallo` con código y mensaje del `ErrorModelo` |
| U-VM | Registrar con lista vacía → `Fallo(0, 'No hay alumnos…')` y **0** llamadas a la conexión |
| U-VM | Registrar envía el **estado actual** tras varias marcas y desmarcas del mismo alumno |
| U-Repo | Errores de la conexión pasan sin cambios (`same(...)`) en listar y registrar |
| U-Con | GET: URI exacta, 200 lista → modelos, 200 no-lista → 406, `DioException` 404/500 → código, `connectionError` → 503 |
| U-Con | POST: cuerpo JSON exacto según el contrato (3.5) y `?idclase=` correcto |
| U-Modelo | `Atencionmodelo` y `Alumnomodelo`: `fromJson(toJson(x))` conserva todos los campos (ida y vuelta) |
| U-Vista | Error de carga → se pinta el texto del error |
| U-Vista | Lista vacía → "¡No hay alumnos aún!" |
| U-Vista | Registro fallido → `DialogError` con el código y la pantalla **no** se cierra |
| U-Vista | Registro exitoso → diálogo y luego `pop` |

**c) Diagnóstico (`test/diagnostico/atenciones/`, se esperan en rojo)**

| Hipótesis | Prueba |
|---|---|
| AS-01 | U-Vista: con sesión de alumno (y sin sesión), la lista de clases no permite abrir la clase, o `Claseview` no muestra "Guardar" |
| AS-02 | U-Vista: dos toques seguidos a "Guardar" con la respuesta retenida (`Completer` en el doble) → `llamadasRegistrar == 1` |
| AS-03 | U-Vista: tras una carga fallida, "Guardar" está deshabilitado o el mensaje es el del error de carga |
| AS-04 | U-Con: categoría `"Fútbol & Voleibol"` → la URI enviada lleva los parámetros codificados y `curso` intacto |
| AS-05 | U-Repo / U-Con: el JSON enviado conserva `codigo`, `imagen` y `eliminadoestado` del alumno cargado |
| AS-06 | U-Con: 200 con `estaAtendido: null` → `RespuestaModelo` de error, **sin** excepción |
| AS-07 | U-Con + U-VM: POST con 201 o 204 → `Exito` |
| AS-08 | U-Repo: atención con `idClase` distinto del parámetro → se rechaza antes de la red |
| AS-09 | U-VM: tras un registro fallido, el VM indica que hay cambios sin guardar |
| AS-12 | U-Con: `receiveTimeout` → 408 |

AS-10, AS-11 y AS-13 esperan la respuesta del cliente (3.4) antes de escribirse.

**d) Integración**

| Nivel | Caso |
|---|---|
| I-Local | Recorrido completo `Claseview` → `GET` → marcar dos de tres → `POST`, con las peticiones afirmadas en el adaptador según el contrato |
| I-Local | Doble toque a "Guardar" (AS-02) y POST con 201 (AS-07) de punta a punta |
| I-Local | Navegación con rol: `GruposAsignados` (instructor) → grupo → clase permitido; `CursosView` → grupo → clase con alumno o sin sesión, según la regla del cliente (AS-01) |
| I-Remota | *Cuando existan los endpoints*: preparar grupo + clase + 2 alumnos inscritos en `setUpAll` (patrón de `VmGruposInscripcionTest`) → listar → registrar → **volver a abrir** y comprobar las marcas guardadas → registrar otra vez (¿duplica?) → leer en estadísticas que la asistencia cuenta |

### 3.7 Criterio de terminado del módulo

> **Estado al 2026-10-29:** fases 0 a 6 cerradas. Se confirmaron por prueba 10 fallos de la app, todos de severidad media o baja por lo probado; 4 de ellos pueden ser graves según el backend. AS-B01 se confirmó contra el backend. 4 hipótesis esperan al cliente y 1 quedó descartada. El informe separa lo confirmado (parte A) de lo inferido (parte B). La fase 7 está bloqueada por AS-B01. AS-01 y O-01 se aplazan al módulo de autenticación y roles, que pasa al final.
> Ver [informe-diagnostico-asistencias.md](informe-diagnostico-asistencias.md) y [registro-bugs.md](registro-bugs.md).
> Faltan dos pasos de esta lista: enviar el contrato y las preguntas.

- Infraestructura transversal (2.1–2.3) en el repositorio.
- Saneamiento (3.6.a) hecho y `test/unitarias` en verde.
- Cada AS-xx tiene una prueba y un estado en `registro-bugs.md`. Las que dependen del cliente o del backend quedan con su responsable.
- Contrato (3.5) enviado al backend y preguntas (3.4) enviadas al cliente.
- `flutter analyze` sin warnings nuevos (línea base: 31).

### 3.8 Ejecución paso a paso

Cada fase termina con algo que se puede revisar. No se pasa a la siguiente sin cumplir su criterio de salida.

#### Fase 0: Línea base y comprobaciones (sin escribir código)

| Paso | Acción | Salida |
|---|---|---|
| 0.1 | Levantar el backend y consultar `http://localhost:8082/v3/api-docs` buscando `atencion` | Se confirma o descarta el bloqueo de los endpoints |
| 0.2 | `flutter test test/unitarias test/raiz_composicion_test.dart` | 82 en verde (línea base) |
| 0.3 | `flutter analyze` | 0 errores y 31 warnings (línea base) |
| 0.4 | Revisar el cambio sin commit en `test/dobles/conexionautenticacionFalsa.dart` | Saber si sirve para montar sesiones por rol (AS-01) |

**Criterio de salida:** líneas base anotadas en el registro.

#### Fase 1: Infraestructura transversal

| Paso | Archivo | Contenido |
|---|---|---|
| 1.1 | `test/dobles/adaptadorHttpFalso.dart` | `HttpClientAdapter` programable con:<br>• `responder(metodo, ruta, codigo, cuerpo)`<br>• `fallar(metodo, ruta, DioExceptionType)`<br>• `retener(metodo, ruta)` → `Completer`, para AS-02<br>• `peticiones`: lista de método, URI y cuerpo JSON decodificado<br>• `crearDioFalso()`: usa `crearClienteHttp('http://falso/api/v2')` y le asigna el adaptador |
| 1.2 | `dart_test.yaml` | `tags: diagnostico:` (evita el aviso de etiqueta no declarada) |
| 1.3 | `test/contratos/atenciones/` | `listar_200.json`, `listar_vacia.json`, `registrar_peticion.json` y `test/contratos/leerContrato.dart` (lee con ruta relativa a la raíz, como `assets/images/1.jpg`) |
| 1.4 | `ConexionatencionesFalsa` | Respuestas por defecto tomadas de `listar_200.json`, más un gancho `antesDeRegistrar` (como `antesDeResponder` en estadísticas) |
| 1.5 | `auditoria-mvvm/registro-bugs.md` | Filas AS-01 … AS-14 en estado *hipótesis* |

**Criterio de salida:** una prueba de humo del adaptador (GET → 200 → `peticiones.length == 1`) en verde, y las 82 siguen en verde.

#### Fase 2: Saneamiento de pruebas existentes

| Paso | Prueba | Cambio |
|---|---|---|
| 2.1 | E-12 `prueba4BackendSinEndpoint` | Renombrar a `... - BUG AS-B01 - backend sin endpoints (fija el 404)` |
| 2.2 | E-02 (repo, registrar) | Afirmar `codigo`, `imagen` y `eliminadoestado` del alumno enviado. Si sale rojo, se mueve a diagnóstico como AS-05 y en su lugar queda la versión actual |
| 2.3 | E-01, E-03, E-07 | Usar `listar_200.json` en vez de modelos armados a mano |

**Criterio de salida:** `test/unitarias` en verde; ninguna prueba existente afirma algo que solo el doble garantiza.

#### Fase 3: Unitarias nuevas (se espera verde)

Archivos nuevos: `test/unitarias/conexion/conexionAtencionesRemoto_test.dart` y `test/unitarias/modelo/atencionModelo_test.dart`. Los demás casos se agregan a los archivos existentes de repo, VM y vista.

| Archivo | Casos (nombre `'$capa - unitaria - $metodo - $caso'`) |
|---|---|
| conexión | GET URI exacta · GET 200 lista → modelos · GET 200 objeto → 406 · GET 404/500 → código y mensaje · GET `connectionError` → 503 · POST cuerpo = `registrar_peticion.json` · POST `?idclase=210` |
| modelo | `Atencionmodelo` ida y vuelta conserva `idClase` y `estaAtendido` · `Alumnomodelo` ida y vuelta conserva `id`, `nombre`, `correo` |
| repositorio | Listar con error → `same(respuesta)` · Registrar con error → `same(respuesta)` |
| viewModel | Cargar 404 / 500 / 503 → `error` contiene el código, `cargando == false`, lista vacía · Cargar `200 []` → sin error · Registrar 400/500 → `Fallo` con código y mensaje · Registrar con lista vacía → `Fallo(0)` y `llamadasRegistrar == 0` · Marcar, desmarcar y marcar → se envía `true` |
| vista | Error de carga → texto del error · Lista vacía → "¡No hay alumnos aún!" · Registro fallido → `DialogError` y la pantalla sigue (`find.byType(Claseview)`) · Registro exitoso → diálogo y luego `pop` |

Unos 22 casos. **Criterio de salida:** todos en verde. Un caso que salga rojo es un hallazgo nuevo: se registra y su prueba se mueve a diagnóstico.

#### Fase 4: Diagnóstico (se espera rojo)

Archivos: `test/diagnostico/atenciones/{conexion,repositorio,viewModel,vista}_diagnostico_test.dart`, todos con `tags: ['diagnostico']`.

| ID | Archivo | Preparar | Actuar | Afirmar (comportamiento correcto) |
|---|---|---|---|---|
| AS-01a | vista | Montar la pantalla del grupo (como `grupoView_test`) con sesión de **alumno** | — | No aparecen "AGREGAR CLASE" ni eliminar; tocar una clase no abre `Claseview` |
| AS-01b | vista | Igual, **sin sesión** | — | Ídem |
| AS-01c | vista | Sesión de instructor con id ≠ `grupo.idInstructor` | — | No permite registrar (según la regla de la pregunta 3.4-1) |
| AS-02 | vista | `antesDeRegistrar` retenido | Dos toques a "Guardar" y después liberar | `llamadasRegistrar == 1`; botón deshabilitado o indicador de carga visible |
| AS-03 | vista | Carga con 500 | Tocar "Guardar" | Botón deshabilitado, o el diálogo muestra el error de carga y no "No hay alumnos" |
| AS-04 | conexión | Categoría `"Fútbol & Voleibol"`, curso `"Nivel 1"` | `obtenerAtencionesClase` | `uri.queryParameters['categoria'] == 'Fútbol & Voleibol'` y `['curso'] == 'Nivel 1'` |
| AS-05 | conexión | GET devuelve un alumno con `codigo`, `imagen` y `eliminadoestado: 1` | Cargar → registrar (I-Local en pequeño) | El JSON del POST conserva los tres valores |
| AS-06 | conexión | GET 200 con `estaAtendido: null` | `obtenerAtencionesClase` | Devuelve `RespuestaModelo` de error y **no lanza** (`returnsNormally`) |
| AS-07a | conexión | POST responde 201 | `registrarAtencionesClase` | `codigoHttp` de éxito |
| AS-07b | viewModel | Doble responde 201 / 204 | `registrarAtenciones` | `isA<Exito>()` |
| AS-08 | repositorio | Atención con `idClase: 999` y parámetro `210` | `registrarAtencionesClase` | Error local y `llamadasRegistrar == 0` |
| AS-09 | viewModel | Registro con 500 | `marcarAsistencia` → `registrarAtenciones` | El VM expone que hay cambios sin guardar (p. ej. `hayCambiosSinGuardar == true`) |
| AS-12 | conexión | `receiveTimeout` | Cualquier método | `codigoHttp == 408` |
| AS-14 | vista | `clasesGrupo` con una clase de `fecha: null` | Montar la pantalla del grupo | No hay excepción (`tester.takeException()` es `null`) y se pintan las demás clases |

Si una prueba afirma algo que hoy no existe (p. ej. `hayCambiosSinGuardar` en AS-09), se escribe contra la interfaz propuesta y queda roja por compilación. En ese caso se marca con `skip: 'AS-09: requiere API nueva'` y se documenta, para no romper la carpeta.

**Criterio de salida:** `flutter test test/diagnostico` ejecutado y la salida guardada; cada AS-xx pasa a *confirmado* (rojo) o *descartado* (verde).

#### Fase 5: Integración local (sin backend)

Archivo `test/integracion/atenciones_integracion_test.dart`. Cadena real: `Atencionviewmodel(Servicioatencion(Atencionesrepositorio(conexion: Conexionatencionesremoto(dioFalso))))` montada en `Claseview`.

| Caso | Se afirma |
|---|---|
| Flujo completo: 3 alumnos, marcar 2, guardar | Secuencia `GET /atencionesporclase` → `POST /atenciones?idclase=210`; cuerpo = `[true, true, false]`; diálogo de éxito |
| POST con 201 (AS-07) | El usuario ve éxito |
| Doble toque (AS-02) | Un solo POST en `peticiones` |
| Sin red al guardar | `DialogError` con 503; la pantalla no se cierra; las marcas siguen |
| Navegación por rol (AS-01) | `GruposAsignados` (instructor) → grupo → clase llega a `Claseview`; con alumno no llega |

**Criterio de salida:** casos ejecutados; los rojos quedan en el registro con su ID.

#### Fase 6: Cierre del diagnóstico y entregables

| Paso | Entregable | Para quién |
|---|---|---|
| 6.1 | `registro-bugs.md` completo: estado, evidencia (nombre de la prueba y mensaje del fallo), severidad y responsable | Equipo |
| 6.2 | Resumen: confirmados por severidad y propuesta de orden de corrección (A primero) | Equipo / docente |
| 6.3 | Contrato `test/contratos/atenciones/` y lista AS-C-xx | Backend |
| 6.4 | Preguntas 3.4 con las hipótesis que dependen de ellas | Cliente |

#### Fase 7: Remota (bloqueada hasta que existan los endpoints)

`test/remoto/viewModel/atencion/vmAtencionTest.dart`: reemplazar E-12 por el ciclo de 3.6.d (preparar en `setUpAll` → listar → registrar → reabrir → registrar otra vez → estadísticas) y registrarlo en `main_test.dart`.

#### Resumen de volumen

| Fase | Pruebas nuevas o modificadas | Resultado esperado |
|---|---|---|
| 1 | 1 de humo | verde |
| 2 | 4 modificadas | verde (E-02 puede pasar a diagnóstico) |
| 3 | ~22 | verde |
| 4 | ~15 | rojo = bug confirmado |
| 5 | 5 | mixto |
| 7 | ~5 (bloqueadas) | — |

---

## 4. Módulos siguientes (orden por valor para el cliente)

Primero lo que la toma de asistencias **necesita** para funcionar; después, lo que **consume** su resultado; al final, la administración del catálogo. En cada módulo se repite el ciclo: **auditar pruebas (D1–D7) → hipótesis leyendo el código → saneamiento → unitarias → diagnóstico → integración → registro**.

| # | Módulo | Por qué en este lugar | Foco inicial |
|---|---|---|---|
| 2 | **Clases (crear, listar, eliminar)** | Sin clase no hay asistencia | `DELETE /clase` responde 200 pero no borra (prueba remota D4 → registrar como bug del backend); fechas y zona horaria, y `Clasemodelo.fromJson` con `fecha` nula (viene de AS-14); clase sin código (relacionado con E-10). |
| 3 | **Grupo: detalle y alumnos del grupo** | Es la lista de alumnos a los que se toma asistencia | 406 de `GC-0002` tratado como lista vacía; ¿coincide la lista del grupo con la de atenciones?; claves compuestas sin codificar (como AS-04). |
| 4 | **Inscripciones** | Define quién está en el grupo | Cupos llenos, inscripción duplicada, desinscribir; usa `cargarCategorias(context)`, de estilo antiguo (CAT-04/05). El alumno solo ve aquí los cursos a los que puede inscribirse. **Ya hay hallazgos anticipados IN-01 a IN-07 en `registro-bugs.md`**, todos de lectura del código salvo IN-04: las pantallas del coordinador para abrir, cerrar y programar inscripciones son maquetas (lista de grupos ficticia, botones sin acción); no hay endpoints para ello; los cursos no tienen fechas; `fechaFinalizacion` del grupo no se envía; `validarInscripcion` manda cuerpo en un GET. Al llegar al módulo, escribir sus pruebas y preguntar al cliente dónde van las fechas de inscripción (curso, grupo o categoría). |
| 5 | **Estadísticas** | Consume las asistencias ("agrupa las atenciones y horas por categoría") | Decidir si "ceros en un rango sin clases" es correcto (D4); ¿cuenta una asistencia duplicada dos veces?; exportación a Excel. |
| 6 | **Horarios** | Apoyo a la programación de clases | `/horarios` con `200 []` frente al 406 del resto. |
| 7 | **Categorías** | Catálogo; hallazgos ya hechos (anexo A) | Ejecutar el plan del anexo A. |
| 8 | **Cursos** | Catálogo; comparte la conexión de imágenes con categorías | Mismas hipótesis CAT-01 y CAT-03. |
| 9 | **Alumnos, instructores y facultades** | Cobertura casi nula, poco valor directo | Ruta crítica de listar y registrar. |
| 10 | **Autenticación y roles** (**al final, por decisión del 2026-10-29**; autenticación diagnosticada el 2026-11-05 sin backend: AU-01 a AU-10 y AU-B01, ver [plan-diagnostico-autenticacion.md](plan-diagnostico-autenticacion.md)) | Se trata después de corregir los demás hallazgos. Recoge lo aplazado: AS-01, AS-01c, O-01 y T-04/CAT-12 | Comprobar el rol en pantallas y rutas (no solo en el menú lateral). O-01 ya está explicado: `cursos.dart:184` solo deja tocar un curso al coordinador. Falta decidir con el cliente si alumno e instructor ven el detalle del curso, y mostrar que la tarjeta no es navegable. Login 404 → registro; ¿`perfilSesion` notifica? (T-04); rol nulo o desconocido; cierre de sesión. |

---

## Anexo A: Hallazgos de categorías (versión 1 del plan, se conservan)

**Pruebas hechas para pasar**

| # | Prueba | Señal | Detalle |
|---|---|---|---|
| T-01 | [categoriaViewModel_test.dart:47](../test/unitarias/viewModel/categoriaViewModel_test.dart) | D1, D3 | Inserta con `idImagen` y sin `imagenFile`; la conexión real hace `imagenFile!` y revienta. Además se salta `guardarCategoria`. |
| T-02 | [categoriaRepositorio_test.dart:57](../test/unitarias/repositorio/categoriaRepositorio_test.dart) | D1, D2 | Mismo camino imposible; el `idImagen` afirmado viene de la respuesta programada del doble. |
| T-03 | [conexionCategoriaFalsa.dart:35](../test/dobles/conexionCategoriaFalsa.dart) | D1 | El doble acepta `imagenFile == null`. |
| T-04 | [categoriasView_test.dart:97](../test/unitarias/vista/categoriasView_test.dart) | D5 | `notifyListeners()` manual tras cambiar `perfilSesion`. |
| T-05/06 | Módulo completo | D6, D7 | Sin ramas de error; la conexión sin pruebas. |

**Hipótesis de bugs**

| ID | Hipótesis | Sev. |
|---|---|---|
| CAT-01 | Insertar con `idImagen` y sin archivo → `TypeError` que escapa entre capas | A |
| CAT-02 | POST 201 o PUT 200 sin cuerpo → el repo lo cambia a 204 → el VM devuelve `Fallo` aunque se guardó | M |
| CAT-03 | Título sin codificar en `?titulo=` (PUT y DELETE) → afecta a otra categoría o a ninguna | A |
| CAT-04 | `CategoriaViewModel` sin `NotificacionSegura` → notifica después de `dispose` | M |
| CAT-05 | `cargarCategorias(context)`: sin `cargando`, `codigo: 204` en todos los errores, 204 mostrado como error | M |
| CAT-06 | `categoriaModelo.fromJson` incompleto → `TypeError` no capturado | M |
| CAT-07 | `ErrorModelo.mensaje` (`String`) recibe `response.data` (puede ser un `Map`) | B |
| CAT-08 | `receiveTimeout` → código 0 en vez de 408 | B |
| CAT-09 | Cargas concurrentes sin contador → puede pintarse una respuesta vieja | B |
| CAT-10 | El botón "quitar imagen" del formulario nunca se agrega al `Stack` | B |
| CAT-11 | `route_generator.dart:29` importa `views/Categorias/` (la carpeta es `categorias`) → no compila en Linux | M |
| CAT-12 | `perfilSesion` asignado sin notificar → la UI de coordinador no aparece al iniciar sesión | M |

**Otros módulos:** `DELETE /clase` responde 200 sin borrar (D4) y los ceros de estadísticas (D4, por decidir) se tratan en los módulos 3 y 6.
