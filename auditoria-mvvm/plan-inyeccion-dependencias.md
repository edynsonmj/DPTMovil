# Plan de refactorización: de la fábrica abstracta a inyección de dependencias

Estado al 2026-10-23. Rama `refactor/inyeccion-dependencias` (local, sin subir).
**Fases 0 a 8 hechas: la refactorización está cerrada.** Queda pendiente el recorrido E2E
manual completo (ver "Pendientes") y, cuando se decida, borrar los restos que se conservaron.

## Objetivo

Quitar `ConexionFabricaAbstracta` y el modo local, porque ya no se justifican: el backend
está casi completo. Las dependencias se arman en una **raíz de composición**
(`lib/config/inyeccion/dependencias.dart`) con `provider`:

```
Dio compartido → Conexion*Remoto → *Repositorio → Servicio*   (raíz, sin estado)
Servicio* → *ViewModel                                         (por ruta, en route_generator)
```

## Decisiones ya tomadas (no reabrir)

| Tema | Decisión |
|---|---|
| Contenedor de dependencias | `provider` (árbol de composición), **no** `get_it` |
| Raíz vs ruta | Por estado y vida útil, no por número de consumidores. Raíz: `Dio`, `Conexionimagen` (la única conexión compartida: categoría, curso y `Servicioimagen`) y los `Servicio*`. Las conexiones y repositorios 1:1 se construyen **dentro del `create` de su servicio**, sin provider propio |
| VMs | Por ruta. **Solo `AutenticacionViewModel` queda global** (sesión). Una ruta que necesita varios VMs los provee con `MultiProvider`. Se conservan las clases de VM actuales; la fusión en un VM por pantalla se hizo **solo en el módulo grupo** (`DetalleGrupoViewModel`, fase 4c). En las pantallas de grupos asignados e inscripción (fase 6c) no se fusionó: cada VM guarda su estado **por grupo** (`Grupoentidad.clave`) y cada tarjeta lo lee con `context.select` |
| Estado de pantalla | `EstadoSeccion<T>` inmutable (`estadoSeccion.dart`) para lo que se pinta por partes, y el mixin `NotificacionSegura` para que un VM de ruta no notifique tras `dispose`. Sin `FutureBuilder` creado en `build` |
| Métodos sin uso | A diferencia de las clases, los **métodos** muertos de un VM sí se borran al migrar su módulo (K2, fase 7c) |
| Clases sin uso | **No se borran** `Servicio*` ni VMs solo porque hoy no tengan consumidores (decisión del usuario): servirán para funcionalidades futuras. Casos: `Servicioimagen` y `Alumnosviewmodel` |
| Servicios | **Se mantienen las clases `Servicio*`**, aunque hoy son pasarelas. No confundirlas con los "services" de la guía de Flutter (que equivalen a las `Conexion*`). No se adoptan las demás sugerencias de esa guía |
| `Servicioimagen` | Desde la fase 3 recibe su repositorio y está registrado en la raíz (perezoso: no se crea hasta que alguien lo lea) |
| URL de imágenes | La arma la conexión (`urlImagen`) y baja por repositorio → servicio → VM; la vista la pasa a `Tarjeta` (`atrUrlImagen`) o a `EncabezadoImagen` (`urlImagen`). Los widgets no conocen el servidor. Desde la fase 6 no queda ningún respaldo: sin URL, `Tarjeta` muestra la imagen por defecto |
| Timeouts | Todas las conexiones usan los 20 s del `Dio` compartido salvo imagen (30 s) y autenticación (1 min), que los piden por petición. Inscripción tenía 10 minutos; desde la fase 6 usa los 20 s |
| Listas vacías | El backend no es uniforme: `/horarios` responde `200 []`; `/alumnosGrupo` y `/clasesGrupo` responden 200 con un objeto `GC-0002` que la conexión devuelve como 406. Las conexiones no se tocan; `DetalleGrupoViewModel` trata ese 406 como lista vacía |
| URL del backend | `ConfigApi.baseUrl` (`--dart-define=API_HOST=...`, por defecto `10.0.2.2`), única fuente desde la fase 7. `ConfigServicio.obtenerBaseApi()` ya no tiene llamadores |
| Restos conservados (fase 8) | **No se borran por ahora** (decisión del usuario, 2026-10-23): `lib/data/api/fabrica/` (sin métodos), `ConfigServicio`, `page1`/`page2` con sus rutas, `lib/data/api/conexion/local/`, `MyHomePage` y `shared_preferences`. La app arranca en `AppRutas.categorias` (`onGenerateInitialRoutes` evita que `/categorias` apile `/`); `page1` es inalcanzable y la IP que se escribe en ella se ignora |
| Cliente HTTP | `crearClienteHttp([baseUrl])` en `configApi.dart`, timeouts de 20 s. Una conexión que necesite más los pide por petición con `Options(sendTimeout:, receiveTimeout:)` (imágenes 30 s, autenticación 1 min) |
| Constructores | Parámetro **obligatorio** por defecto: el compilador lista todos los usos. Parámetro **opcional con respaldo** solo en hojas compartidas con usuarios sin migrar, marcado `//TODO fase N` |
| Dobles de prueba | Escritos a mano, sin `mocktail`, en `test/dobles/`. Convención `<NombreDeLaInterfaz>Falsa`, programables (`respuestaX` fijables, registran `ultimoX`/`llamadasX`) |
| Alcance de los tests | Solo **rutas críticas**; los casos especiales se aplazan hasta que la app se estabilice |
| BD de pruebas | El backend en `localhost:8082` usa una BD desechable; las imágenes huérfanas y las categorías `prueba_*` se aceptan |
| Documentación | `CLAUDE.md`, `auditoria-mvvm/`, `diagramas/` y los `.dot` **no se versionan**; no incluirlos en commits |

## Protocolo por módulo

1. **Antes:** con los constructores actuales, escribir tests de caracterización de las rutas
   críticas (repositorio con doble + VM remoto) y correr `flutter analyze` y `flutter test`
   con el backend arriba. Commit propio ("Fase Na").
2. **Refactor:** conexión recibe `Dio` → servicio recibe repositorio → VM recibe servicio →
   registrar en la raíz → VM por ruta.
3. **Después:** los mismos tests pasan **sin tocar sus asserts** (solo cambia la función
   `crearVm`). Excepción: cuando una responsabilidad se muda a propósito de clase o cambia lo
   que devuelve un método por una decisión aprobada (fases 4c, 6b y 6c), el commit dice qué
   asserts se movieron, cambiaron o quitaron y por qué.
5. Antes de escribir un test contra un endpoint, comprobar que existe en `/v3/api-docs`, y
   ante un comportamiento raro, inspeccionar la respuesta cruda con un test temporal (que se
   borra) antes de fijarlo. Se agregan tests unitarios de VM con dobles, la línea del test de humo y, si
   aplica, un widget test. Comprobar que los tests nuevos detectan un fallo inyectado y
   restaurar. `flutter analyze` sin errores nuevos y warnings que no suban. Checklist manual
   en el emulador. Commit propio ("Fase Nb").
4. Cada paso se **detalla al usuario antes de aplicarse** y **no se hace commit sin su
   revisión**. No se sube nada al remoto.

## Estado actual

| | Línea base (`8c9291c`) | Fin de fase 2 (`99bd16a`) | Fin de fase 3 (`bd7ab9e`) | Fin de fase 4 (`5127c97`) | Fin de fase 5 (`4bfeea9`) | Fin de fase 6 (`7f10367`) | Fin de fase 7 (`6132fc8`) | Fin de fase 8 (`52aa19a`) |
|---|---|---|---|---|---|---|---|---|
| `flutter analyze` | 0 errores, 113 warnings, 321 infos | 0 errores, 99 warnings, 326 infos | 0 errores, 95 warnings, 332 infos | 0 errores, 83 warnings, 329 infos | 0 errores, 83 warnings, 333 infos | 0 errores, 76 warnings, 337 infos | 0 errores, 73 warnings, 332 infos | **0 errores, 31 warnings, 301 infos** |
| `flutter test` | 35 | 54/54 | 65/65 | 92/92 (43 sin backend) | 101/101 (51 sin backend) | 123/123 (70 sin backend) | 139/139 (82 sin backend) | **139/139** (82 sin backend) |
| VMs globales | 12 | 9 | 8 | 5 | 5 | 2 | 1 | 1 |
| Métodos en la fábrica | 11 | 9 | 6 | 2 | 1 | 1 | 0 | 0 |

Solo queda global `AutenticacionViewModel` (se queda). Ninguna conexión usa `ConfigServicio()`
y no queda ningún `unused_import`. Los 31 warnings que quedan son de otro tipo: 18
`must_be_immutable`, 5 `unnecessary_null_comparison`, 4 `unused_local_variable`, 3
`unused_field` y 1 `unnecessary_question_mark`.

Commits de la rama:

```
52aa19a Fase 8b: código muerto de cursos, mixin e imports sin uso
a70830b Fase 8a: fuera los tests inactivos de repositorio
6132fc8 Fase 7c: estadísticas cargadas una vez por rango
8d93960 Fase 7b: Estadísticas inyectada y VM por ruta
f9ef680 Fase 7a: tests de caracterización de Estadísticas
7f10367 Fase 6c: horarios e inscripción cargados una vez por grupo
6b24ab7 Fase 6b: inscripción inyectada y VMs por ruta en grupos asignados e inscripción
ca30085 Fase 6a: tests de caracterización de grupos asignados e inscripción
4bfeea9 Fase 5b: Atención inyectada y carga al crear la ruta clase
9e822a1 Fase 5a: tests de caracterización de Atención
5127c97 Fase 4c: pantalla de grupo con un solo VM (DetalleGrupoViewModel)
7453e0d Fase 4b: módulo grupo inyectado y VMs por ruta en grupo y formularios
34b457c Fase 4a: tests de caracterización del módulo grupo
bd7ab9e Fase 3b: Curso, Deporte e Imagen inyectados y VMs de cursos por ruta
21ab80e Fase 3a: tests de caracterización de Cursos y Deporte
99bd16a Fase 2b: Autenticación y Facultades inyectadas, Facultades por ruta
4290c72 Fase 2a: tests de caracterización de Autenticación y Facultades
7f81f9e Fase 1: Imagen y Categoría inyectadas y VM de categorías por ruta
278921e Fase 0.4: dobles de prueba y tests de repositorio de categorías
44071f8 Fase 0.3: raíz de composición en dependencias.dart y test de humo
4f15af4 Fase 0.2: URL única con --dart-define y arranque sin page1
8c9291c Corrección MVVM de categorías, clase, curso y cursos con tests de ViewModel
```

Piezas de infraestructura ya disponibles:

- `lib/config/configApi.dart`: `ConfigApi.baseUrl` y `crearClienteHttp()`.
- `lib/config/inyeccion/dependencias.dart`: `proveedoresDatos()` (antes) y `vmsGlobales()`
  (después). El orden importa: un VM lee sus servicios con `context.read` en su `create`.
- `test/raiz_composicion_test.dart`: test de humo; falla con `ProviderNotFoundException` si
  falta un provider. Se actualiza en cada fase.
- `test/main_test.dart`: `baseUrlPruebas` (`http://localhost:8082/api/v2`) y
  `crearCategoriaViewModel(conexion)`. Los tests remotos nuevos reciben una función
  `crearVm` (patrón de `VmListarGruposTest`).
- `test/main_test.dart` también tiene `crearDeporteViewModel()`; `VmCursoTest` crea en su
  `setUpAll` una categoría `prueba_*` y sus 3 casos dependen del orden (el curso que agrega
  el primero es el que buscan los otros dos).
- `test/main_test.dart` arma los VMs del módulo grupo con `crearGruposViewModel()`,
  `crearHorariosViewModel()`, `crearAlumnosViewModel()`, `crearClasesViewModel()`,
  `crearInstructoresViewModel()` y `crearDetalleGrupoViewModel(grupo)`, atención con
  `crearAtencionViewModel()`, inscripción con `crearInscripcionViewModel()` y estadísticas
  con `crearEstadisticasViewModel()`. Ningún test activo fija `ConfigServicio` (solo los
  inactivos `probarRepositorio*`).
- `VmGruposInscripcionTest` crea en su `setUpAll` una categoría, un curso, un grupo y un
  **alumno de prueba** (registro con id numérico único); sus 3 casos dependen del orden.
- `VmModuloGrupoTest` crea en su `setUpAll` una categoría y un curso nuevos y usa el primer
  instructor de la BD; sus 7 casos dependen del orden (el grupo que crea el caso 2 lo usan
  los demás).
- Dobles: `ConexionCategoriaFalsa`, `ConexionCategoriaLocal` (movida desde `lib/`),
  `ConexionautenticacionFalsa`, `ConexionfacultadesFalsa`, `ConexionCursoFalsa`,
  `ConexiongruposFalsa`, `ConexionhorariosFalsa`, `ConexionalumnosFalsa`,
  `ConexionclasesFalsa`, `ConexioninstructoresFalsa`, `ConexionatencionesFalsa`,
  `ConexioninscripcionFalsa`, `ConexionEstadisticasFalsa` (con `antesDeResponder` para
  retrasar una respuesta), `GoogleSignInFalso`. `copiaRespuesta()` copia la respuesta de
  un doble que sirve a varias peticiones (los repositorios convierten escribiendo sobre
  `respuesta.datos`); solo copia si hay lista, para no romper los tests con `same()`.
- Widget tests: `CategoriasView`, la pantalla de grupo (`grupoView_test.dart`), la de
  clase (`claseView_test.dart`), la de inscripción del alumno (`gruposInscripcionView_test`),
  la de grupos asignados (`gruposAsignadosView_test`) y la de estadísticas
  (`estadisticasGeneralesView_test`).
- El backend publica su documentación OpenAPI en `http://localhost:8082/v3/api-docs`
  (lista de rutas): útil para comprobar si un endpoint existe antes de escribir un test.

## Fases

### Hechas

- **Fase 0 — Infraestructura.** Línea base, `ConfigApi` + `--dart-define`, `Dio` compartido,
  arranque en categorías, raíz de composición, test de humo, eliminado `Imagenviewmodel`
  (ninguna pantalla lo usaba), primer doble y tests de repositorio de categorías.
- **Fase 1 — Imagen + Categoría.** `ConexionCategoriaRemota(Dio, Conexionimagen)`,
  `Conexionimagenremoto([Dio?])` con respaldo, `ServicioCategoria(repositorio)`,
  `CategoriaViewModel(servicio)` por ruta en `categorias`, `editarCategoria`, las dos rutas
  de inscripciones y el `default`. `CategoriasView` recarga cuando el formulario vuelve con
  `true`. Sale `crearConexionCategoria` de las fábricas.
- **Fase 2 — Autenticación + Facultades.** `Conexionautenticacionremoto(Dio)` (1 min por
  petición), `Conexionfacultadremoto(Dio)`, `AutenticacionViewModel(servicio, GoogleSignIn)`
  global, `Facultadesviewmodel(servicio)` por ruta en `autenticacionRegistro`. Sale
  `crearConexionAutenticacion`. Primer widget test (`CategoriasView`).
- **Fase 3 — Cursos + Deporte** (`21ab80e` tests, `bd7ab9e` refactor; checklist manual
  pasado). `ConexionCursoRemoto(Dio, Conexionimagen)`, `Conexiondeporteremoto(Dio)`,
  `Conexionimagenremoto(Dio)` obligatorio (sin respaldo). `ServicioCurso`,
  `Serviciodeporte` y `Servicioimagen` reciben su repositorio y están en la raíz.
  `CursosViewModel(servicio)` por ruta en `cursos`, `formularioCurso` (con
  `Deporteviewmodel`, en un `MultiProvider`) y `grupo` (solo para mostrar el curso).
  `Deporteviewmodel` sale de los globales. Salen `crearConexionCurso`,
  `crearConexionDeporte` y `crearConexionImagenes` de las fábricas. Corregido el `return`
  que faltaba en `agregarCurso`. `urlImagen` de curso desde la conexión hasta el VM;
  `FormularioCurso`, `cursos.dart` y `CategoriasView` ya no arman la URL. Tests: doble
  `ConexionCursoFalsa`, 4 de repositorio, 3 unitarios de VM y 4 remotos (deportes,
  agregar, listar de categoría, obtener).
- **Fase 4 — Grupo + Horarios, Alumnos, Instructores, Clases** (`34b457c` tests, `7453e0d`
  inyección, `5127c97` fusión; checklist manual pasado en 4b y 4c). Se hizo en tres commits
  para separar la inyección de la fusión.
  - 4a: 5 dobles, 8 tests de repositorio y remotos sobre un grupo real creado en la prueba
    (incluye el caso de éxito de registrar clase, pendiente desde septiembre).
  - 4b: las 5 conexiones reciben `Dio`; servicios y VMs por constructor; salen de las
    fábricas grupos, horarios, alumnos y clases. `formularioClase` recibe el `Grupoentidad`
    y crea su `Clasesviewmodel` (revierte la decisión del 2026-09-25 de dejarlo global);
    `grupoFormulario` con `Gruposviewmodel` e `InstructoresViewModel` propios, e
    `insertarGrupo` ya no recarga. `GrupoFormulario`: año en `initState` (no `setState` en
    `build`), `return` al faltar identificador, sin `print`. `EncabezadoImagen` recibe la URL
    desde `Gruposviewmodel.urlImagen`.
  - 4c: `DetalleGrupoViewModel` (curso, horarios, alumnos y clases, cargados una vez en el
    `create` de la ruta; `EstadoSeccion` inmutable + `context.select`; 406 como lista vacía;
    no notifica tras `dispose`). Los widgets de la pantalla quedan sin estado ni
    `FutureBuilder`. `Clasesviewmodel` queda solo para registrar; `prueba5GrupoNoInicializado`
    perdió 2 asserts de la lista que pasó al VM nuevo. `Alumnosviewmodel` se conserva sin uso.
- **Fase 5 — Atención** (`9e822a1` tests, `4bfeea9` inyección; checklist manual pasado,
  aunque la pantalla solo puede mostrar el 404). `Conexionatencionesremoto(Dio)`,
  `Servicioatencion(repositorio)` en la raíz, `Atencionviewmodel(servicio)`. La ruta `clase`
  crea el VM y carga en su `create` (H2); `claseView` ya no carga en `initState`. El VM no
  notifica tras `dispose` (H4). Sale `crearConexionAtenciones`. Tests: doble, 2 de
  repositorio, 1 remoto que fija el 404, 4 unitarios de VM y widget test de la pantalla. El
  caso de éxito con un alumno inscrito (H1) y la lista vacía (H3) quedan para cuando existan
  los endpoints; el registro y la inscripción de un alumno de prueba sí funcionan.
- **Fase 6 — Grupos asignados + Grupos de inscripción** (`ca30085` tests, `6b24ab7`
  inyección, `7f10367` carga por grupo; checklist manual pasado). Las pantallas de
  inscripciones generales y particulares son maquetas con `CategoriaViewModel` y quedaron
  fuera.
  - 6a: doble de inscripción, 3 tests de repositorio y remotos sobre un grupo y un alumno de
    prueba: grupos del instructor, grupos disponibles y el ciclo validar → inscribir →
    validar → desvincular → validar. El GET con cuerpo de `validarInscripcion` funciona.
  - 6b: `Conexioninscripcionremoto(Dio)` con 20 s (I2), `Servicioinscripcion` en la raíz,
    VMs propios en las rutas `gruposDisponiblesInscripcion` (Grupos, Horarios, Inscripción) y
    `gruposAsignados` (Grupos, Horarios); salen 3 globales. `Tarjeta` pierde `idImagen` y el
    respaldo con `ConfigServicio`. Las tarjetas revisan el código antes de pintar horarios
    (I3). Inscribir y desvincular devuelven `Resultado` y la vista espera el diálogo; "Quitar
    matrícula" también avisa (I4). Cambiaron los asserts del ciclo de inscripción remoto.
  - 6c (opción b de I1): horarios y estado de inscripción guardados por grupo y cargados una
    vez (J1, en `initState` de la pantalla); tarjetas sin `FutureBuilder`; tras inscribir solo
    se revalida ese grupo (J3) y su botón se deshabilita mientras tanto (J4); `EstadoSeccion`
    y `NotificacionSegura` en `estadoSeccion.dart` (J2). Cambiaron 2 asserts de
    notificaciones del 6b por comprobaciones del estado del grupo.
- **Fase 7 — Estadísticas** (`f9ef680` tests, `8d93960` inyección, `6132fc8` carga por
  rango; checklist manual pasado en 7b y 7c). Endpoints `/estadisticas/{categorias,cursos,grupos}`
  comprobados: con datos dan `200 [...]` con números `double`; un rango sin clases (o
  invertido) **no da lista vacía**, sino todas las categorías en `0.0` (K4); una fecha vacía o
  mal formada da 400.
  - 7a: doble de estadísticas, 3 tests de repositorio y 4 remotos (categorías, grupos para
    exportar, rango sin clases, fecha mal formada).
  - 7b: `Conexionestadisticasremoto(Dio)` (20 s), `ServicioEstadisticas(repositorio)` en la
    raíz, VM por ruta en `estadisticasGenerales`; `vmsGlobales()` queda solo con la sesión.
    Sale `crearConexionEstadisticas` (L1: las fábricas quedan vacías y se borran en la fase 8).
    El repositorio pone la ruta real de cada sección en su error (L2).
  - 7c (K1–K2, M1–M4): el VM guarda el rango y tres `EstadoSeccion`; `cargar()` pide las tres
    en paralelo, ordena por horas una vez y descarta lo que llega de un rango anterior;
    `limpiar()` para "Cancelar". Vista sin estado ni `FutureBuilder`; un 400/500 ya no da la
    pantalla roja. Exportar deshabilitado sin grupos. Fuera el `Expanded` mal puesto de
    `GraficoBarrasAgrupado` y los métodos muertos del VM. Cambiaron los asserts de los 4
    remotos (leen la sección tras `cargar()`) y los 3 unitarios de la 7b (pasan a 6).
  - Visto en el checklist: con 2026-10-01 a 2026-10-22 casi todo son categorías `prueba_*`
    de los tests remotos (1 clase, 2 h cada una); son filas reales de la BD de pruebas.
  - Sin cambiar: `institucionalFacultades/Programas` siguen lanzando `UnimplementedError` y
    la app no usa `/estadisticas/alumnos` ni `/instructores` (K3). `guardarArchivoExcel` pide
    `Permission.storage`, que Android 13+ siempre niega: la exportación probablemente falla en
    emuladores recientes.
- **Fase 8 — Limpieza** (`a70830b` tests, `52aa19a` lib). Sin commit de caracterización
  previo: solo se borró código sin llamadores, y los 139 tests pasaron sin cambiar asserts.
  - Hallazgo: desde la fase 7 nadie lee `ConfigServicio` (`obtenerBaseApi()` sin llamadores),
    así que los tres modos de `page1` ya no tienen efecto y `page1` es inalcanzable.
  - 8a, **solo la parte de test/** (el usuario decidió conservar los archivos de lib/):
    `main_test` sin `probarRepositorio*`, sus grupos ni `configuracion*Repositorio`; borrados
    `test/local/categorias/`, `test/remoto/categorias/` (con los dos casos rotos conocidos) y
    `test/remoto/imagenes/`. `Imagenrepositorio` se queda sin test (el suyo nunca corría).
    Se conservan `probarViewModelCategoriaLocal` y `ConexionCategoriaLocal` (activos).
  - 8b (N3, N4): fuera las dos cadenas muertas de cursos (`cargarListaCursos` → `call` →
    `obtenerCursos`, y `listarTodosCursos` → `listarTodosLosCursos` → `encontrarTodosCursos`)
    en interfaz, remoto, repositorio, servicio, VM y doble; `ConexionCursoLocal` pierde esos
    métodos y sus datos de ejemplo. `DetalleGrupoViewModel` y `Atencionviewmodel` usan
    `NotificacionSegura`. `dart fix --code=unused_import`: 41 imports en 28 archivos (entre
    ellos `grupoEntidad.dart`, que importaba la vista `grupo.dart`). Warnings de 71 a 31.
  - `CLAUDE.md` reescrito (no versionado): raíz de composición, VMs por ruta, estado real de
    las dos suites, `Resultado`/`EstadoSeccion`/`NotificacionSegura` y la lista de restos
    conservados.
  - Ya no queda ningún respaldo `//TODO fase N`.

### Hallazgos del backend (fuera de esta refactorización)

Avisos pendientes para quien mantiene el backend:

1. **No existen endpoints de atenciones**: `GET /atencionesporclase` y `POST /atenciones`
   responden 404 `NoResourceFoundException` y no aparecen en `/v3/api-docs`. La pantalla de
   asistencia de una clase no puede funcionar (al entrar a una clase se ve "Código: 404").
   `VmAtencionTest.prueba4BackendSinEndpoint` fija el 404: cuando se agreguen, fallará y hay
   que reemplazarlo por casos de listar y registrar (y revisar cómo llega la lista vacía).
2. **No hay endpoint para crear horarios**: solo existe `GET /horarios`. En la app el botón
   "AGREGAR HORARIO" de la pantalla de grupo tiene `onPressed: () {}`; falta también el
   formulario.
3. **`DELETE /clase?id=X` no borra**: de una clase existente responde 200 sin cuerpo, pero
   `/clasesGrupo` la sigue devolviendo con `eliminado: 0` (el parámetro `id` es el correcto:
   sin él, 400). El test remoto solo fija el 200; cuando se corrija, agregar que la lista
   quede vacía.
4. **No se pueden abrir ni cerrar las inscripciones de un grupo ya creado**:
   `/gruposInscripcion` devuelve los grupos con `fechaInscripcionApertura` ≤ hoy ≤
   `fechaIncripcionCierre`. Esas fechas solo se pueden fijar al crear el grupo (`POST /grupo`
   las acepta) y no hay `PUT /grupo`. En la app, además, `GrupoModelo` no tiene esos campos y
   los botones "Abrir", "Cerrar" y "Programar" de las pantallas de inscripciones son `TODO`.
   Con el backend actual se podría pedir el rango de inscripción en el formulario de grupo.

Otros:

- `fechaCreacion` del grupo se calcula con el reloj del dispositivo; con el emulador en GMT,
  después de las 19:00 de Bogotá el backend la rechaza por "futura".
- Las listas vacías no llegan igual en todos los endpoints (ver la decisión "Listas vacías").
- En la BD de pruebas quedó abierto a inscripción el grupo `curso_20261023012143953553`
  (2026.2, del 22 al 30 de octubre), creado para el checklist de la fase 6.

### Pendientes

- **Recorrido E2E manual completo** con los tres roles (coordinador: categorías → cursos →
  grupo → clase, estadísticas; instructor: grupos asignados; alumno: inscripción). Cada fase
  pasó su propio checklist, pero tras la fase 8 no se hizo un recorrido completo.
- **Restos conservados**, para cuando se decida borrarlos (N1/N2 de la fase 8): orden sugerido
  `page1`/`page2` y sus rutas → `ConfigServicio` → `lib/data/api/fabrica/` →
  `lib/data/api/conexion/local/` → `MyHomePage` → `shared_preferences` del `pubspec`. Ninguno
  tiene test ni llamador, así que la suite no debería cambiar.

## Cómo correr las pruebas

```bash
flutter analyze
```

```bash
flutter test
```

Los tests remotos necesitan el backend en `localhost:8082`. Si todos los remotos fallan a la
vez, revisar primero que el backend esté arriba. Si `flutter run` no conecta con la app
("Error connecting to the service protocol") pero la app corre, usar `flutter attach`.
