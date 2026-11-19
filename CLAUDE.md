# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

`dpt_movil` — Flutter app (Android-first, `co.edu.unicauca.dpt_movil`) for Unicauca's "Deporte para Todos" program: categories → courses → groups → classes/schedules, plus enrollments, students, instructors and statistics. All code, identifiers and comments are in Spanish; keep new code in Spanish.

Flutter 3.41 / Dart 3.11, `sdk: ^3.7.2`. Key packages: `dio` (HTTP), `provider` (state + dependency injection), `fl_chart`, `google_sign_in`, `image_picker`, `excel`.

## Commands

```bash
flutter pub get
flutter run                                   # backend at 10.0.2.2:8082 (emulator alias for the host)
flutter run --dart-define=API_HOST=192.168.1.20   # backend elsewhere
flutter analyze                               # lints via flutter_lints (analysis_options.yaml)
flutter test test/unitarias test/raiz_composicion_test.dart test/integracion   # backend-free suite (457), must be green
flutter test test/main_test.dart                              # remote suite (130), needs the backend
flutter test test/diagnostico                                 # diagnostic suite (34): red ON PURPOSE, one test per known bug
flutter test --plain-name "<substring of test name>"
```

Plain `flutter test` runs **all three** (621), so it is never all green: the diagnostic suite fails by design (28 red of 34), and without a backend the remote suite fails too. Use the explicit paths above. If every remote case fails at once, check first that the backend on `localhost:8082` is up (a 503 "No hay conexion" means it is still starting). Since 2026-11-05 the backend in use (`E:/2026-1/Practica/BackDeporteParaTodos (Nuevo)`) answers **401** on every route without a JWT; only `POST /RegistroPerfilAlumno`, `GET /facultades` and `GET /programas` are public. The remote suite signs its own test JWT (`test/remoto/jwtPruebas.dart`, HS256 with the same claims as the backend's `TokenServicio`), taking `JWT_SECRET` from `--dart-define`, the environment or the backend's `.env` (`DPT_BACKEND_ENV` overrides the path); the secret is never committed or printed. Since 2026-11-19 it is **green** (130) with the backend up; incompatibilities with the new backend are recorded in `registro-bugs.md`, «Compatibilidad con el backend nuevo» (BK-xx). Seeds that inscribe several students use **one `Inscripcionviewmodel` per inscription**: the VM keeps its state per group (one user per VM, as in the app) and blocks a second student in the same group with its own 409. The backend publishes its route list at `http://localhost:8082/v3/api-docs` — check there before writing a test against an endpoint.

Analyzer baseline: 0 errors, 33 warnings (mostly `must_be_immutable`; 3 come from the side-menu redesign, SCRUMBAN-137), ~391 infos (new test files only add `file_names` infos, because they follow the project's camelCase file names). New code should not raise the warning count.

CI (`.github/workflows/ci.yml`, CI-01): on every push and PR, GitHub Actions runs `flutter analyze` (fails on errors, and on more warnings than `LIMITE_AVISOS`; lower that number when a fix lowers the baseline, never raise it) and the backend-free suite, on Ubuntu with `TZ=America/Bogota`. The runner is Linux, so **import paths are case-sensitive**: an import whose case differs from the file name compiles on Windows and breaks CI.

### Tests

Three suites with different styles. Test names follow `'$capa - $tipo - $metodo - $caso'` (e.g. `viewModel - unitaria - Listar categorias - 200 carga la lista`).

#### 1. Backend-free suite — `test/unitarias/` + `test/raiz_composicion_test.dart` + `test/integracion/`

Normal Flutter tests: each file has its own `main()` and ends in `_test.dart`.

- `unitarias/conexion/` — the **real** `Conexion*Remoto` on top of `AdaptadorHttpFalso` (see below): exact URI and query, JSON body sent, status codes, `DioException` types. So far atenciones, autenticación (login and registro), grupos (periodo de inscripción) and inscripción (`validarInscripcion`), plus the adapter's own smoke test.
- `unitarias/modelo/` — `fromJson`/`toJson` round trips.
- `unitarias/dominio/` — rules computed on entities (e.g. `Grupoentidad.estadoInscripcion(hoy)`); they take the date as a parameter, never `DateTime.now()`.
- `unitarias/repositorio/` — one file per module: modelo → entidad conversion, and error responses pass through unchanged (`same(...)`).
- `unitarias/viewModel/` — VM state after loads, refresh after writes, `Resultado` returned on failures, no notify after `dispose`.
- `unitarias/vista/` — widget tests for `CategoriasView`, the grupo screen, clase, grupos de inscripción, grupos asignados, estadísticas and the coordinator's inscripciones screens (`inscripcionesCoordinador_test.dart`, mounted through the real routes with `integracion/montajeInscripciones.dart`). Each mounts the screen under the same providers `route_generator` gives it (plus a global `AutenticacionViewModel` built on doubles).
- `raiz_composicion_test.dart` — smoke test: mounts `proveedoresDatos()` + `vmsGlobales()` and reads every provider, so a missing registration fails with `ProviderNotFoundException` here instead of at runtime. Update it whenever a service is added to the root.
- `integracion/` — local end-to-end flows with **no backend**: the real routes of `route_generator` (`onGenerateRoute: generateRoute`) and the real chain of the module under test down to `Conexion*Remoto` + `AdaptadorHttpFalso`; neighbouring modules go in with their doubles. `montajeAtenciones.dart`, `montajeInscripciones.dart` and `montajeAutenticacion.dart` (side menu + real routes + real auth chain) are shared mounts (no `_test` suffix, so they are not run on their own).

How they are built:

- **Test doubles live in `test/dobles/`**, written by hand (no `mocktail`), named `<InterfaceName>Falsa` (`ConexionCategoriaFalsa`, `ConexiongruposFalsa`, `ConexionEstadisticasFalsa`, …), plus `GoogleSignInFalso` and `SelectorImagenFalso` (install it with `ImagePickerPlatform.instance = SelectorImagenFalso('assets/images/1.jpg')` so `image_picker` returns that file; `image_picker_platform_interface` is a dev dependency for this). A form that uploads a real file must be submitted inside `tester.runAsync(...)` (tap + a short real delay): file IO does not advance on the fake clock, and the continuation after the request (dialogs, `pop`) also runs in that real zone — see `integracion/formularioCurso_integracion_test.dart`. They are *programmable*: the test sets `respuestaX` before acting and inspects `ultimoX` / `llamadasX` afterwards. Some accept a hook to delay an answer (`antesDeResponder` in estadísticas, `antesDeRegistrar` in atenciones).
- **A double must reject what the real connection rejects.** A double that accepts inputs the real code crashes on makes tests green for paths that cannot happen in production (e.g. inserting a categoría with no image file: the real connection does `imagenFile!`).
- **`AdaptadorHttpFalso`** (`test/dobles/adaptadorHttpFalso.dart`) replaces Dio's transport, one level below the connection: `responder(metodo, ruta, codigo, cuerpo)`, `fallar(metodo, ruta, DioExceptionType)`, `retener(metodo, ruta)` → `Completer` to hold an answer, and `peticiones` / `peticionesA(...)` with the URI and decoded JSON body that went out. `crearDioFalso(adaptador)` gives the same `Dio` as the root (timeouts included). A route nobody programmed answers 404, so a forgotten route shows up as a failure.
- **Contracts in `test/contratos/<modulo>/`**: the JSON the app expects from each endpoint, read with `leerContrato(modulo, nombre)` (path relative to the project root). Doubles and adapter responses take their data from here instead of inventing it, so the data shape is written down once and reviewed with the backend team. `atenciones/` was a proposal until 2026-10-29; it now holds the observed shape of `/asistenciasClase` (see `LEEME.md` there).
- **`copiaRespuesta()`**: repositories convert by writing over `respuesta.datos`. A double that serves the same response to several requests must return a copy (only when `datos` is a list, so `same()` checks on errors still hold).
- `ConexionCategoriaLocal` is the old local-mode fake moved here: seeded data that mutates. Still used by `probarViewModelCategoriaLocal`. Known bug: `actualizarCategoria` with an unknown title throws `LateInitializationError` instead of returning 404.
- **The real chain is built with the double at the bottom**, same shape as the composition root: `CategoriaViewModel(ServicioCategoria(CategoriaRepositorio(cliente: doble)))`.
- **New double per case in `setUp`**: no test inherits responses or state from another.
- Scope is **critical paths only**; special cases are deferred until the app stabilises.

#### 2. Remote suite — `test/main_test.dart` → `test/remoto/`, `test/local/`

Older pattern: files under `remoto/viewModel/` and `local/viewModel/` are plain classes exposing `pruebaN...` methods; they only run because `main_test.dart`'s `main()` calls a `probarViewModelX()` per module. To change what runs, edit that `main()`.

- Every VM gets its chain built by hand on a `Dio` from `crearDioPruebas(baseUrlPruebas)` (the root's `Dio` + `InterceptorToken` over the shared `almacenPruebas`; coordinador by default, `actuarComoAlumno(id)` / `actuarComoInstructor(id)` switch identity). `test/remoto/datosPruebas.dart` holds what the new backend demands from seeds: `cierreInscripcionPruebas`, `aperturaFuturaPruebas`, `completarRegistro`, `abrirInscripcionesPruebas`, `sembrarHorariosSemana` (`'http://localhost:8082/api/v2'`, constant at the top of `main_test.dart`), through helpers such as `crearCategoriaViewModel(conexion)`, `crearGruposViewModel()`, `crearDetalleGrupoViewModel(grupo)`, `crearEstadisticasViewModel()`. No test touches `ConfigServicio`.
- Newer test classes take a `crearVm` function and build one VM per case, like the route does. Older groups share one VM: the 24 categoría cases share a single `vm`, and so do the 5 `VmRegistrarClaseTest` ones — **they depend on order**.
- Some groups create their own data in `setUpAll` and depend on order: `VmCursoTest` (a `prueba_*` categoría), `VmModuloGrupoTest` (categoría + curso, uses the first instructor in the DB), `VmGruposInscripcionTest` (categoría, curso, grupo and a registered test student).
- They take the **full route** — `ViewModel → Servicio → Repositorio → Conexion → backend` — and assert on VM state, not just `codigoHttp`.
- It hits a **real backend** with a disposable test DB: orphan images and `prueba_*` rows are accepted on purpose; don't add teardown. The categoría insert-success case also downloads an image from the internet; the rest use `File('assets/images/1.jpg')`, relative to the working directory — run `flutter test` from the project root.

Backend behaviours the tests pin down:

- Categoría: inserting costs two requests (`POST /imagenMultipart`, then `POST /categoria`), so 400 cases still create images. Empty `titulo`/`descripcion` on POST → 400 with a per-field message. `DELETE` of an unknown title → 404 `GC-0003`; of an empty one → 400 (404 before the new backend). `PUT /categoria?titulo=X` validates the body before looking the categoría up: a null `imagenId` always gives 400, so a "title does not exist" test must send a real `imagenId`; with a valid body an unknown title → 404, an empty one → 400.
- Empty collections are not uniform: `/horarios` answers `200 []`, or (new backend) a `GC-0002` object that the connection turns into `200 []`; `/alumnosGrupo` and `/clasesGrupo` answered 200 with a `GC-0002` object that the connection turns into 406 (`DetalleGrupoViewModel` treats that 406 as an empty list); since 2026-10-29 `/clasesGrupo` answers `200 []` (both shapes are handled).
- Estadísticas: a range with no classes does **not** come back empty — every categoría arrives with `0.0` values; a malformed date gives 400.
- Asistencias (backend nuevo, BK-02): `/asistenciasClase` ya no existe. La lista es `GET /alumnosGrupo` unida con `GET /atencionesporclase?claseid=` (`[{idClase, idPerfil, estaAtendido}]`, o 200 con un objeto `GC-0002` si no hay marcas; leer una clase inexistente no da 404) y se confirma con `PUT /clase/{codigo}/asistencia` `{asistencias:[{idPerfil, estaAtendido}], confirmaTodosAusentes}` → 200 `{codigoClase, confirmadaEn, presentes, ausentes}` (404 `GC-0003` si la clase no existe). La unión la hace `Conexionatencionesremoto`; `Atencionmodelo.fromJson` lee `{alumno, asistio}`, la forma ya unida.
- Horarios (since 2026-11-04): `POST /horario` with the full `HorarioDto` body `{categoria, curso, anio, iterable, dia, horaInicio, horaFin, escenario}` (no query; the group in the query gives 400 "curso/categoria no debe estar vacio") → 201 with the `id`; `PUT /horario?prmId=` → 200; `DELETE /horario?prmId=` → 200, and `/horarios` stops listing it (unlike clases). 400 per field (`dia`, `horaInicio`, `rangoHorasValido`); 404 `GC-0003` for an unknown group or horario. Hours come back as sent (`08:00` or `14:00:00`). The app lists, creates and deletes (HO-04, HO-05; no edit); `VmHorarioDiagnosticoTest` seeds horarios with a plain `Dio` and reads them through the app's chain.
- `DELETE /clase?id=X` answers 200 but does not delete (backend bug CL-01); the test only pins the 200.
- `POST /claseGrupo` receives `fecha` as a `LocalDate`. `Clasemodelo.toJson` sends only the local day (`yyyy-MM-dd`, CL-07). It used to send the UTC instant (CL-06, for the old backend), which rolled to the next day from 19:00 local. `vmClaseDiagnosticoTest.prueba3FechaSinCorrimiento` pins 00:00, 04:59, 05:00 and 23:30.
- A date that already has a class: `POST /claseGrupo` answers 200 with the existing class and does not store the hours sent; a new class answers 201. `registrarClase` returns `Exito<bool>` (false = it already existed) and the form says so (BK-08).
- Class on a day with no horario (BK-04): `POST /claseGrupo` requires `justificacion` (10–500 chars, no leading/trailing spaces) → else 422 `GC-0021`; with a horario that day the backend ignores it and computes the duration itself. An Instructor cannot register on a day without horario at all (`DiaFueraDeHorarioExcepcion`); Coordinador can. The form route calls `Clasesviewmodel.cargarHorarios()`; `requiereJustificacion(fecha)` is true/false/null (null = horarios unknown, the field stays optional and the backend decides). Days are matched like the backend (`equalsIgnoreCase` against `LUNES`…`DOMINGO`, no accents), so an old horario saved as `Miércoles` does not count. Since HO-06 (fixed 2026-11-19) the app always sends the backend's code: `DiaSemana` (`domain/entities/diaSemana.dart`) has `codigo` (any spelling → `MIERCOLES`), `etiqueta` (→ `Miércoles`, for display) and `numero` (backend rule → `DateTime.weekday`). Views show `DiaSemana.etiqueta(horario.dia)`, never `horario.dia` raw.
- Periodo de inscripción (`VmPeriodoInscripcionTest`, its own group per run; new routes since 2026-11-05): `PATCH /grupo/periodo` takes `{fechaApertura?, fechaCierre, grupos:[{categoria, curso, anio, iterable}]}` and answers 200 with the list of groups; the cierre is mandatory and must be today or later, cierre before apertura → 422 `GC-0015`, unknown group → 404 `GC-0003`, and it does not reopen a group closed by hand. `PATCH /grupo/inscripciones?...&cerradas=true|false` closes or reopens by hand (`inscripcionesCerradasManual`), leaving the dates alone. `POST /grupo` requires `fechaIncripcionCierre` (422 `GC-0015`); with no apertura the group is open at once, and the closing day still counts. `POST /inscripcion` into a group with closed inscriptions → 422, not 409.
- `POST /grupo` accepts an optional `fechaFinalizacion` (`GrupoDto`); `GrupoModelo.toJson` sends it only when set, so a group without it posts the same body as before (GR-02, fixed; `vmGrupoDiagnosticoTest.prueba7FechaFinalizacion` pins it).
- Registro (`POST /RegistroPerfilAlumno`, since 2026-11-02): what it requires depends on `tipoAlumno` — Estudiante: `alumnoCodigo` + `facultad` + `programa`; Docente: `facultad` + `programa`; Administrativo/Contratista: `dependencia`. Missing data → 422 `GC-0029` with the reason in `mensaje`; the programa must belong to the facultad. `GET /programas?facultad=` answers `[{nombre, facultad}]`, or 200 with a `GC-0002` object for a facultad with none (the connection turns it into `[]`). Faculty and programme names currently come back double-encoded from the test DB (`IngenierÃ­a`): the app shows them as they come and sends them back unchanged, so validation still matches.
- Lista de espera (since 2026-11-05): `POST /inscripcion` into a full group answers **201** with `estado: EN_ESPERA`, not 409. `GET /validarInscripcion` only counts `INSCRITO`, so the waitlist comes from `GET /inscripcion/misCursos` (role Alumno, active inscriptions only). `PUT /desvincularInscripcion` also leaves the list. `Inscripcionviewmodel.enEspera(grupo)` exposes it, and `agregarIncripcion` returns `Exito<bool>` (true = waitlisted).
- `GET /validarInscripcion` takes its data as **query parameters** (since 2026-10-29); a GET body gets 400. The connection sends `queryParameters` (bug IN-07, fixed); `conexionInscripcionRemoto_test.dart` pins it.

#### 3. Diagnostic suite — `test/diagnostico/<modulo>/`

Tests that assert the **correct** behaviour for a suspected bug, so they are **red while the bug exists**. They come from the audit in `auditoria-mvvm/`:
- `plan-diagnostico-pruebas.md` — method and module order;
- `registro-bugs.md` — every bug ID, its evidence and its state;
- `informe-diagnostico-asistencias.md` — report for the first module and the proposed fix batches;
- `informe-diagnostico-pruebas.md` — consolidated report for modules 1–9b (findings by cause, discarded hypotheses, fix order).

- Every file starts with `@Tags(['diagnostico'])` + `library;` (tag declared in `dart_test.yaml`). Test names carry the bug ID: `'$capa - diagnostico - $metodo - BUG AS-04 - <correct behaviour>'`.
- They use the same tools as the backend-free suite (doubles, `AdaptadorHttpFalso`, contracts, `integracion/montajeAtenciones.dart`). Exception: the `diagnostico/categorias/remoto_diagnostico_test.dart` (the inscripciones, estadísticas, grupos, cursos and clases ones moved to the remote suite when their bugs closed) run against the **real backend** (they reuse the `prepararVm…` helpers from `main_test.dart`); without the backend they fail in `setUpAll` and their red proves nothing.
- A test can ask for an API that does not exist yet through `dynamic` (e.g. `hayCambiosSinGuardar`), so it compiles and fails with `NoSuchMethodError`. A case that waits for a client rule uses `skip: true` (`testWidgets` only takes a bool) with the reason in a comment.
- A `control` test (e.g. `control AS-01`) must stay green: it proves the mount is valid, so the red of its siblings comes from the app.
- **When a bug is fixed**: its test turns green → move it to `test/unitarias/` or `test/integracion/`, drop the tag and the `BUG` prefix, and set the bug to *corregido* in `registro-bugs.md`. A hypothesis whose test is green from the start is recorded as *descartado*.
- Do not "fix" a red diagnostic test by weakening its assertion: the red is the evidence.

## Architecture

Three layers under `lib/`, dependencies flow presentation → domain → data:

```
presentation/  views + widgets + viewmodels (ChangeNotifier)
domain/        entities (*Entidad) + servicios (Servicio*)
data/          repositories (*Repositorio) + models (*Modelo) + api/conexion (Conexion*)
config/        configApi, inyeccion (composition root), routes, theme
```

**Call chain:** View → `context.read/select<XViewModel>()` → `ServicioX` → `XRepositorio` → `ConexionX` (Dio) → backend.

- `Conexion*` classes speak HTTP and produce `*Modelo` objects (JSON shape, `fromJson`/`toJson`). Interfaces live in `data/api/conexion/interfaces/`, implementations in `remoto/`.
- `*Repositorio` converts `*Modelo` ⇄ `*Entidad`. **Entities never cross into the connection layer and models never reach views** — this mapping is the repository's whole job.
- The conversion itself lives in `data/mappers/<modulo>Mapper.dart`: static `aEntidad` / `aModelo` (plus `aEntidades` for lists where the repository converts several), only the directions that are used, tested in `unitarias/mapper/`. Entities and models never import each other, so `domain/entities/` has no import from `data/`. A new module gets its mapper; don't add `fromModelo` / `fromEntidad` factories.
- `Servicio*` classes are thin pass-throughs today but are **kept on purpose**: they are the injection point between VMs and repositories. Do not confuse them with the "services" of Flutter's architecture guide (those are our `Conexion*`).
- ViewModels hold the state, call services, and expose getters + `notifyListeners()`.
- Image URLs are built by the connection (`urlImagen(id)`) and travel up to the VM; views pass them to `Tarjeta`/`EncabezadoImagen`. Widgets never know the server address. Backend images need the JWT and `Image.network` does not go through Dio, so they are painted with `widgets/imagenRemota.dart` (`ImagenRemota`), which sends `AutenticacionViewModel.autorizacion`; never use `Image.network` directly for them.

### Dependency injection — `lib/config/inyeccion/dependencias.dart`

The composition root, read by `main.dart` as `MultiProvider(providers: [...proveedoresDatos(), ...vmsGlobales()])`. Order matters: data providers come first so a VM's `create` can `context.read` its service.

- `proveedoresDatos()`: one shared `Dio` (`crearClienteHttp()`, 20 s timeouts), `Conexionimagen` (the only connection shared by several services: categoría, curso, `Servicioimagen`), and one `Provider<Servicio*>` per module. 1:1 connections and repositories are built **inside the service's `create`**, with no provider of their own.
- `vmsGlobales()`: **only `AutenticacionViewModel`** (the session, read by the side menu and most screens).
- Every other VM is created **per route** in `route_generator` (`ChangeNotifierProvider(create: (c) => XViewModel(c.read()))`, or a `MultiProvider` when a screen needs several) and disposed when the route pops.

Constructors take their dependencies as **required** parameters (the compiler lists every use). A connection that needs longer timeouts asks per request with `Options(...)` (images 30 s, authentication 1 min).

When adding a module: interface + `remoto/` connection taking `Dio`, mapper in `data/mappers/`, repository, service taking the repository, register the service in `proveedoresDatos()` and in the smoke test, VM taking the service, create the VM in its route.

### RespuestaModelo and Resultado

Every async method in the data and domain layers returns `Future<RespuestaModelo>` (`lib/data/models/respuestaModelo.dart`): `{ codigoHttp, datos, error }`. **Errors are not thrown across layers — they are returned.** Failures come back through the named factories `RespuestaModelo.fromResponse`, `.fromDioException`, `.fromFormatException`, `.fromException`, `.fromObjectError` (the last three take `(exception, metodo, url, capa)`). Do not let exceptions escape a layer.

`fromDioException` turns a rejection into the text to show: the backend's `mensaje`, not the whole JSON (IN-16); a per-field 400 stays JSON because `DialogError` lists each field; an empty body is explained by its code (401 and 403, IN-17). `GC-xxxx` codes do not reach `ErrorModelo`.

Newer VM methods translate that into `Resultado<T>` (`domain/entities/resultado.dart`: `Exito` / `Fallo(codigo, mensaje, origen:)`), so the view gets a resolved message and never reads `ErrorModelo`.

### Screen state

- `EstadoSeccion<T>` (`presentation/viewmodels/estadoSeccion.dart`) is an immutable `{datos, cargando, error}` for anything painted in parts. Widgets read only their section with `context.select`, so they rebuild alone.
- Route VMs mix in `NotificacionSegura`, so a response that arrives after the route was popped doesn't call `notifyListeners` on a disposed notifier.
- Load once — in the route's `create` (`..cargar(...)`) or in the screen's `initState` — never through a `FutureBuilder` created in `build`. Examples: `DetalleGrupoViewModel` (grupo screen), per-grupo maps in `Horariosviewmodel`/`Inscripcionviewmodel`, `EstadisticasViewModel.cargar(inicio, fin)` with a request counter that drops stale responses.

### ViewModel error-handling styles

No ViewModel takes `BuildContext` or calls `showDialog` any more (the last ones, `CategoriaViewModel.cargarCategorias` and `CursosViewModel.listarCursosDe(context, …)`, went on 2026-11-04 with CAT-05 and CU-05). Two return styles remain: older methods return `RespuestaModelo` and the view reads `codigoHttp` (only `registroAlumno` and `login` are still read by a view, deferred with authentication); newer ones return `Resultado` and the view only shows the resolved message. Forms go through one VM entry point that applies the rules and builds the entity (`guardarCategoria`, `guardarCurso`, `registrarGrupo`, `registrarClase`); `agregarCurso`, `insertarGrupo` and `obtenerDeportes` still return `RespuestaModelo` because the remote tests use them to seed data. Use `Resultado` for new code, and keep VMs free of `material.dart`: lists for a `DropdownMenu` are exposed as data (`titulos`, `nombresCursos`) and the view builds the entries.

### Backend selection

`lib/config/configApi.dart`: `ConfigApi.baseUrl` is `http://$API_HOST:8082/api/v2`, fixed at compile time with `--dart-define=API_HOST=...` (default `10.0.2.2`, the Android-emulator alias for the host). It is the only source of the URL; tests pass their own to `crearClienteHttp(baseUrlPruebas)`.

### Routing

The app starts at `AppRutas.categorias` (`onGenerateInitialRoutes` keeps `/categorias` from stacking `/` first). Named routes only: constants in `config/routes/app_rutas.dart`, all built in `generateRoute` (`config/routes/route_generator.dart`). Arguments are passed with `Navigator.pushNamed(..., arguments: x)` and **cast unguarded** in the switch (`settings.arguments as CursoEntidad`) — a wrong type is a runtime crash, so add the constant and the case together. Routes needing several arguments use a wrapper class in `domain/entities/entidadesRutas/`. The `default` case opens categorías.

A pushed route is not under the previous route's providers: a form that changes data pops `true` and the screen below reloads its own VM.

### Auth

Login with Google: `GoogleSignIn` is built with `serverClientId: ConfigApi.googleServerClientId` (the **web** OAuth client of the Google Cloud project that also holds the Android client; overridable with `--dart-define=GOOGLE_SERVER_CLIENT_ID=...`) so Android hands out an ID Token. `AutenticacionViewModel.login()` sends it to `POST /auth/token` (`Conexionautenticacion.intercambiarToken`), which answers `{token, perfil}`; the repository stores the JWT in `AlmacenToken` (`data/api/sesion/`, a root provider) and `InterceptorToken` on the shared `Dio` adds `Authorization: Bearer <jwt>` to every request (it never overwrites a header the connection set). The token lives in memory only: `verificarSesion` gets a new one on start, `logout` clears it, and after a 201 registration the VM exchanges the token again. Plain-email login still calls `GET /login`, which the current backend rejects with 401. The result is a `PerfilEntidad` with `role`. Role gating is UI-level only, via `perfilSesion?.role ==` the constants in `config/routes/roles.dart` (`Coordinador` / `Instructor` / `Alumno`) — see `widgets/menuLateral.dart`, which also drives the login/registration flow. A 404 from login (or from `/auth/token`) means "not registered" and pushes `AppRutas.autenticacionRegistro`. In tests, `CuentaGoogleFalsa` (in `dobles/googleSignInFalso.dart`) gives an account with an `idToken`, `PeticionRegistrada.autorizacion` shows the `Authorization` that went out, and `MontajeAutenticacion` shares one `AlmacenToken` + interceptor across its connections.

### Leftovers kept on purpose

These no longer affect the running app but are **kept by decision** — don't delete them unless asked:

- `lib/data/api/fabrica/` (`ConexionFabricaAbstracta` and its two factories): no methods left; only its `SERVICIO_REMOTO`/`SERVICIO_LOCAL` constants are read.
- `lib/config/configServicio.dart`: nothing reads it any more (`obtenerBaseApi()` has no callers); `page1` still writes to it.
- `page1.dart` / `page2.dart` (dev screens, routes `AppRutas.page1/page2`): unreachable from the app, and the IP typed in `page1` is ignored — the backend comes from `--dart-define`. `shared_preferences` is only used by `page1`.
- `lib/data/api/conexion/local/`: old in-memory connections, nothing creates them.
- `MyHomePage` in `main.dart`: unused counter template.
- Classes with no consumers yet (`Servicioimagen`, `Alumnosviewmodel`) stay for future features. Dead **methods** in a VM, however, are removed when their module is touched.

## Naming conventions

Naming is inconsistent by history, not by rule. Classes appear as `CategoriaViewModel`, `Gruposviewmodel`, `categoriaModelo`, `Conexiongruposremoto` — all in the same codebase; file names mix `camelCase.dart`, `PascalCase.dart` and `snake_case.dart`. Don't refactor these wholesale; match whatever the file/feature you're touching already uses. Domain suffixes are stable and should be kept: `*Entidad`, `*Modelo`, `*Repositorio`, `Servicio*`, `Conexion*` (+ `Remoto`), `*ViewModel`.
