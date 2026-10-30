# Auditoría MVVM · Capa ViewModel · Criterios C1–C4

- **Estado auditado:** árbol de trabajo en disco sobre `ee32c5d` (rama `main`), con cambios sin commit.
- **Alcance:** `lib/presentation/viewmodels/` (14 clases) y los widgets de View que las consumen.
- **Convención de citas:** rutas relativas a la raíz del proyecto. Todo veredicto se apoya en `archivo:línea`.
- **Aclaración sobre PASO 1:** la búsqueda literal de `extends ChangeNotifier` devuelve **0 resultados**. Las 14 clases usan el mixin `with ChangeNotifier`. El inventario se construyó con ese patrón más el nombre de archivo.

---

## PASO 1 — Inventario de clases candidatas

| # | Clase | Archivo | Líneas | Patrón |
|---|---|---|---|---|
| 1 | `CategoriaViewModel` | `lib/presentation/viewmodels/categoriaViewModel.dart:10` | 279 | `with ChangeNotifier` |
| 2 | `CursosViewModel` | `lib/presentation/viewmodels/cursosViewModel.dart:9` | 198 | `with ChangeNotifier` |
| 3 | `EstadisticasViewModel` | `lib/presentation/viewmodels/estadisticasViewModel.dart:10` | 174 | `with ChangeNotifier` |
| 4 | `Gruposviewmodel` | `lib/presentation/viewmodels/gruposViewModel.dart:8` | 154 | `with ChangeNotifier` |
| 5 | `AutenticacionViewModel` | `lib/presentation/viewmodels/autenticacionViewModel.dart:7` | 135 | `with ChangeNotifier` |
| 6 | `Clasesviewmodel` | `lib/presentation/viewmodels/clasesViewModel.dart:8` | 100 | `with ChangeNotifier` |
| 7 | `Atencionviewmodel` | `lib/presentation/viewmodels/atencionViewModel.dart:8` | 80 | `with ChangeNotifier` |
| 8 | `Inscripcionviewmodel` | `lib/presentation/viewmodels/inscripcionViewModel.dart:6` | 62 | `with ChangeNotifier` |
| 9 | `Imagenviewmodel` | `lib/presentation/viewmodels/imagenViewModel.dart:6` | 43 | `with ChangeNotifier` |
| 10 | `Facultadesviewmodel` | `lib/presentation/viewmodels/facultadesViewModel.dart:5` | 41 | `with ChangeNotifier` |
| 11 | `InstructoresViewModel` | `lib/presentation/viewmodels/instructores_view_model.dart:5` | 40 | `with ChangeNotifier` |
| 12 | `Horariosviewmodel` | `lib/presentation/viewmodels/horariosViewModel.dart:5` | 34 | `with ChangeNotifier` |
| 13 | `Alumnosviewmodel` | `lib/presentation/viewmodels/alumnosViewModel.dart:5` | 33 | `with ChangeNotifier` |
| 14 | `Deporteviewmodel` | `lib/presentation/viewmodels/deporteViewModel.dart:5` | 11 | `with ChangeNotifier` |

Las 14 están registradas como `ChangeNotifierProvider` globales en `lib/main.dart:36-49`.

Único archivo con nomenclatura `*_view_model.dart`: `instructores_view_model.dart`. El resto usa `camelCase*ViewModel.dart`.

---

## PASO 2 — Mapa de consumo (View ↔ ViewModel)

| ViewModel | Consumido en | Forma de acceso |
|---|---|---|
| `CategoriaViewModel` | `CategoriaFormulario.dart:53`, `CategoriasView.dart:34,51`, `inscripcionesGeneralesView.dart:31,41`, `inscripcionesParticulares.dart:30,38` | `Provider.of` + `Consumer` |
| `CursosViewModel` | `curso/cursos.dart:68,80` | `Provider.of` (con `listen:true` en `build`, L80) |
| `EstadisticasViewModel` | `estadisticas/estadisticasGeneralesView.dart:47` | `Consumer` |
| `Gruposviewmodel` | `curso/widgetListaGrupos.dart:27,37`, `grupo/GrupoFormulario.dart:257`, `grupos/GruposAsignados.dart:35,52`, `grupos/GruposInscripcion.dart:34,51` | `Provider.of` + `Consumer` |
| `AutenticacionViewModel` | `autenticacion/AutenticacionView.dart:38`, `CategoriasView.dart:39,62,112`, `curso/cursos.dart:91`, `widgets/menuLateral.dart:25` | `Provider.of` + `Consumer` |
| `Clasesviewmodel` | `grupo/widgetListaClases.dart:28,42,86,136,175` | `Provider.of` + `Consumer` |
| `Inscripcionviewmodel` | `grupos/GruposInscripcion.dart:139` | `Consumer` |
| `Facultadesviewmodel` | `autenticacion/AutenticacionView.dart:48,98` | `Provider.of` + `Consumer` |
| `InstructoresViewModel` | `grupo/GrupoFormulario.dart:52,110` | `Provider.of` + `Consumer` |
| `Horariosviewmodel` | `grupos/GruposAsignados.dart:108`, `grupos/GruposInscripcion.dart:107` (`Consumer`, sin uso de estado); **instanciado a mano** en `grupo/widgetListaHorarios.dart:20` | mixto |
| `Imagenviewmodel` | **instanciado a mano** en `widgets/imagenTarjeta.dart:18`; el acceso por Provider está comentado en `imagenTarjeta.dart:23` | `AnimatedBuilder` sobre instancia propia (`imagenTarjeta.dart:32-33`) |
| `Alumnosviewmodel` | **instanciado a mano** en `grupo/widgetListaAlumnos.dart:50`, dentro de un método de construcción | ninguna (`FutureBuilder`) |
| `Atencionviewmodel` | **instanciado a mano** en `clase/claseView.dart:36` y `claseView.dart:143` | ninguna (`FutureBuilder`) |
| `Deporteviewmodel` | **instanciado a mano** en `curso/FormularioCurso.dart:47` | ninguna (`FutureBuilder`) |

**Observación de alcance:** 4 ViewModels (`Alumnosviewmodel`, `Atencionviewmodel`, `Deporteviewmodel`, `Imagenviewmodel`) están registrados en `main.dart:41-46` pero **ninguna View los toma del árbol de Provider**; cada widget construye su propia instancia. El registro global es, para ellos, código muerto.

---

## PASO 3 y 4 — Evaluación por ViewModel

### 1. `CategoriaViewModel` — `lib/presentation/viewmodels/categoriaViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 · Estado, comandos y notificación | **Cumple parcialmente** | Estado privado + getters: `categoriaViewModel.dart:15-17,20-22,24-25,27-28`. Comandos públicos: `:97,118,230,243`. Mutación sin notificar: `:56` y `:69` llaman `_establecerCategorias` (que escribe `_categorias` y `_listaEntradas`, `:261-264`) y **no** emiten `notifyListeners()`; sólo la rama de éxito notifica (`:40`). `eliminarCategoria` (`:243-255`) no notifica ni refresca. | (c) se cumple: los dos `notifyListeners()` de `listarYNotificarCategorias` (`:100`, `:115`) están separados por un `await` (`:102`). **Corrección:** mover el `notifyListeners()` al final de `cargarCategorias` fuera del `if/else`, o hacer que `_establecerCategorias` (`:261`) notifique siempre; y que `eliminarCategoria` refresque la lista como hacen `insertarCategoria` (`:122`) y `actualizarCategoria` (`:235`), en vez de delegarlo a `CategoriasView.dart:196`. |
| C2 · Coordinación con el Model | **Cumple** | Sin `http.`/`Dio(`/`FirebaseFirestore`/`sqflite` en el archivo. Delega en `ServicioCategoria`: campo `:12`, construcción `:31`, invocaciones `:36,102,120,232,248`. | Import sin usar: `servicioImagen.dart` (`:2`). **Corrección:** eliminarlo. |
| C3 · E/S asíncrona | **Cumple parcialmente** | `async`/`await` en `:33,97,118,230,243`. Sin métodos `*Sync`. `_cargando=true` antes del `await` en `:98` vs `:102`, y `false` en `:114` — **fuera de `finally`**. `cargarCategorias` (`:33-95`) no toca `_cargando` en ningún punto. | **Corrección:** envolver el cuerpo de `listarYNotificarCategorias` en `try/finally` con `_cargando=false; notifyListeners();` en el `finally`, y dar estado de carga a `cargarCategorias` (hoy la View compensa con `categorias == null`, `CategoriasView.dart:84`). |
| C4 · Adaptación y desacople de la View | **No cumple** | `import 'package:flutter/material.dart'` (`:3`); imports de widgets `dialogCargando.dart` (`:7`) y `dialogError.dart` (`:8`). `cargarCategorias(context)` recibe contexto (`:33`) y ejecuta `showDialog` en `:43,57,70,84`. Tipo de UI como campo público: `List<DropdownMenuEntry>` en `:20,22`, construido en `:266-278`. | Sí hay adaptación (`_cargarEntradas`, `:266`), pero produce un widget de Material en vez de un DTO. **Corrección:** (a) convertir `cargarCategorias` al estilo que retorna `RespuestaModelo` —como `insertarCategoria` (`:118`)— y mover los diálogos a `CategoriasView`; (b) sustituir `DropdownMenuEntry` por una lista de `String`/DTO propio y que la View construya el widget, igual que ya hace `AutenticacionView.dart:118-126` con las facultades. Los `showDialog` de `:143,155,170,184` están dentro del bloque comentado `:135-197` y no cuentan; conviene borrar ese bloque muerto. |

### 2. `CursosViewModel` — `lib/presentation/viewmodels/cursosViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple parcialmente** | Getters `:17,19`. Comandos `:24,34,39,108,148`. `listarTodosCursos` y `listarCursosDe` notifican en `finally` (`:104`, `:144`). Pero `agregarCurso` (`:34-37`) **no notifica ni refresca** la lista tras un alta. No existe estado `cargando`/`error` público. | Callback de la View correcto en `cursos.dart:74`. **Corrección:** tras un 201 en `agregarCurso`, invocar la recarga (`listarCursosDe`) como hace `categoriaViewModel.dart:122`; añadir `_cargando`/`_error` con getters. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `ServicioCurso`: `:11,22` y llamadas `:26,35,43,112,151`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:24,34,39,108,148`; sin métodos `*Sync`. **No existe ningún indicador de carga** en la clase; los `finally` (`:102`, `:142`) sólo recalculan entradas y notifican. | **Corrección:** introducir `_cargando` activado antes de cada `await` y apagado en el `finally` ya existente, y exponerlo por getter para que la View deje de inferir el estado de carga por otros medios. |
| C4 | **No cumple** | `import 'package:flutter/material.dart'` (`:3`) e import de `dialogError.dart` (`:7`). `context` como parámetro en `:39,108,180`. `showDialog` en `:49,63,76,92,181`. `List<DropdownMenuEntry>` como campo y getter en `:15,19`, construido en `:166-178`. | **Corrección:** misma que en `CategoriaViewModel`: métodos que devuelvan `RespuestaModelo`, diálogos en la View, y exponer los datos del desplegable como lista de `String` en vez de `DropdownMenuEntry`. |

### 3. `EstadisticasViewModel` — `lib/presentation/viewmodels/estadisticasViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple parcialmente** | Getters `:158-164`. `cargarGeneralCategorias` y `cargarCursosGenerales` notifican en `finally` (`:83`, `:102`). Pero `estadisticasGrupos` **muta `_listEstadisticasGeneralesCategorias` en `:64-65` sin `notifyListeners()`**. `_cargarCategorias` (`:145-155`) hace `add` acumulativo sobre `_listCategorias` (`:152`) sin limpiarla antes: en cada carga duplica las entradas. | **Corrección:** notificar tras la mutación de `:64`; en `_cargarCategorias`, reconstruir la lista (`_listCategorias = [...]`) en vez de acumular. Además `:147` y `:154` dejan `print` de depuración. |
| C2 | **Cumple parcialmente** | Delega en `ServicioEstadisticas` (`:13,21,37,48,59,73,89`). Pero `export()` (`:23-31`) orquesta la exportación a Excel —`ExcelExport()` `:25`, `llenarHoja` `:26`, `exportarEstadisticasAExcel` `:27`, `guardarArchivoExcel` `:28`— y manipula `File` de `dart:io` (`:1,27`), que escribe en disco (`lib/domain/excel.dart:50-56`). | No es acceso HTTP, pero sí E/S de archivos y una regla de negocio (la condición `isNotEmpty` de `:24` decide si hay algo que exportar) dentro del ViewModel. **Corrección:** mover la orquestación completa a un `ServicioExportacion` que devuelva `bool`/`RespuestaModelo`, y que el ViewModel sólo lo invoque. |
| C3 | **Cumple parcialmente** | `async`/`await` en `:23,33,44,55,71,87`; sin métodos `*Sync`. **No hay indicador de carga** en ninguna operación; los `finally` de `:82` y `:101` sólo notifican. `_manejarRepuestaEstadistica` (`:106-142`) es síncrono y dispara diálogos. | **Corrección:** añadir `_cargando` activado antes del `await` (`:73`, `:89`) y apagado en los `finally` que ya existen. La View hoy suple esto con `!promesa.hasData` (`estadisticasGeneralesView.dart:140`). |
| C4 | **No cumple** | `import 'package:flutter/material.dart'` (`:4`) e import de `dialogError.dart` (`:8`). `context` como parámetro en `:71,87,107,166`. `showDialog` en `:167`. `List<DropdownMenuEntry>` como campo y getter en `:18,164`, construido en `:148-151`. | La adaptación real a formato de gráfico vive **en la View**: `estadisticasGeneralesView.dart:146-147,175-177,205-207` convierte `List<Estadistica>` en `List<EstadisticaGraficoargumentos>`. **Corrección:** subir esos tres `formato*` al ViewModel como getters y quitar `context`/`showDialog` de `:166-173`. Nota aparte: la View invoca al ViewModel dentro de `build` (`estadisticasGeneralesView.dart:138,167,197`), lo que relanza la petición en cada reconstrucción. |

### 4. `Gruposviewmodel` — `lib/presentation/viewmodels/gruposViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple parcialmente** | Getters `:12,15,21`; comandos `:25,63,97,131`; 15 `notifyListeners()`, uno por cada rama que muta estado (`:33,39,46,52,58,66,72,82,88,93,100,109,116,122,127`). Fallo: `insertarGrupo` (`:131-153`) llama `listarGruposDe` en `:143` **sin `await`**, así que retorna antes de que la lista se recargue y el `Consumer` puede pintar datos viejos. | **Corrección:** `await listarGruposDe(...)` en `:143`, y condicionar el refresco al `codigoHttp == 201`. Quitar los `print` de `:134-139`. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Serviciogrupo`: `:9,23` y llamadas `:35,70,104,142`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:25,63,97,131`; sin métodos `*Sync`. **`gruposViewModel.dart:31` escribe `_cargando == true;` — es una comparación, no una asignación**: en `listarGruposDe` el indicador de carga nunca se activa. En `:63` y `:97` sí se activa (`:64`, `:98`) pero se apaga repitiendo `_cargando=false` en cada rama (`:72,80,85,91,105,113,119,125`), **sin `finally`**. | **Corrección:** cambiar `:31` por `_cargando = true;` y refactorizar los tres listados a `try { ... } finally { _cargando = false; notifyListeners(); }`, eliminando las ocho asignaciones repetidas. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, sin `showDialog`, sin tipos de UI en campos ni parámetros. Pero importa `package:flutter/material.dart` (`:6`) y `dialogError.dart` (`:5`), **ninguno usado** (0 `showDialog` en el archivo). No hay getters de adaptación: `getListaGrupos` (`:21`) expone la lista de entidades cruda. | **Corrección:** sustituir el import de `material.dart` por `package:flutter/foundation.dart` —como ya hace `horariosViewModel.dart:3`— y borrar el de `dialogError.dart`. La composición del texto de cada tarjeta se hace hoy en la View (`GruposInscripcion.dart:130-133`); es candidata a subir como getter. |

### 5. `AutenticacionViewModel` — `lib/presentation/viewmodels/autenticacionViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **No cumple** | El estado es **público y mutable**, sin encapsular: `cuenta` `:11`, `perfilSesion` `:12`, `error` `:13`; cualquier View puede escribirlos. Mutaciones sin notificar: `:30-32` (`verificarSesion`), `:45,50-52,55-57` (`loginGoogle`), `:74-76` (`prepararLoginConCorreo`), `:36` y `:61` (asignación de `error`). Sólo notifican `logout` (`:87`), `login` en éxito (`:105`) y `registroAlumno` en éxito (`:124`). | Además (b): el flujo de inicio de sesión se orquesta **en el widget** — `menuLateral.dart:151-185` encadena elección de método, `loginGoogle()`, `prepararLoginConCorreo()` y `_procesarLoginBackend`, y `menuLateral.dart:193-232` decide navegación y `logout` según `codigoHttp`. **Corrección:** hacer privados los tres campos con getters, notificar en cada mutación (sobre todo en las ramas de error de `:36,61`), y exponer un único comando `iniciarSesion(metodo, correo)` que encapsule el encadenamiento de `menuLateral.dart:151-232`. |
| C2 | **Cumple parcialmente** | Delega el backend en `Servicioautenticacion` (`:8,102,120`), sin `http.`/`Dio(`. Pero instancia y consume **directamente el SDK de Google** en el ViewModel: `GoogleSignIn(...)` `:9`, `signInSilently()` `:28`, `signIn()` `:45`, `signOut()` `:81`. | Es el mismo antipatrón que un `Dio()` embebido: acceso a un proveedor externo sin repositorio ni servicio intermedio, imposible de sustituir en pruebas. **Corrección:** encapsularlo en un `ServicioGoogle`/`ConexionGoogle` inyectable, en línea con la fábrica usada por el resto de conexiones. |
| C3 | **Cumple parcialmente** | `async`/`await` en `:23,41,80,90,118`; sin métodos `*Sync`. **No existe ningún `cargando`** en la clase, pese a que `:28,45,81,102,120` son operaciones de red. | La View tampoco tiene con qué bloquear el botón mientras corre el login (`menuLateral.dart:158`). **Corrección:** añadir `_cargando` con getter, activarlo antes de cada `await` y apagarlo en `finally`. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, sin `showDialog`, sin `Widget`/`Color`/`TextStyle`. Sí hay getters de adaptación: `correoAutenticado` `:19`, `nombreAutenticado` `:20`, `fotoPerfil` `:21` (consumido en `menuLateral.dart:133-134`). Fallos: importa `package:flutter/material.dart` (`:4`) sin necesitarlo, y expone el tipo del SDK externo `GoogleSignInAccount? cuenta` (`:11`) hacia la View. | Es el ViewModel más limpio del conjunto en este criterio. **Corrección:** cambiar `:4` por `flutter/foundation.dart` y hacer `cuenta` privada, sirviendo sólo los getters de `:19-21`. Quitar los `print` de `:47-49`. |

### 6. `Clasesviewmodel` — `lib/presentation/viewmodels/clasesViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple parcialmente** | Getters `:13,16,19`; comandos `:27,41,52,65`; notificaciones en `:71,76,98`. Fallos: `inicializarGrupo` (`:27-39`) muta cinco campos (`:34-38`) sin notificar, y `eliminarClase` (`:41-50`) no notifica ni refresca tras un borrado exitoso. | El refresco tras borrar lo hace la View: `widgetListaClases.dart:66-67` y `:105-106`. **Corrección:** que `eliminarClase` recargue como `guardarClase` (`:56-58`). `inicializarGrupo` puede quedarse sin notificar si se documenta que sólo fija parámetros de consulta. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Servicioclase`: `:9,10` y llamadas `:44,54,79`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:41,52,65`; sin métodos `*Sync`. `_cargando=true` en `:74` antes del `await` de `:79`, y `false` en `:97` **fuera de `finally`**. La salida temprana de `:66-73` retorna sin tocar `_cargando`. | **Corrección:** `try/finally` alrededor de `:78-95` con el apagado del indicador en el `finally`. |
| C4 | **Cumple parcialmente** | Sin `BuildContext` ni `showDialog` (0 en el archivo) ni tipos de UI. Pero importa `package:flutter/material.dart` (`:6`), `dialogError.dart` (`:4`) y `dialogExito.dart` (`:5`), **los tres sin usar**. Sin getters de adaptación: `clases` (`:13`) entrega entidades crudas. | El formateo de fecha y duración se hace en la View (`widgetListaClases.dart:46-47`). **Corrección:** borrar los tres imports y, si se quiere cumplir del todo, exponer las clases ya formateadas. |

### 7. `Atencionviewmodel` — `lib/presentation/viewmodels/atencionViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **No cumple** | La clase **no tiene ningún campo de estado, ningún getter y ningún `notifyListeners()`** (0 ocurrencias en el archivo); usa `ChangeNotifier` (`:8`) sin ejercerlo. Los dos comandos (`:12`, `:39`) sólo retornan `RespuestaModelo`. El estado vive en la View: `claseView.dart:31` guarda `_atenciones` y lo **asigna dentro del `builder` del `FutureBuilder`** (`claseView.dart:118`). | **Corrección:** subir `_atenciones`, `_cargando` y `_error` al ViewModel con getters, y que `claseView` consuma un `Consumer<Atencionviewmodel>` en vez de `FutureBuilder`. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Servicioatencion`: `:9,10` y llamadas `:21,46`. | El campo `:9` no es `final`. **Corrección menor:** marcarlo `final`. |
| C3 | **Cumple parcialmente** | `async`/`await` en `:12,39`; sin métodos `*Sync`. No existe indicador de carga; lo suple el `FutureBuilder` de `claseView.dart:87`. | **Corrección:** añadir `_cargando` junto con el estado de C1. |
| C4 | **No cumple** | `import 'package:flutter/material.dart'` (`:6`) e import de `dialogError.dart` (`:5`). `registrarAtenciones` recibe `context` como primer parámetro (`:40`) —sin tipar y sin usarlo en el cuerpo—. `_mostrarError(context, ...)` con `showDialog` en `:62-78`, método muerto (su única llamada está comentada en `:52`). Sin adaptación: devuelve `RespuestaModelo`, un tipo de la capa `data`, que la View castea a mano (`claseView.dart:116-117`). | **Corrección:** borrar `_mostrarError` (`:62-78`) y el parámetro `context` de `:40`, y devolver entidades ya adaptadas en vez de `RespuestaModelo`. |

### 8. `Inscripcionviewmodel` — `lib/presentation/viewmodels/inscripcionViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple parcialmente** | Getters `:10,13,16`; comandos `:18,38,51`; notificaciones `:23,35,43,46`. Fallos: el `catch` de `agregarIncripcion` (`:32-34`) fija `_error` pero **deja `_cargando` en `true`**; `desvincularInscripcion` emite `notifyListeners()` en `:43` y `:46` **sin haber mutado ningún campo** (notificación espuria que reconstruye la View sin motivo); `validarInscripcion` (`:51-61`) no expone su resultado como estado. | (b) incumplido: el callback de `GruposInscripcion.dart:157-194` llama al comando y luego **inspecciona el estado del ViewModel para decidir tres diálogos**; el `if (vm.cargando)` de `:162` se evalúa después del `await`, cuando ya es `false`, así que ese `DialogCargando` nunca aparece. **Corrección:** apagar `_cargando` en un `finally`; retirar los `notifyListeners()` de `:43,46` o mutar estado real; y sustituir la cadena de `if` de la View por un único resultado devuelto por el comando. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Servicioinscripcion`: `:7` y llamadas `:24,40,53`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:18,38,51`; sin métodos `*Sync`. `_cargando=true` en `:21` antes del `await` de `:24`; `false` en `:25` **inmediatamente tras el `await` y fuera de `finally`**, y nunca en la rama de excepción. | **Corrección:** `try { ... } finally { _cargando = false; notifyListeners(); }`. Nota: `GruposInscripcion.dart:142` invoca `validarInscripcion` dentro de `build`, relanzando la petición en cada reconstrucción. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, `showDialog` ni tipos de UI. Pero importa `package:flutter/material.dart` (`:4`) sin necesitarlo. Sin getters de adaptación: expone `_codigoInsercion` (`:16`), un código HTTP crudo que la View interpreta (`GruposInscripcion.dart:170,186`). | **Corrección:** cambiar el import a `flutter/foundation.dart` y reemplazar `codigoInsercion` por un estado de dominio (`enum EstadoInscripcion`) o un mensaje ya formateado. |

### 9. `Imagenviewmodel` — `lib/presentation/viewmodels/imagenViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple parcialmente** | Getters `:10,13,16`; comando `:20`; notificaciones `:23` y `:41`, separadas por el `await` de `:26` (cumple (c)). Fallos de forma: `_servicioImagen` no es `final` (`:7`) y hay `print` de depuración en `:28-29`. | (b): el widget **no usa el Provider registrado** — `imagenTarjeta.dart:18` construye su propia instancia y la línea del Provider está comentada en `imagenTarjeta.dart:23`; cada tarjeta de la lista crea un ViewModel y una petición propios. **Corrección:** consumir la instancia del árbol o registrar el ViewModel por tarjeta de forma explícita; marcar `:7` como `final` y borrar los `print`. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Servicioimagen`: `:7,26`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:20`; sin métodos `*Sync`. `_cargando=true` en `:21` antes del `await` de `:26`, apagado en `:40` **fuera de `finally`**. | **Corrección:** mover `:40-41` a un bloque `finally`. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, `showDialog` ni tipos de UI. Pero importa `package:flutter/material.dart` (`:4`) sin necesitarlo. Sin getters de adaptación: expone `ImagenEntidad` cruda (`:13`) y la View extrae los bytes. | **Corrección:** cambiar el import a `flutter/foundation.dart`; opcionalmente exponer directamente los bytes que la View necesita. |

### 10. `Facultadesviewmodel` — `lib/presentation/viewmodels/facultadesViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple** | Estado privado con getters: `:8-9,11-12,14-15`. Comando público único `:19`. Toda mutación queda cubierta por `notifyListeners()`: `:22` tras `:20-21`, `:39` tras `:27-38`. Los dos avisos están separados por el `await` de `:25`, así que no hay dos notificaciones en un mismo tramo síncrono. La View sólo delega: `AutenticacionView.dart:52`. | — |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Serviciofacultades`: `:6,25`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:19`; sin métodos `*Sync`. `_cargando=true` en `:20` antes del `await` de `:25`, pero se apaga en `:38` **fuera de `finally`**: cualquier fallo no capturado por el `catch` de `:33` dejaría el indicador encendido. | **Corrección:** `try { ... } catch { ... } finally { _cargando = false; notifyListeners(); }`. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, `showDialog` ni tipos de UI en campos ni parámetros. Pero importa `package:flutter/material.dart` (`:3`) sin necesitarlo. No hay getters que adapten: expone `List<String>` cruda (`:9`) y es la View quien arma las entradas del desplegable (`AutenticacionView.dart:118-126`). | **Corrección:** cambiar `:3` por `package:flutter/foundation.dart`. La adaptación en la View es defendible porque el tipo destino es un widget; documentarlo o moverlo a un mapeador de la capa de presentación. |

### 11. `InstructoresViewModel` — `lib/presentation/viewmodels/instructores_view_model.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **Cumple** | Estado privado con getters: `:8-9,11-12,14-15`. Comando público único `:19`. `notifyListeners()` en `:22` y `:38`, separados por el `await` de `:25`; todas las ramas de `:26-36` quedan cubiertas por el aviso de `:38`. La View delega sin lógica propia: `GrupoFormulario.dart:56`. | — |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `ServicioInstructor`: `:6,25`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:19`; sin métodos `*Sync`. `_cargando=true` en `:20` antes del `await` de `:25`, apagado en `:37` **fuera de `finally`**. | **Corrección:** igual que en `Facultadesviewmodel`: apagar el indicador en un `finally`. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, `showDialog` ni tipos de UI. Importa `package:flutter/material.dart` (`:3`) sin necesitarlo. Sin getters de adaptación: expone `List<Instructorentidad>` cruda (`:9`) y la View compone el desplegable (`GrupoFormulario.dart:126`). | **Corrección:** cambiar `:3` por `package:flutter/foundation.dart`. |

### 12. `Horariosviewmodel` — `lib/presentation/viewmodels/horariosViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **No cumple** | **Sin campos de estado, sin getters y con 0 `notifyListeners()`** en el archivo; usa `ChangeNotifier` (`:5`) sin ejercerlo. El único comando (`:10`) devuelve `Future<RespuestaModelo>`. El servicio es campo **público** (`:6`). La View lo instancia dentro del método de construcción — `widgetListaHorarios.dart:20`, invocado desde `build` (`:15-16`) — así que se crea un ViewModel nuevo y se relanza la petición en cada reconstrucción; los `Consumer<Horariosviewmodel>` de `GruposAsignados.dart:108` y `GruposInscripcion.dart:107` escuchan una instancia que nunca notifica. | **Corrección:** añadir `_horarios`, `_cargando` y `_error` con getters y un comando `listarYNotificarHorarios(...)`, y consumir la instancia del Provider en vez de crear una nueva; hacer privado el campo de `:6`. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Serviciohorario`: `:6,8,18`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:10`; sin métodos `*Sync`. No existe indicador de carga; lo suple el `FutureBuilder` de `widgetListaHorarios.dart:28-30`. | **Corrección:** añadir `_cargando` junto con el estado de C1. |
| C4 | **Cumple parcialmente** | **Único ViewModel sin import de UI**: usa `package:flutter/foundation.dart` (`:3`). Sin `BuildContext` ni tipos de UI. Pero no adapta nada: devuelve `RespuestaModelo` (capa `data`) y la View hace el casteo y el formato (`widgetListaHorarios.dart:42-45`). | **Corrección:** exponer `List<Horarioentidad>` ya convertida, o un DTO de presentación, en vez de `RespuestaModelo`. El import de `:3` es el patrón que deberían seguir los otros 13. |

### 13. `Alumnosviewmodel` — `lib/presentation/viewmodels/alumnosViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **No cumple** | **Sin campos de estado, sin getters y con 0 `notifyListeners()`**; `ChangeNotifier` en `:5` sin ejercer. Único comando `:9`, que sólo retorna. La View lo construye dentro de `listadoAlumnos()` (`widgetListaAlumnos.dart:50`), método llamado desde el árbol de construcción, de modo que cada reconstrucción crea una instancia y repite la petición (`widgetListaAlumnos.dart:52-57`). | **Corrección:** mover la lista, el indicador de carga y el error al ViewModel con getters; consumirlo con `Consumer` desde el Provider ya registrado en `main.dart:41`. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Servicioalumno`: `:6,7,17`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:9`; sin métodos `*Sync`. No hay indicador de carga; lo suple el `FutureBuilder` de `widgetListaAlumnos.dart:59-60`. | **Corrección:** añadir `_cargando` con getter, activado antes del `await` de `:17` y apagado en `finally`. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, `showDialog` ni tipos de UI. Importa `package:flutter/material.dart` (`:3`) sin necesitarlo. Sin adaptación: devuelve `RespuestaModelo` y la View interpreta el código HTTP y castea (`widgetListaAlumnos.dart:72-75`). | **Corrección:** cambiar `:3` por `flutter/foundation.dart` y exponer entidades ya listas para pintar. |

### 14. `Deporteviewmodel` — `lib/presentation/viewmodels/deporteViewModel.dart`

| Criterio | Veredicto | Evidencia (archivo:línea) | Observaciones |
|---|---|---|---|
| C1 | **No cumple** | Clase de 11 líneas: **sin campos de estado, sin getters y con 0 `notifyListeners()`**; `ChangeNotifier` en `:5` sin ejercer. El único método (`:8-10`) es un reenvío de una línea al servicio. La View lo instancia a mano en `FormularioCurso.dart:47`. | **Corrección:** o se le da estado (`_deportes`, `_cargando`, `_error` + getters) y se consume por Provider, o se elimina la clase; mantenerla como reenvío sin estado no aporta nada sobre llamar al servicio directamente. |
| C2 | **Cumple** | Sin acceso directo a red. Delega en `Serviciodeporte`: `:6,9`. | — |
| C3 | **Cumple parcialmente** | `async`/`await` en `:8-9`; sin métodos `*Sync`. Sin indicador de carga (la clase no tiene estado). | **Corrección:** ligada a la de C1. |
| C4 | **Cumple parcialmente** | Sin `BuildContext`, `showDialog` ni tipos de UI. Importa `package:flutter/material.dart` (`:3`) sin necesitarlo. Sin adaptación: devuelve `RespuestaModelo` directamente a la View. | **Corrección:** cambiar `:3` por `flutter/foundation.dart` y devolver la lista de deportes ya convertida. |

---

## PASO 5 — Tabla resumen

| ViewModel | C1 Estado/comandos | C2 Model | C3 Asíncrono | C4 Desacople |
|---|---|---|---|---|
| `CategoriaViewModel` | Cumple parcialmente | Cumple | Cumple parcialmente | **No cumple** |
| `CursosViewModel` | Cumple parcialmente | Cumple | Cumple parcialmente | **No cumple** |
| `EstadisticasViewModel` | Cumple parcialmente | Cumple parcialmente | Cumple parcialmente | **No cumple** |
| `Gruposviewmodel` | Cumple parcialmente | Cumple | Cumple parcialmente | Cumple parcialmente |
| `AutenticacionViewModel` | **No cumple** | Cumple parcialmente | Cumple parcialmente | Cumple parcialmente |
| `Clasesviewmodel` | Cumple parcialmente | Cumple | Cumple parcialmente | Cumple parcialmente |
| `Atencionviewmodel` | **No cumple** | Cumple | Cumple parcialmente | **No cumple** |
| `Inscripcionviewmodel` | Cumple parcialmente | Cumple | Cumple parcialmente | Cumple parcialmente |
| `Imagenviewmodel` | Cumple parcialmente | Cumple | Cumple parcialmente | Cumple parcialmente |
| `Facultadesviewmodel` | **Cumple** | Cumple | Cumple parcialmente | Cumple parcialmente |
| `InstructoresViewModel` | **Cumple** | Cumple | Cumple parcialmente | Cumple parcialmente |
| `Horariosviewmodel` | **No cumple** | Cumple | Cumple parcialmente | Cumple parcialmente |
| `Alumnosviewmodel` | **No cumple** | Cumple | Cumple parcialmente | Cumple parcialmente |
| `Deporteviewmodel` | **No cumple** | Cumple | Cumple parcialmente | Cumple parcialmente |

**Conteo (14 ViewModels × 4 criterios = 56 veredictos):**

| Criterio | Cumple | Cumple parcialmente | No cumple | No determinado |
|---|---|---|---|---|
| C1 · Estado, comandos y notificación | 2 | 6 | 6 | 0 |
| C2 · Coordinación con el Model | 12 | 2 | 0 | 0 |
| C3 · E/S asíncrona | 0 | 14 | 0 | 0 |
| C4 · Adaptación y desacople | 0 | 11 | 3 | 0 |
| **Total** | **14** | **33** | **9** | **0** |

No hubo veredictos "No determinado": los 14 archivos se leyeron completos y todos tienen al menos un consumidor identificado.

---

## Hallazgos transversales

1. **Ningún ViewModel apaga su indicador de carga en un `finally`** (C3, 14/14 parciales). Los seis que tienen `cargando` lo apagan en la última línea del método o repetido por rama: `categoriaViewModel.dart:114`, `clasesViewModel.dart:97`, `facultadesViewModel.dart:38`, `imagenViewModel.dart:40`, `inscripcionViewModel.dart:25`, `instructores_view_model.dart:37`, y `gruposViewModel.dart:72,80,85,91,105,113,119,125`. Los ocho restantes no tienen indicador alguno. Es el arreglo de menor costo y mayor cobertura del informe.

2. **`gruposViewModel.dart:31` es un defecto real, no de estilo:** `_cargando == true;` compara en lugar de asignar, así que `listarGruposDe` nunca marca carga. `flutter analyze` debería señalarlo como expresión sin efecto.

3. **13 de 14 importan `package:flutter/material.dart`**; sólo `horariosViewModel.dart:3` usa `flutter/foundation.dart`. En 9 de esos 13 el import no se usa para nada, así que el arreglo es un reemplazo de una línea. Los cuatro restantes —`categoriaViewModel`, `cursosViewModel`, `estadisticasViewModel`, `atencionViewModel`— sí dependen de Material: `showDialog` (15 ocurrencias), `BuildContext` como parámetro (9 firmas) y `DropdownMenuEntry` como campo público (3 clases).

4. **Cinco ViewModels no ejercen `ChangeNotifier`** (0 `notifyListeners()`): `Alumnosviewmodel`, `Atencionviewmodel`, `Deporteviewmodel` y `Horariosviewmodel` — y en la práctica tampoco se consumen por Provider pese a estar registrados en `main.dart:41-46`. El estado que deberían guardar vive en la View, dentro de `FutureBuilder`, con el efecto colateral de repetir la petición en cada reconstrucción (`widgetListaAlumnos.dart:52`, `widgetListaHorarios.dart:22`, `claseView.dart:118`, `estadisticasGeneralesView.dart:138`, `GruposInscripcion.dart:142`).

5. **Dos estilos de manejo de error conviven**, tal como documenta `CLAUDE.md`: el antiguo recibe `context` y abre el diálogo dentro del ViewModel (`categoriaViewModel.dart:33`, `cursosViewModel.dart:39,108`, `estadisticasViewModel.dart:71,87`, `atencionViewModel.dart:40`), el nuevo devuelve `RespuestaModelo` y deja la decisión a la View (`categoriaViewModel.dart:118,230,243`). Los métodos del estilo antiguo son exactamente los que hacen fallar C4 y, de paso, los que no se pueden ejercitar desde un `test()`.

6. **`RespuestaModelo` se filtra hasta la View en 8 ViewModels.** Es un tipo de `lib/data/models/`, y su presencia en la firma pública obliga a la View a interpretar códigos HTTP y a castear `datos` (`widgetListaAlumnos.dart:72-75`, `claseView.dart:101-117`, `estadisticasGeneralesView.dart:143-145`). Es la causa de fondo de los parciales en C4: no hay una capa de adaptación, hay un reenvío.
