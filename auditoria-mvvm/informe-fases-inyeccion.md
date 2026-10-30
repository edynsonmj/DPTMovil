# Informe por fase: refactorización a inyección de dependencias

Rama `refactor/inyeccion-dependencias`, del 2026-10-20 (`2b3aa28`) al 2026-10-23 (`f2141e5`).
Fuentes: mensajes de los 22 commits, `plan-inyeccion-dependencias.md`, las notas de cada
checklist manual y las sesiones de trabajo de cada fase.

## Cómo leer este informe

Cada módulo siguió el mismo protocolo:

1. **Caracterización (commit "Na")**: antes de tocar `lib/`, tests que fijan lo que el código
   hace hoy en sus rutas críticas — repositorio con un doble (sin backend) y ViewModel contra el
   backend real. `lib/` sin cambios.
2. **Refactor (commit "Nb", a veces "Nc")**: conexión recibe `Dio` → servicio recibe
   repositorio → VM recibe servicio → registro en la raíz → VM por ruta. Los tests de
   caracterización deben pasar **sin tocar sus asserts**.
3. **Verificación**: tests nuevos comprobados contra un fallo inyectado, `flutter analyze` sin
   errores y con warnings que no suban, checklist manual en el emulador.

### Por qué la caracterización tuvo dos capas

Al inicio solo se podían escribir dos tipos de prueba sobre el código sin migrar:

| Capa | Cómo se armaba antes del refactor | Sin backend |
|---|---|---|
| Repositorio | Su constructor ya recibía la conexión (`cliente:`): se le pasa un doble programable | Sí |
| ViewModel | La fábrica en `SERVICIO_REMOTO` + `ConfigServicio.ip = "localhost"` → backend real | No |

El VM no admitía un doble porque construía sus dependencias por dentro. En la línea base
(`2b3aa28`), `CategoriaViewModel()` creaba `ServicioCategoria()`, y este pedía la conexión a
`ConexionFabricaAbstracta.obtenerConexionFabrica()`. Sin parámetros en el constructor, el test no
tenía por dónde meter `ConexionCategoriaFalsa`.

Existía una tercera vía, el **modo local de la fábrica** (`SERVICIO_LOCAL`, conexiones en memoria
de `lib/data/api/conexion/local/`), pero no servía como red de caracterización:

- **Datos fijos**: no se le puede pedir un 406 o un 400; solo cubre el camino feliz sembrado.
- **No registra llamadas**: no hay `llamadasX` ni `ultimoX`, así que no se puede comprobar, por
  ejemplo, que el VM refrescó la lista.
- **Configuración global y orden**: el modo se elige con la estática
  `ConfigServicio.tipoFabricaServicio`, que cada VM lee al construirse; `main_test.dart` tenía que
  correr el grupo local antes de cambiar a remoto.
- **Cobertura mínima**: solo categorías tenía un test local de VM (listar). Clase, atención y
  grupo no tenían conexión local usable.
- **Desaparecía con el refactor**: quitar la fábrica y el modo local era el objetivo; una red
  apoyada en ellos se habría caído con el propio cambio.

Por eso cada commit "Na" trae las dos capas posibles: **repositorio con doble** (conversión
modelo → entidad, errores sin cambios) y **VM remoto** (estado de la pantalla por la ruta
completa `ViewModel → Servicio → Repositorio → Conexion → backend`). El remoto era el único que
podía armar el VM de cualquier forma —con la fábrica antes, con `crearVm` después— sin cambiar sus
asserts.

Los **unitarios de VM con doble** y los **widget tests** no son de caracterización: solo fueron
posibles cuando el VM pasó a recibir su servicio por constructor, así que se escribieron en los
commits "Nb"/"Nc". No prueban que se conservó el comportamiento anterior, sino el diseño nuevo, y
por eso se validaron contra un fallo inyectado (por ejemplo, quitar el refresco tras guardar).

| | Repositorio con doble | VM con doble | VM remoto |
|---|---|---|---|
| Cadena armada | Solo `CategoriaRepositorio(cliente: doble)` | `VM(Servicio(Repositorio(cliente: doble)))` | `VM(Servicio(Repositorio(Conexion(Dio))))` |
| Comprueba | Conversión y errores que pasan intactos | Estado del VM, refresco, `Resultado`, no notificar tras `dispose` | Estado del VM contra el backend real |
| Backend | No | No | Sí |
| Momento | Antes del refactor ("Na") | Después ("Nb"/"Nc") | Antes ("Na"), y después solo cambia `crearVm` |
| Papel | Caracterización | Verificación del diseño nuevo | Caracterización |

Para cada fase se distinguen:

- **Hallazgos**: lo que la caracterización (o el checklist) descubrió del código o del backend.
- **Tratados**: los que se corrigieron dentro de la fase.
- **Fuera de alcance**: los que se dejaron, con el motivo, para retomarlos después.
- **Regresiones**: si algo que funcionaba antes de la fase dejó de funcionar después. Se separan
  tres cosas que no son lo mismo: regresión real, **riesgo de regresión evitado** (se vio antes
  del commit y se previno) y **cambio de comportamiento a propósito** (decisión aprobada, con los
  asserts que cambiaron declarados en el commit).

## Resumen

| Fase | Commits | Tests de caracterización | Hallazgos | Tratados | Fuera de alcance | Regresiones |
|---|---|---|---|---|---|---|
| 0 Infraestructura | `81936a1` `a3bd8fb` `a274aeb` | 4 de repositorio de categorías | 4 | 4 | 1 | Ninguna; 1 riesgo evitado |
| 1 Imagen + Categoría | `f641608` | (los de 0.4 + 24 remotos previos) | 4 | 3 | 7 huecos de casos especiales | Ninguna; 2 riesgos evitados |
| 2 Autenticación + Facultades | `c8329a2` `120493b` | 4 repo + 3 remotos | 3 | 2 | 1 bug (`registro`) | Ninguna |
| 3 Cursos + Deporte | `3240a29` `29292fc` | 4 repo + 4 remotos | 4 | 3 | 1 (zona horaria) | Ninguna; 1 reporte descartado |
| 4 Grupo | `d928e85` `f8b705a` `f5a347d` | 8 repo + 6 remotos | 6 | 4 | 2 (backend) | Ninguna; 1 riesgo evitado; asserts movidos (4c) |
| 5 Atención | `d4f2985` `9c11f17` | 2 repo + 1 remoto | 2 | 1 | 2 (H1, H3) | Ninguna |
| 6 Grupos asignados + Inscripción | `e64061a` `30995b5` `cd1d6ce` | 3 repo + 3 remotos | 6 | 4 | 2 (backend/maquetas) | Ninguna; 3 reportes descartados; asserts cambiados (6b, 6c) |
| 7 Estadísticas | `7fd508b` `cae2b34` `374bfd2` | 3 repo + 4 remotos | 6 | 4 | 2 (K3, permisos) | Ninguna; asserts cambiados (7c) |
| 8 Limpieza | `62f8532` `f2141e5` | (sin caracterización: solo código sin llamadores) | 2 | 2 | restos conservados | Ninguna |

**Ninguna fase cerró con una regresión.** Todas terminaron con la suite completa en verde y el
checklist manual pasado; los reportes del checklist que parecían fallos se investigaron y
resultaron ser comportamiento previo, del backend o del entorno (ver la recopilación final).

Evolución de las métricas:

| | Línea base | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 |
|---|---|---|---|---|---|---|---|---|---|
| Tests | 35 | 43 | 54 | 65 | 92 | 101 | 123 | 139 | 139 |
| Sin backend | — | — | — | — | 43 | 51 | 70 | 82 | 82 |
| Warnings | 113 | 100 | 99 | 95 | 83 | 83 | 76 | 73 | **31** |
| Infos | 321 | 317 | 326 | 332 | 329 | 333 | 337 | 332 | **301** |
| VMs globales | 12 | 10 | 9 | 8 | 5 | 5 | 2 | 1 | 1 |
| Métodos en la fábrica | 11 | 10 | 9 | 6 | 2 | 1 | 1 | 0 | 0 |

Errores de `flutter analyze`: 0 en todas las fases. Los warnings nunca subieron entre fases.

---

## Fase 0 — Infraestructura

**Qué se hizo.** `ConfigApi` como única URL (`--dart-define=API_HOST`), `Dio` compartido en la
raíz, arranque directo en categorías, `dependencias.dart` con `proveedoresDatos()` y
`vmsGlobales()`, test de humo de la raíz, primer doble y tests de repositorio.

**Caracterización (0.4).** `ConexionCategoriaFalsa` (convención `<Interfaz>Falsa`) y 4 tests de
`CategoriaRepositorio`: listar 200 y 204, guardar 201, actualizar 200 con `imagenId`. Verificados
contra el mapeo de `idImagen` roto a propósito. La red remota de categorías (24 casos) ya venía
del commit de línea base.

**Hallazgos**

1. Deporte y Facultad leían `ConfigServicio.ip` directamente: sin pasar por `page1` quedaba en
   `null` y la URL salía mal.
2. Arrancar en `/categorias` con `initialRoute` apilaba `/` debajo.
3. `Imagenviewmodel` no lo leía ninguna pantalla; sus 2 tests estaban inactivos.
4. Con `Imagenviewmodel` fuera, `Servicioimagen`/`Imagenrepositorio` quedaban sin consumidores.

**Tratados.** 1: ambos pasan por `obtenerBaseApi()`, que delega en `ConfigApi`. 2:
`onGenerateInitialRoutes`. 3: eliminado con sus tests. 4: decidido en las fases 1 y 3 (se
conserva y se registra en la raíz).

**Fuera de alcance.** `ConexionCategoriaLocal` seguía en `lib/` (la usaba la fábrica local): se
movió en la fase 1.

**Regresiones.** Ninguna (35 → 40 tests, probado en el emulador).
*Riesgo evitado*: el hallazgo 1 habría dejado sin datos deportes y facultades en cuanto la app
dejara de pasar por `page1`; se corrigió en el mismo paso 0.2 que cambia el arranque.

---

## Fase 1 — Imagen + Categoría

**Qué se hizo.** `crearClienteHttp()` con 20 s; `Conexionimagenremoto([Dio?])` con respaldo
temporal (30 s por petición); `ConexionCategoriaRemota(Dio, Conexionimagen)`;
`ServicioCategoria(repositorio)`; `CategoriaViewModel(servicio)` por ruta.

**Caracterización.** Los 4 de repositorio de la fase 0.4 y los 24 remotos de categorías ya
existentes. Tras el refactor solo cambió `crearCategoriaViewModel(conexion)`: **mismos asserts**.
Se agregaron 3 unitarios de VM (listar, guardar y eliminar refrescan la lista), verificados
contra el refresco quitado.

**Hallazgos**

1. `CategoriaViewModel` también lo usaban `inscripcionesGenerales` e `inscripcionesParticulares`
   y el `default` del router.
2. Con el VM por ruta, el formulario de edición ya no comparte instancia con la lista.
3. `ConexionCategoriaLocal` ya no la creaba la app, pero sí los tests locales.
4. Revisión de cobertura de categorías (2026-10-20): **7 huecos de casos especiales** (abajo).

**Tratados.** 1: VM por ruta también en esas tres rutas. 2: `CategoriasView` recarga cuando el
formulario vuelve con `true`. 3: movida a `test/dobles/` con `git mv`.

**Fuera de alcance** (decisión: solo rutas críticas hasta que la app se estabilice):

1. **Títulos con `&` o `#`**: `ConexionCategoriaRemota.dart:85` y `:186` arman
   `?titulo=...` sin codificar. Bug real, sigue presente. El mismo patrón está en cursos,
   grupos, clases, horarios, alumnos y atenciones. Arreglo propuesto:
   `Uri.encodeQueryComponent` (o `queryParameters` de Dio).
2. Título duplicado al crear (respuesta del backend desconocida).
3. Eliminar una categoría con cursos asociados (clave foránea).
4. Rama de error de `listarYNotificarCategorias` y `cargando == true` en vuelo.
5. `cargarCategorias(context)` sin test (lo usan las vistas de inscripciones).
6. `ConexionCategoriaLocal.actualizarCategoria` con título inexistente lanza
   `LateInitializationError` en vez de devolver 404.
7. Sin `integration_test/` (los widget tests llegaron desde la fase 2).

**Regresiones.** Ninguna (43/43, checklist pasado).
*Riesgos evitados*: sin el hallazgo 1, sacar el VM de la raíz daba `ProviderNotFoundException`
al abrir las pantallas de inscripciones (el test de humo no lo cubre porque es un provider de
ruta, no de raíz); sin el hallazgo 2, la lista no se habría actualizado tras editar.

---

## Fase 2 — Autenticación + Facultades

**Caracterización (2a).** Dobles `ConexionautenticacionFalsa` y `ConexionfacultadesFalsa`; repo:
login 200 con rol, login 404 sin cambios, registro 201, facultades 200 → nombres. Remotos:
`VmListarFacultadesTest` y `VmLoginTest` (correo no registrado → 404; sin correo no llega a la
red). Primer uso del patrón `crearVm`.

**Hallazgos**

1. El backend confirma 404 para correo no registrado (la app lo usa para mandar al registro).
2. `crearConexionAutenticacion` de las fábricas solo lanzaba `UnimplementedError`.
3. **`Conexionautenticacionremoto.registro` no retorna** en el `if (statusCode != 201)`
   (`ConexionAutenticacionRemoto.dart:59-61`): crea la respuesta de error y la descarta, y
   sigue parseando el cuerpo como perfil.

**Tratados.** 2: eliminada. Además: auth pide 1 min por petición (lo que ya tenía), facultad
pasa de sin timeout a los 20 s compartidos, `GoogleSignIn` se inyecta (doble
`GoogleSignInFalso`), primer widget test (`CategoriasView`: solo el coordinador ve "Agregar
categoria").

**Fuera de alcance.** Hallazgo 3: visto y **no corregido** (sigue en el código). El equivalente
en cursos sí se corrigió en la fase 3.

**Regresiones.** Ninguna: los 3 remotos del 2a pasaron sin cambiar asserts (54/54, checklist
pasado). Fallos inyectados detectados (notificación del login, rol del botón).

---

## Fase 3 — Cursos + Deporte (+ Imagen)

**Caracterización (3a).** `ConexionCursoFalsa`; repo: listar 200/406, guardar 201, obtener 200.
Remotos: deportes 200, y sobre una categoría `prueba_*` creada en `setUpAll`: agregar curso 201,
listar de categoría, obtener 200. Fallo inyectado (imagen `null` en `CursoEntidad.fromModelo`)
detectado por 5 casos.

**Hallazgos**

1. `ConexionCursoRemoto.agregarCurso` no retornaba en el `if != 201` (mismo bug que en
   autenticación).
2. Tres URLs de imagen (`imagenStream`) se armaban a mano en widgets (`Tarjeta`,
   `EncabezadoImagen`, `FormularioCurso`).
3. `servicioCurso` importaba la vista `grupo.dart`.
4. Checklist: crear grupo de noche fallaba con "fechaCreacion no puede ser periodo futuro".

**Tratados.** 1: `return` agregado (D1). 2: `urlImagen` baja desde la conexión hasta el VM
(D3); `Tarjeta` y `EncabezadoImagen` con respaldo temporal que se quitó en las fases 6 y 4.
3: import quitado. Además `Servicioimagen(repo)` en la raíz y `Conexionimagenremoto(Dio)`
obligatorio (D2).

**Fuera de alcance.** Hallazgo 4: no es del código migrado; `GrupoFormulario` usa la fecha del
dispositivo y el emulador estaba en GMT. El arreglo de fondo (que el backend asigne la fecha o
calcularla en hora de Bogotá) quedó aplazado.

**Regresiones.** Ninguna (65/65, checklist pasado). *Reporte descartado*: el hallazgo 4 se
confirmó como zona horaria del emulador, no como regresión.

---

## Fase 4 — Grupo (+ Horarios, Alumnos, Instructores, Clases)

**Caracterización (4a).** 5 dobles, 8 tests de repo (grupos 200/406 e insertar, clases listar y
agregar, horarios, alumnos e instructores). Remotos sobre un grupo real creado en la prueba:
instructores, insertar grupo 201, horarios y alumnos de grupo nuevo, registrar clase 201 (el caso
de éxito pendiente desde septiembre) y eliminar clase 200.

**Hallazgos**

1. Listas vacías no uniformes: `/horarios` → `200 []`; `/alumnosGrupo` y `/clasesGrupo` → 200
   con objeto `GC-0002` que la conexión convierte en 406.
2. **`DELETE /clase?id=X` responde 200 pero no borra** (la clase sigue con `eliminado: 0`).
3. `GrupoFormulario` llamaba `setState` dentro de `build`, no retornaba al faltar el
   identificador y tenía `print`s.
4. `insertarGrupo` recargaba una lista que el formulario ya no comparte.
5. La pantalla de grupo cargaba con `FutureBuilder` creados en `build` (recarga en cada
   reconstrucción) y repartía el estado en 4 VMs.
6. Botón "AGREGAR HORARIO" con `onPressed: () {}` y sin endpoint en el backend.

**Tratados.** 1: `DetalleGrupoViewModel` trata el 406 como lista vacía (las conexiones no se
tocan). 3 y 4: corregidos en 4b. 5: 4c reúne curso, horarios, alumnos y clases en
`DetalleGrupoViewModel`, carga una vez en el `create` de la ruta, `EstadoSeccion` +
`context.select`, no notifica tras `dispose`. `formularioClase` recibe el grupo y crea su propio
`Clasesviewmodel`.

**Fuera de alcance.** 2 y 6 son del backend (avisos pendientes 2 y 3). El test de eliminar solo
fija el 200; cuando se corrija, agregar que la lista quede vacía. `Alumnosviewmodel` queda sin
uso por decisión (clases sin consumidores se conservan).

**Regresiones.** Ninguna (79 → 83 → 92, checklist pasado en 4b y 4c).
*Riesgo evitado*: con `Clasesviewmodel` por ruta, volver del formulario de clase no habría
mostrado la clase nueva; la pantalla del grupo recarga al volver con `true`.
*Cambio a propósito (4c)*: `prueba5GrupoNoInicializado` perdió 2 asserts de la lista de clases,
que se mudó a `DetalleGrupoViewModel`; los casos remotos de registrar y eliminar clase pasaron a
verificar con el VM nuevo. Declarado en el commit.

---

## Fase 5 — Atención

**Caracterización (5a).** `ConexionatencionesFalsa`; repo: listar 200 (alumno anidado y
`estaAtendido`) y registrar. Remoto: `VmAtencionTest.prueba4BackendSinEndpoint`.

**Hallazgos**

1. **El backend no tiene endpoints de atenciones**: `GET /atencionesporclase` y
   `POST /atenciones` dan 404 y no aparecen en `/v3/api-docs`. Al entrar a una clase se ve
   "Código: 404".
2. `Atencionviewmodel` podía notificar después de `dispose` (salir mientras carga).

**Tratados.** 2: guarda contra notificar tras `dispose` (H4), luego unificada en
`NotificacionSegura` (8b). Carga en el `create` de la ruta `clase` (H2).

**Fuera de alcance.** H1 (caso de éxito con un alumno inscrito) y H3 (cómo llega la lista vacía)
quedan sin objeto hasta que existan los endpoints. El remoto fija el 404 a propósito: fallará
cuando el backend los agregue y habrá que reemplazarlo por listar y registrar.

**Regresiones.** Ninguna (101/101, checklist pasado; la pantalla solo puede mostrar el 404, que
ya mostraba antes). El camino de éxito se cubre con el doble.

---

## Fase 6 — Grupos asignados + Grupos de inscripción

**Caracterización (6a).** `ConexioninscripcionFalsa`; repo: agregar, eliminar y validar.
Remotos sobre un grupo y un **alumno de prueba** creados en `setUpAll`: grupos del instructor,
grupos disponibles y el ciclo validar → inscribir 201 → validar → desvincular 200 → validar. Se
comprobó que el `GET` con cuerpo de `validarInscripcion` funciona.

**Hallazgos**

1. Inscripción tenía timeouts de 10 minutos (I2).
2. Las tarjetas hacían cast de los horarios sin revisar el código: un error lanzaba excepción
   (I3).
3. Flujo "Matricular": diálogo de cargando inalcanzable y desvincular sin aviso (I4).
4. Cada tarjeta creaba `FutureBuilder` en `build` para horarios y estado de inscripción (I1).
5. Checklist 6b: un alumno no ve grupos en Inscripciones.
6. Checklist 6c: "Agregar horario" no hace nada y entrar a una clase da 404.

**Tratados.** 1: 20 s del cliente compartido. 2: se revisa el código antes de pintar. 3:
inscribir y desvincular devuelven `Resultado` y la vista espera el diálogo de éxito o error.
4: 6c guarda horarios y estado por grupo (`Grupoentidad.clave`), carga una vez en `initState`,
tras inscribir revalida solo ese grupo y deshabilita su botón mientras procesa. `Tarjeta`
pierde `idImagen` y el último respaldo con `ConfigServicio`.

**Fuera de alcance.** 5: `/gruposInscripcion` devuelve solo grupos con la fecha de hoy dentro de
su rango de inscripción, ese rango solo se fija al crear el grupo (no hay `PUT /grupo`) y la app
no lo envía; los botones "Abrir/Cerrar/Programar" son `TODO` (aviso 4 al backend). Para el
checklist se creó el grupo `curso_20261023012143953553`, abierto del 22 al 30 de octubre. 6:
avisos 1 y 2 al backend. Las pantallas de inscripciones generales/particulares son maquetas y
quedaron fuera de la fase.

**Regresiones.** Ninguna (107 → 115 → 123, checklist pasado). *Reportes descartados*: 5 y 6 son
comportamiento que ya existía antes de la fase (botones `TODO`, `onPressed` vacío) o faltas del
backend.
*Cambios a propósito*: 6b cambió los asserts del ciclo remoto (leía `vm.cargando`, `vm.error`,
`vm.codigoInsercion == 201`; ahora espera `Exito`, mismos códigos); 6c cambió 2 unitarios del 6b
que contaban notificaciones exactas por comprobaciones del estado del grupo. Ambos declarados.
*Cambio de comportamiento sin test*: una petición de inscripción que antes esperaba hasta 10 min
ahora corta a los 20 s.

---

## Fase 7 — Estadísticas

**Caracterización (7a).** `ConexionEstadisticasFalsa`; repo: grupos 200 → entidades, 200 sin
lista → código 0, 400 sin cambios. Remotos: categorías 200, grupos 200 (para exportar), rango
sin clases, fecha mal formada.

**Hallazgos**

1. **Un rango sin clases no da lista vacía**: llegan todas las categorías con `0.0` (K4).
2. Fecha vacía o mal formada → 400, y la pantalla se ponía roja (`FutureBuilder` + cast sin
   revisar).
3. El repositorio ponía una ruta equivocada en el error de cada sección (L2).
4. `GraficoBarrasAgrupado` tenía un `Expanded` cuyo padre no era un `Flex`.
5. `institucionalFacultades/Programas` lanzan `UnimplementedError`; la app no usa
   `/estadisticas/alumnos` ni `/instructores`.
6. `guardarArchivoExcel` pide `Permission.storage`, que Android 13+ siempre niega.

**Tratados.** 2: 7c, `cargar(inicio, fin)` una vez por rango con 3 `EstadoSeccion`, en paralelo,
descartando respuestas de un rango anterior; error/cargando/"Sin datos" por gráfica. 3:
corregido en 7b. 4: `Expanded` fuera. Métodos muertos del VM borrados (K2). Exportar
deshabilitado sin grupos.

**Fuera de alcance.** 5 (K3, decisión de no tocarlos). 6: la exportación probablemente falla en
emuladores recientes; no se verificó ni corrigió.

**Regresiones.** Ninguna (130 → 133 → 139, checklist pasado en 7b y 7c). En el checklist, las
categorías `prueba_*` del rango de octubre son filas reales de la BD de pruebas, no un error.
*Cambio a propósito (7c)*: los 4 remotos pasaron a llamar `cargar()` y leer la sección en vez de
la `RespuestaModelo`; los 3 unitarios del 7b pasaron a 6. Declarado en el commit.

---

## Fase 8 — Limpieza

Sin caracterización previa: solo se borró código sin llamadores, y los 139 tests pasaron **sin
cambiar asserts**.

**Hallazgos**

1. Desde la fase 7 nadie lee `ConfigServicio`: los tres modos de `page1` no tienen efecto y
   `page1` es inalcanzable.
2. `grupoEntidad.dart` importaba la vista `grupo.dart` (dominio → presentación).

**Tratados.** 8a (solo `test/`): fuera `probarRepositorio*` y los tests inactivos de categorías e
imágenes (incluidos dos casos rotos conocidos). 8b: dos cadenas muertas de cursos, `NotificacionSegura`
en `DetalleGrupoViewModel` y `Atencionviewmodel`, 41 imports sin uso (2 con el hallazgo 2).
Warnings 71 → 31.

**Fuera de alcance (conservado por decisión).** `lib/data/api/fabrica/`, `ConfigServicio`,
`page1`/`page2` y sus rutas, `lib/data/api/conexion/local/`, `MyHomePage`, `shared_preferences`.
`Imagenrepositorio` queda sin test (el suyo nunca corría).

**Regresiones.** Ninguna (139/139, 0/31/301).

---

## Recopilación de regresiones

### Regresiones reales

**Ninguna.** No hubo fase que cerrara con un comportamiento previo roto: los tests de
caracterización pasaron tras cada refactor, la suite completa quedó en verde en cada commit y
cada checklist manual se pasó antes del commit.

Límite de esta afirmación: la caracterización cubre **solo rutas críticas**, y tras la fase 8 no
se hizo el recorrido E2E completo con los tres roles. Una regresión en un caso especial o en una
combinación de pantallas no cubierta por un checklist podría no haberse visto.

### Riesgos de regresión evitados antes del commit

| Fase | Riesgo | Cómo se evitó |
|---|---|---|
| 0.2 | Deporte y Facultad sin URL al dejar de pasar por `page1` | `obtenerBaseApi()` delega en `ConfigApi` |
| 1 | `ProviderNotFoundException` en inscripciones y `default` al sacar `CategoriaViewModel` de la raíz | VM por ruta también en esas rutas |
| 1 | Lista de categorías sin actualizar tras editar (VM ya no compartido) | `pop(true)` + recarga |
| 4b | Clase nueva sin aparecer al volver del formulario | La pantalla del grupo recarga al volver con `true` |
| 6c | Tests que pasaban por compartir la misma lista entre peticiones del doble | `copiaRespuesta()` en los dobles |

### Reportes del checklist que no eran regresiones

| Fase | Reporte | Causa |
|---|---|---|
| 3/4 | "fechaCreacion no puede ser periodo futuro" | Emulador en GMT; `GrupoFormulario` usa la fecha del dispositivo |
| 6b | El alumno no ve grupos para inscribirse | Rango de inscripción del grupo; no hay forma de abrirlo desde la app ni `PUT /grupo` |
| 6c | "Agregar horario" no hace nada | `onPressed` vacío desde antes; sin endpoint |
| 6c | Entrar a una clase da 404 | El backend no tiene endpoints de atenciones |
| 7c | Estadísticas llenas de `prueba_*` | Datos reales de la BD de pruebas |

### Cambios de comportamiento a propósito

| Fase | Cambio | Asserts afectados |
|---|---|---|
| 2b | Facultades pasa de sin timeout a 20 s | Ninguno |
| 4c | Lista de clases se muda a `DetalleGrupoViewModel`; 406 = lista vacía | 2 asserts quitados de `prueba5`; 2 remotos verifican con el VM nuevo |
| 6b | Inscripción de 10 min a 20 s; inscribir/desvincular devuelven `Resultado` | Ciclo remoto de inscripción |
| 6c | Carga por grupo, revalidación de un solo grupo | 2 unitarios del 6b |
| 7c | Carga por rango; 400/500 ya no rompe la pantalla | 4 remotos y 3 unitarios del 7b |

---

## Pendientes para retomar

**De la app**

1. Recorrido E2E manual completo con los tres roles (coordinador, instructor, alumno).
2. `Conexionautenticacionremoto.registro` sin `return` en el `if != 201` (fase 2).
3. Parámetros de query sin codificar (`?titulo=`, `categoria=`, `prmCategoria=`) en categoría y
   otros 6 módulos (fase 1).
4. Casos especiales de categorías aplazados: título duplicado, eliminar con cursos, rama de
   error y `cargando` en vuelo, `cargarCategorias(context)` sin test (fase 1).
5. `ConexionCategoriaLocal.actualizarCategoria` → `LateInitializationError` (fase 1).
6. `fechaCreacion` del grupo con el reloj del dispositivo (fase 3).
7. Exportación a Excel con `Permission.storage` en Android 13+ (fase 7).
8. `institucionalFacultades/Programas` con `UnimplementedError`; endpoints de estadísticas de
   alumnos e instructores sin usar (fase 7, K3).
9. Formulario de grupo sin rango de inscripción; botones Abrir/Cerrar/Programar en `TODO`
   (fase 6).
10. Restos conservados: `page1`/`page2` → `ConfigServicio` → fábrica → `conexion/local/` →
    `MyHomePage` → `shared_preferences` (fase 8).
11. 31 warnings restantes (18 `must_be_immutable`, 5 `unnecessary_null_comparison`, 4
    `unused_local_variable`, 3 `unused_field`, 1 `unnecessary_question_mark`).

**Del backend** (avisos pendientes)

1. Endpoints de atenciones (`VmAtencionTest.prueba4` fija el 404 y fallará cuando existan).
2. Endpoint para crear horarios.
3. `DELETE /clase` responde 200 sin borrar.
4. Abrir/cerrar inscripciones de un grupo ya creado (`PUT /grupo` o equivalente).
