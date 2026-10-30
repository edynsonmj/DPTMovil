# Auditoría MVVM · View/Widgets · Pasada C1–C4 · Piloto de formularios (v3, calibración cerrada)

- **Estado auditado:** árbol de trabajo en disco sobre `ee32c5d` (rama `main`), con 23 entradas sin commit (misma lista de la pasada C5).
- **Base de esta versión:** sin reanálisis. Filas verificadas en la corrida v1 (142 fragmentos comprobados con `grep -F`, 0 ausentes) y reprocesadas con las decisiones D5–D8 y los puntos de calibración 2–4.
- **Ubicación del reporte:** fuera del repositorio, para no alterar el `git status` auditado.
- **Convenciones:** rutas relativas a `lib/presentation/view/views/`, salvo V-86. Los IDs se conservan desde v1 para mantener la trazabilidad.
- **Columna "Cruce":** `V-xx` remite a la pasada C5; `→ V-xx` remite a otra fila de esta tabla.
- **Criterio DEP-INV:** dependencia inversa entre capas (dominio → View).

## 1. Decisiones de calibración aplicadas

| Decisión | Regla | Efecto en las filas |
|---|---|---|
| D5 | Solo son convenciones del proyecto las que están en archivos versionados; al citar una se indica el archivo y que está commiteado. | `CLAUDE.md` descartado (figura como `?? CLAUDE.md`, sin seguimiento). VM-f retirado. C2 sin excepción. Este reporte no cita convenciones del proyecto. |
| D6 | Toda variable que se lee al construir o mutar la entidad enviada es estado lógico, aunque además se pinte. | V-82 a V-85 (C3 sobre `_imagen`). V-59 y V-70 confirmados. |
| D7 (redacción final) | `initState` es C1 cuando contiene lógica propia de la View: transformaciones, cálculos sobre el dominio, o creación de un ViewModel, servicio o repositorio. No lo es delegar una carga a un ViewModel obtenido por Provider ni copiar la entidad a los controllers. | V-39 se mantiene. V-63 sigue fuera. V-50 vuelve por la creación de `Deporteviewmodel()` y se registra como cruce de V-61 (ver sección 2). |
| D8 | C4 marca una vez por archivo que el ViewModel no recibe la decisión. C4b y C4c sin cambios. | V-49, V-62, V-72 y V-81, una fila por formulario. |
| Punto 2 | La validación de presencia de un solo campo (`validator` de campo vacío, chequeo de nulo de una selección) es contrato de formulario, no regla de negocio. | Sin fila. Queda en observaciones menores (sección 6). |
| Punto 3 | Un límite de widget con significado de negocio es C2. | V-75 confirmado ("una clase no puede ser futura"). |
| Punto 4 | C4c sigue activo aunque el piloto tenga 0 casos. | Sin filas. Se aplicará a las pantallas con `FutureBuilder`. |

## 2. Decisión sobre V-50: cruce de V-61, no fila propia

**Hecho:** `FormularioCurso.dart` L47, dentro de `initState` (L45-64), ejecuta `Deporteviewmodel vmDeporte = Deporteviewmodel();`. Con la redacción final de D7 esto es C1.

**Decisión:** V-50 se registra como cruce en la fila V-61 y no suma como fila.

**Justificación:**

1. **Mismo hecho, mismo fragmento.** V-61 (C4b) cita exactamente la misma línea (L47) dentro del mismo bloque (`initState`). La regla de cruce del piloto dice que, si un hallazgo recae sobre la misma línea o bloque que otro ya registrado, se anota el ID en lugar de duplicar la fila.
2. **Mismo principio que D8:** un hecho, un conteo. Contarlo dos veces (Media en C1 + Alta en C4b) inflaría el peso de una sola línea sin aportar evidencia nueva.
3. **No se pierde cobertura.** El hecho ya cuenta con la severidad mayor (Alta, en V-61), y el criterio C1 queda visible en la columna "Cruce" de esa fila.
4. **Coherencia con V-39, que sí es fila propia.** V-39 cita la llamada a la conversión en L64 dentro de `initState`, mientras que V-43 cita el cuerpo de la conversión en `_convertirImagen` (L70-74). Son fragmentos y bloques distintos, así que la regla de cruce no se activa.

**Si prefieres fila propia:** total 47, Media 10, FormularioCurso 15, C1 10. El resto de ejes no cambia.

## 3. Filas fuera de la tabla

| ID | Criterio · ubicación | Motivo |
|---|---|---|
| V-50 | C1 · FormularioCurso.dart:45-64 (`initState`) | D7 lo reconoce como hallazgo por crear `Deporteviewmodel()` (L47). Registrado como cruce de V-61, ver sección 2. |
| V-63 | C1 · GrupoFormulario.dart:42-58 (`initState`) | D7: copia argumentos y delega la carga de instructores en un ViewModel obtenido por Provider. Sin lógica propia. Las trazas `print` están en E-18. |

## 4. Hallazgos

<!-- HALLAZGOS:INICIO -->

### 4.1 categorias/CategoriaFormulario.dart

| ID | Archivo:línea | Criterio | Severidad | Evidencia | Descripción | Cruce |
|---|---|---|---|---|---|---|
| V-39 | categorias/CategoriaFormulario.dart:50-68 | C1 | Media | `void initState() {` · `_convertirImagen();` | El método de ciclo de vida contiene una transformación de datos: lanza la conversión de los bytes de la imagen a archivo (L64); la copia a controllers (L58-61) no forma parte del hallazgo. | V-08, → V-43 |
| V-40 | categorias/CategoriaFormulario.dart:92-140 | C1 | Media | `Future<void> _submitForm() async {` | Método de 49 líneas que no construye UI: valida, construye la entidad, gestiona la bandera de carga y elige la operación. | V-21 |
| V-41 | categorias/CategoriaFormulario.dart:142-172 | C1 | Media | `Future<void> guardarCategoria(context, CategoriaEntidad entidad) async {` | Método de 31 líneas que no construye UI: llama al ViewModel, interpreta la respuesta, muestra diálogos, limpia y navega. | V-10 |
| V-42 | categorias/CategoriaFormulario.dart:175-209 | C1 | Media | `Future<void> actualizarCategoria(context, CategoriaEntidad entidad) async {` | Método de 35 líneas que no construye UI, con el mismo patrón que V-41 aplicado a la actualización. | V-10 |
| V-43 | categorias/CategoriaFormulario.dart:70-74 | C2 | Alta | `File? imagen = await ConvertFile.uInt8ListToFile(` · `_categoria!.imagen!.datos,` | Convierte los bytes de la imagen de la entidad en un archivo temporal que después se reenvía como carga: transformación de datos del dominio en la View. | V-08 |
| V-44 | categorias/CategoriaFormulario.dart:93 | C2 | Alta | `if (_imagen == null && _categoria?.idImagen == null) {` | Aplica la regla "la categoría necesita una imagen, nueva o existente" combinando la entrada con el estado de la entidad, y cancela la operación desde la View. | — |
| V-45 | categorias/CategoriaFormulario.dart:107-115 | C2 | Alta | `CategoriaEntidad entidad = CategoriaEntidad(` · `idImagen: _categoria?.idImagen,` | C2 confirmado: pasa los controllers a la entidad y aplica la regla de reemplazo de imagen (conserva `idImagen`, adjunta `imagenFile` solo si hay archivo nuevo). | V-21 |
| V-46 | categorias/CategoriaFormulario.dart:126, 237 | C2 | Alta | `if (_esEdicion) {` · `enabled: _esEdicion ? false : true,` | La View elige entre insertar y actualizar, y bloquea la edición del título, que es la clave del `PUT ?titulo=`. | — |
| V-47 | categorias/CategoriaFormulario.dart:144, 177 | C2 | Alta | `if (respuesta.codigoHttp == 201) {` · `if (respuesta.codigoHttp == 200) {` | Decide éxito o fracaso por códigos HTTP concretos, y con ello si limpia el formulario y cierra la pantalla. | V-10 |
| V-48 | categorias/CategoriaFormulario.dart:120-136 | C3 | Alta | `_guardando = true;` · `_guardando = false;` | Guarda con `setState` la bandera de carga de una operación asíncrona; es estado lógico aunque su efecto sea deshabilitar el botón. | — |
| V-82 | categorias/CategoriaFormulario.dart:75-77 | C3 | Alta | `_imagen = imagen;` | (D6) Guarda como estado local el archivo derivado de la entidad, que después se adjunta como `entidad.imagenFile` (L114). | V-08, → V-43 |
| V-83 | categorias/CategoriaFormulario.dart:338-340 | C3 | Alta | `_imagen = File(pickedImage.path);` | (D6) Guarda como estado local la imagen elegida, que se valida (L93) y se adjunta a la entidad (L114). | — |
| V-49 | categorias/CategoriaFormulario.dart:294-298 | C4 | Alta | `onPressed:` · `_submitForm();` | (D8) Ninguna decisión del formulario llega al ViewModel: el único punto de envío resuelve en la View la validación, la construcción y la elección de operación (V-40, V-44 a V-47). | V-21 |

### 4.2 curso/FormularioCurso.dart

| ID | Archivo:línea | Criterio | Severidad | Evidencia | Descripción | Cruce |
|---|---|---|---|---|---|---|
| V-51 | curso/FormularioCurso.dart:301-346 | C1 | Media | `Future<void> _submitForm(context) async {` | Método de 46 líneas que no construye UI: dos validaciones, construcción de la entidad, limpieza y elección de operación. | V-25 |
| V-52 | curso/FormularioCurso.dart:348-378 | C1 | Media | `_manejarAgregar(CursoEntidad entidad) async {` | Método de 31 líneas sin tipo de retorno declarado: llama al ViewModel, interpreta la respuesta, muestra diálogos y navega. | V-14 |
| V-53 | curso/FormularioCurso.dart:173 | C2 | Alta | `if (promesa.data!.codigoHttp != 200) {` | Dentro del `builder` decide qué pintar según el código HTTP de la respuesta. | V-14 |
| V-54 | curso/FormularioCurso.dart:180-189 | C2 | Alta | `if (promesa.data!.datos is! List) {` · `List<String> lista = listaDynamic.cast<String>();` | Deserializa a mano datos dinámicos con `is!` y `.cast`; hay `try/catch` (L187-202) que convierte el fallo en un texto. | V-14 |
| V-55 | curso/FormularioCurso.dart:315 | C2 | Alta | `if (_imagen == null && _estado.curso?.imagen == null) {` | Aplica en la View la misma regla de imagen obligatoria que V-44. | — |
| V-56 | curso/FormularioCurso.dart:329-338 | C2 | Alta | `CursoEntidad entidad = CursoEntidad(` · `nombreDeporte: _deporte!,` | C2 confirmado: combina controllers, la selección del desplegable y la imagen original para formar la entidad. | V-25 |
| V-57 | curso/FormularioCurso.dart:339-344, 380 | C2 | Alta | `await _manejarEditar(entidad);` · `_manejarEditar(CursoEntidad entidad) {}` | Elige localmente entre agregar y editar (y bloquea `nombre` en edición, L109); la rama de edición es un método vacío y el formulario se limpia (L339) antes de conocer el resultado. | — |
| V-58 | curso/FormularioCurso.dart:351 | C2 | Alta | `if (respuesta.codigoHttp == 201) {` | Decide éxito, diálogo y navegación según el código HTTP. | V-14 |
| V-59 | curso/FormularioCurso.dart:216-218 | C3 | Alta | `_deporte = seleccion;` | (Confirmado por D6) Guarda el deporte elegido, que se valida (L302) y entra en la entidad (L331). | — |
| V-84 | curso/FormularioCurso.dart:260-262 | C3 | Alta | `_imagen = File(pickedImage.path);` | (D6) Guarda la imagen elegida, que se valida (L315) y se adjunta a la entidad (L337). | — |
| V-85 | curso/FormularioCurso.dart:387-389 | C3 | Alta | `_imagen = null;` | (D6) Borra la imagen destinada a la entidad dentro de `_limpiarInputs`, invocado antes de enviar la petición (L339). | → V-57 |
| V-60 | curso/FormularioCurso.dart:33 | C4b | Alta | `final CursosViewModel _vmCurso = CursosViewModel();` | Crea su propio ViewModel como campo, en paralelo al provider registrado en `main.dart:35`. | — |
| V-61 | curso/FormularioCurso.dart:47-48 | C4b | Alta | `Deporteviewmodel vmDeporte = Deporteviewmodel();` · `_futureDeportes = vmDeporte.obtenerDeportes();` | Crea un ViewModel local en `initState`, en paralelo a `main.dart:43`, y guarda su future como estado de la View; por D7 el mismo hecho es también C1 (V-50, sección 2), y C4c no aplica porque el future no se crea en `build`. | V-14, V-50 (C1 por D7) |
| V-62 | curso/FormularioCurso.dart:279-280 | C4 | Alta | `onPressed: () {` · `_submitForm(context);` | (D8) Ninguna decisión del formulario llega al ViewModel: el envío valida, construye, elige la operación e interpreta la respuesta en la View (V-51 a V-58). | V-25 |

### 4.3 grupo/GrupoFormulario.dart

| ID | Archivo:línea | Criterio | Severidad | Evidencia | Descripción | Cruce |
|---|---|---|---|---|---|---|
| V-64 | grupo/GrupoFormulario.dart:219-289 | C1 | Media | `Future<void> _submitForm(context) async {` | Método de 71 líneas que no construye UI, el más largo del lote: valida, construye, llama al ViewModel, decide por HTTP, muestra diálogos y navega. | V-16, V-29 |
| V-65 | grupo/GrupoFormulario.dart:160-163 | C2 | Alta | `_anio = DateTime.now().year;` · `_fechaCreacion = FormatDate.fechaACadena(DateTime.now(), '-');` | Calcula el año que identifica al grupo y su fecha de creación con el reloj del dispositivo, dentro de un método de UI (`_infoCurso`). | — |
| V-66 | grupo/GrupoFormulario.dart:229-236 | C2 | Alta | `if (_anio == null) {` | Valida que exista identificador pero no hace `return`: la ejecución sigue y `anio: _anio!` (L241) lanzaría si fuera nulo. | — |
| V-67 | grupo/GrupoFormulario.dart:238-247 | C2 | Alta | `Grupoentidad g = Grupoentidad(` · `iterable: 0,` | C2 confirmado: construye la entidad con un valor de negocio fijo (`iterable: 0`) y recalcula `fechaCreacion` convirtiéndola al `String` que exige la entidad. | V-29 |
| V-68 | grupo/GrupoFormulario.dart:244 | C2 | Alta | `cupos: int.parse(_cuposController.text),` | Parseo sin `try/catch`: `digitsOnly` (L98) y el validador de campo vacío acotan la entrada, pero puede lanzar `FormatException` por desbordamiento de `int`, y no hay regla de mínimo (acepta 0). | V-29 |
| V-69 | grupo/GrupoFormulario.dart:261 | C2 | Alta | `if (respuesta.codigoHttp == 201) {` | Decide éxito, diálogo y navegación según el código HTTP. | V-16 |
| V-70 | grupo/GrupoFormulario.dart:151-153 | C3 | Alta | `_idInstructor = seleccion;` | (Confirmado por D6) Guarda el instructor elegido, que se valida (L220) y entra en la entidad (L245). | — |
| V-71 | grupo/GrupoFormulario.dart:161-164 | C3 | Alta | `setState(() {` · `_anio = DateTime.now().year;` | `setState` ejecutado desde `_infoCurso()`, que se invoca durante `build`: vuelve a escribir estado del dominio en cada reconstrucción; también figura en defectos funcionales (sección 7). | → V-65 |
| V-72 | grupo/GrupoFormulario.dart:197-198 | C4 | Alta | `onPressed: () {` · `_submitForm(context);` | (D8) Ninguna decisión del formulario llega al ViewModel: la validación, la construcción de la entidad y la interpretación de la respuesta ocurren en la View (V-64 a V-69). | V-29 |

### 4.4 clase/claseFormulario.dart

| ID | Archivo:línea | Criterio | Severidad | Evidencia | Descripción | Cruce |
|---|---|---|---|---|---|---|
| V-73 | clase/claseFormulario.dart:63-80 | C1 | Media | `Future<void> _seleccionFecha({` | Método de 18 líneas que no construye UI: abre el selector de fecha y escribe el resultado en la entidad. | V-23 |
| V-74 | clase/claseFormulario.dart:133-168 | C1 | Media | `Future<void> _submitForm(context) async {` | Método de 36 líneas que no construye UI: completa la entidad, parsea, llama al ViewModel, decide por HTTP, muestra diálogos y navega. | V-12, V-23 |
| V-75 | clase/claseFormulario.dart:72-73 | C2 | Alta | `firstDate: DateTime(2020),` · `lastDate: DateTime.now(),` | (Confirmado por el punto 3) Fija en un parámetro de widget la regla de negocio del rango válido de fechas de una clase: desde 2020 y nunca futura. | — |
| V-76 | clase/claseFormulario.dart:136 | C2 | Alta | `claseEstado.horas = int.parse(_horasController.text);` | Parseo sin `try/catch`: `digitsOnly` (L112) y el validador de campo vacío acotan la entrada, pero puede lanzar por desbordamiento, y no hay regla de rango (acepta 0 horas). | V-23 |
| V-77 | clase/claseFormulario.dart:135-137 | C2 | Alta | `claseEstado.fecha = fecha;` · `claseEstado.minutos = 0;` | C2 confirmado (mutación, porque la entidad llega por argumento): la completa con un valor de negocio fijo (`minutos = 0`) sin comprobar que la fecha no sea nula. | V-23 |
| V-78 | clase/claseFormulario.dart:140 | C2 | Alta | `if (respuesta.codigoHttp == 201) {` | Decide éxito, diálogo y navegación según el código HTTP. | V-12 |
| V-79 | clase/claseFormulario.dart:76-79 | C3 | Alta | `fecha = selectorFecha;` · `claseEstado.fecha = fecha;` | `setState` muta la entidad editable `late Claseentidad claseEstado`, que es la misma instancia recibida por argumento (L35); lo dispara el `onPressed` de L88-95, y si se cancela el selector escribe `null`. | V-23 |
| V-80 | clase/claseFormulario.dart:26 | C4b | Alta | `final Clasesviewmodel vmClase = Clasesviewmodel();` | Crea su propio ViewModel como campo, en paralelo al provider registrado en `main.dart:41`. | V-12 |
| V-81 | clase/claseFormulario.dart:173-174 | C4 | Alta | `onPressed: () {` · `_submitForm(context);` | (D8) Ninguna decisión del formulario llega al ViewModel: completar la entidad, parsear e interpretar la respuesta ocurren en la View (V-73 a V-78). | V-23 |

### 4.5 Hallazgo de capa (reencuadre de E-24)

| ID | Archivo:línea | Criterio | Severidad | Evidencia | Descripción | Cruce |
|---|---|---|---|---|---|---|
| V-86 | lib/domain/entities/grupoEntidad.dart:2 | DEP-INV | Alta | `import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';` | Una entidad del dominio importa una pantalla de presentación e invierte la dirección de dependencia entre capas; no se comprobó si usa algún símbolo del import, y su remediación cae en la pasada del dominio. | ex E-24 |

<!-- HALLAZGOS:FIN -->

## 5. Inventario de setState (C3)

| # | Archivo:líneas | Variable | Clasificación | Fila |
|---|---|---|---|---|
| 1 | CategoriaFormulario:75-77 | `_imagen` | Lógico (D6) | V-82 |
| 2 | CategoriaFormulario:120-122 | `_guardando` | Lógico | V-48 |
| 3 | CategoriaFormulario:134-136 | `_guardando` | Lógico | V-48 |
| 4 | CategoriaFormulario:338-340 | `_imagen` | Lógico (D6) | V-83 |
| 5 | CategoriaFormulario:369-371 | `_imagen` | Inalcanzable (el `Positioned` nunca entra en el árbol) | E-16 |
| 6 | FormularioCurso:216-218 | `_deporte` | Lógico | V-59 |
| 7 | FormularioCurso:260-262 | `_imagen` | Lógico (D6) | V-84 |
| 8 | FormularioCurso:387-389 | `_imagen` | Lógico (D6) | V-85 |
| 9 | GrupoFormulario:151-153 | `_idInstructor` | Lógico | V-70 |
| 10 | GrupoFormulario:161-164 | `_anio`, `_fechaCreacion` | Lógico | V-71 |
| 11 | claseFormulario:76-79 | `fecha`, `claseEstado.fecha` | Lógico | V-79 |

Total: 11 llamadas. Son 10 lógicas y 1 inalcanzable; ninguna ambigua y ninguna visual.

## 6. Observaciones menores (no son hallazgos)

**Enlace de presentación en `initState` (D7):**
- CategoriaFormulario:58-61 copia título y descripción a los controllers.
- FormularioCurso:51-63 copia los campos del curso.
- GrupoFormulario:44-46 copia argumentos, y en L51-57 delega la carga de instructores a un ViewModel obtenido por Provider.

**Validación de presencia de un solo campo** (punto 2: contrato de formulario, no C2):
- `validator` de campo vacío en CategoriaFormulario:239-244 y 254-259, FormularioCurso:111-116 y 126-131, GrupoFormulario:100-105 y claseFormulario:114-119.
- Chequeo de nulo de una selección: `if (_deporte == null)` en FormularioCurso:302 e `if (_idInstructor == null)` en GrupoFormulario:220.

**Formato visual (fuera de C2):**
- CategoriaFormulario:85, título `"Editar " + (_categoria!.titulo)`.
- FormularioCurso:72, `'Editar curso: ${widget.argumentos.curso!.nombreCurso}'`.
- GrupoFormulario:138, `'${instructor.nombre} - ${instructor.id}'`.
- GrupoFormulario:178, `Text('$_anio.N')`.
- claseFormulario:99, `FormatDate.fechaACadena(fecha!, '/')` como etiqueta de botón.
- Mensaje `'Error desconocido. Código: ${respuesta.codigoHttp}'` en CategoriaFormulario:166, FormularioCurso:372, GrupoFormulario:282 y claseFormulario:161.
- FormularioCurso:224-230, `cargarEntradas` convierte `String` en `DropdownMenuEntry`.

**Métodos Widget de más de 60 líneas:** ninguno. El mayor es `_inputComboDeporte` (FormularioCurso), con 54.

## 7. Defectos funcionales detectados de paso (fuera de C1–C5)

1. **GrupoFormulario: setState durante build (V-71).** Se registra por riesgo de reconstrucción en bucle o de excepción del framework.
   - Precisión técnica, razonada sobre el comportamiento conocido de Flutter y no ejecutada: `_infoCurso()` corre dentro del `build` del mismo `State`, y el elemento ya está pendiente de reconstrucción, así que `markNeedsBuild` no programa otra. Con el código actual lo esperable es un `setState` redundante que reescribe `_anio` y `_fechaCreacion` en cada `build`.
   - La excepción `setState() or markNeedsBuild() called during build` aparecería si la llamada acabara dentro de un builder descendiente (`Consumer`, `Builder`). Se registra como defecto latente.
2. **GrupoFormulario: falta un `return` (V-66).** Tras `if (_anio == null)` la ejecución continúa, y el `_anio!` posterior lanzaría.
3. **GrupoFormulario: el modo edición se ignora.** `_esEdicion` existe, pero `_submitForm` siempre llama a `insertarGrupo`.
4. **FormularioCurso: limpieza antes de enviar (V-57, V-85).** `_limpiarInputs()` borra `_categoriaController` y `_imagen` antes de la petición. Si esta falla, el reintento choca con la regla de imagen y enviaría `tituloCategoria` vacío.
5. **FormularioCurso: la edición no hace nada.** En modo edición el formulario se limpia y no ocurre nada más, porque `_manejarEditar` está vacío.
6. **claseFormulario: fecha nula sin control.** Si se cancela el selector de fecha, esta queda en `null` y el envío no lo comprueba.

## 8. Observaciones estructurales

| ID | Observación |
|---|---|
| E-15 | claseFormulario.dart: el import de `deporteViewModel.dart` (L11) no se usa, y el de `respuestaModelo.dart` (L4) nunca se nombra, porque el tipo solo se infiere en L138. |
| E-16 | CategoriaFormulario.dart:364-375: el `Positioned posicion` se construye y nunca se añade al `Stack` (L377), así que su `setState` es código muerto. |
| E-17 | FormularioCurso.dart:40: `_deporteController` se asigna (L55) y se limpia (L384), pero no está enlazado a ningún campo. |
| E-18 | GrupoFormulario.dart: `_grupo` (L32) y `_fechaCreacion` (L39) se asignan pero nunca se leen; hay 10 `print` de depuración (L47-49 y L249-255). |
| E-19 | Textos de diálogo copiados de otros formularios: FormularioCurso:369 `'Error al guardar clase'`; GrupoFormulario:267 `'Curso registrado'` y GrupoFormulario:279 `'Error al guardar clase'`. |
| E-20 | El bloque "si 201: `DialogExito` y `pop(true)`; si no: `DialogError`" se repite casi literal en CategoriaFormulario 144-171 y 177-208, FormularioCurso 351-377, GrupoFormulario 261-287 y claseFormulario 140-166. |
| E-21 | El esqueleto `contenedorSeguro`/`contenido`/`_acciones`/`_botonSubmit`/`_botonCancelar` se repite en los 4 formularios con el mismo `EdgeInsets.symmetric(horizontal: 50, vertical: 10)`. |
| E-22 | Nombres de clase inconsistentes: `CategoriaFormulario`, `FormularioCurso`, `Grupoformulario` y `Claseformulario`. Lo mismo en archivos: `claseFormulario.dart` frente a `GrupoFormulario.dart`. |
| E-23 | Métodos públicos sin `_` (`guardarCategoria`, `contenedorSeguro`, `cargarEntradas`, `clear`) y métodos sin tipo de retorno (`_manejarAgregar`, `_manejarEditar`, `_limpiarInputs`). |

## 9. Causas raíz y arrastres a otras pasadas

**Causas raíz:**

| ID | Patrón | Filas |
|---|---|---|
| CR-01 | El flujo de envío completo vive en la View: validar, construir la entidad, llamar al ViewModel, decidir por HTTP, mostrar el diálogo y hacer `pop`. | V-40, V-41, V-42, V-45, V-47, V-49, V-51, V-52, V-56, V-58, V-62, V-64, V-67, V-69, V-72, V-74, V-77, V-78, V-81 (19) |
| CR-02 | La View instancia el ViewModel en lugar de obtenerlo del Provider. | V-60, V-61 (+ cruce V-50), V-80 |
| CR-03 | El borrador del formulario vive como estado de la View. | V-59, V-70, V-82, V-83, V-84, V-85 |

**Arrastres:**

| # | Pasada | Hallazgo | Estado |
|---|---|---|---|
| VM-a | ViewModel | `CategoriaViewModel`, `CursosViewModel.agregarCurso`, `Gruposviewmodel.insertarGrupo`, `Clasesviewmodel.guardarClase` y `Deporteviewmodel.obtenerDeportes` devuelven `Future<RespuestaModelo>` a la View. Es el origen de V-47, V-53, V-58, V-69 y V-78. | Pendiente |
| VM-b | ViewModel | `Deporteviewmodel` no tiene estado: reenvía un `RespuestaModelo` con `datos` dinámico. Es el origen de V-54 y V-61. | Pendiente |
| VM-c | ViewModel | Los constructores crean su servicio sin posibilidad de inyección (`CursosViewModel() : servicioCurso = ServicioCurso();` y equivalentes), lo que facilita CR-02. | Pendiente |
| VM-d | ViewModel | `CursosViewModel` expone `List<DropdownMenuEntry> get getListaEntradas` (un tipo de widget de Flutter) y tiene métodos que reciben `context`. | Pendiente |
| VM-e | ViewModel | `CursosViewModel` no tiene operación de edición, lo que explica V-57. | Pendiente |
| VM-f | ViewModel | Se apoyaba en `CLAUDE.md` para justificar que la View decida por código HTTP. | Descartado (D5): archivo no versionado, no es documentación del proyecto. |
| DOM-a | Dominio | V-86: `grupoEntidad.dart` importa `presentation/view/views/grupo/grupo.dart`. | Pendiente |

## 10. Reglas cerradas para los 40 archivos restantes

| Tema | Regla |
|---|---|
| Fuente de convenciones | Solo archivos versionados, citando el archivo y confirmando que está commiteado (D5). |
| C1 | Métodos no-Widget de más de 15 líneas. `initState` cuenta por contenido (D7). Métodos Widget de más de 60 líneas van como observación. |
| C2, formato frente a transformación | Se decide por uso, no por función: si el valor solo se pinta es formato; si entra en la entidad, se envía o condiciona la operación, es C2. Caso de referencia: `FormatDate.fechaACadena`. |
| C2, validaciones | Presencia de un solo campo: observación (punto 2). Regla que combina entrada y estado del dominio, o que cancela la operación: C2. |
| C2, parámetros de widget | Un límite con significado de negocio es C2 (punto 3). |
| C2, HTTP y tipos | Decidir por `codigoHttp`, o castear y comprobar tipos dinámicos, es C2 sin excepción. |
| C3 | Una variable que se lee al construir o mutar la entidad es estado lógico (D6). |
| C4 | Una fila por archivo (D8). C4b: la View crea un ViewModel, servicio, repositorio o conexión. C4c: activo (punto 4). |
| Duplicados | Si el mismo hecho cae en la misma línea o bloque que otro hallazgo, se registra como cruce, no como fila (sección 2). |

Puntos abiertos: ninguno. Queda por validar la decisión de la sección 2 (V-50 como cruce).

## 11. Conteo (calculado a partir de las filas de la sección 4)

| Criterio | CategoriaFormulario | FormularioCurso | GrupoFormulario | claseFormulario | grupoEntidad | Total |
|---|---|---|---|---|---|---|
| C1 | 4 | 2 | 1 | 2 | 0 | 9 |
| C2 | 5 | 6 | 5 | 4 | 0 | 20 |
| C3 | 3 | 3 | 2 | 1 | 0 | 9 |
| C4 | 1 | 1 | 1 | 1 | 0 | 4 |
| C4b | 0 | 2 | 0 | 1 | 0 | 3 |
| C4c | 0 | 0 | 0 | 0 | 0 | 0 |
| DEP-INV | 0 | 0 | 0 | 0 | 1 | 1 |
| **Total** | **13** | **14** | **9** | **9** | **1** | **46** |

| Severidad | Filas |
|---|---|
| Alta | 37 (C2 20 + C3 9 + C4 4 + C4b 3 + DEP-INV 1) |
| Media | 9 (C1) |
| Baja | 0 |
| **Total** | **46** |

## 12. Comprobaciones finales

Verificación ejecutada con un script sobre este mismo archivo, leyendo las filas entre los marcadores `HALLAZGOS:INICIO` y `HALLAZGOS:FIN`:

| Comprobación | Resultado |
|---|---|
| Filas de hallazgo | 46 |
| IDs duplicados | 0 |
| Filas con un número de celdas distinto de 7 | 0 |
| Celdas vacías | 0 |
| Descripciones que no terminan en punto (señal de truncado) | 0 |
| Líneas de contenido duplicadas en todo el archivo | 0 |
| IDs presentes | V-39 a V-49, V-51 a V-62, V-64 a V-86 (V-50 y V-63 fuera, según la sección 3) |

**Conteo recalculado por script a partir de las filas:**

| Eje | Suma | Total |
|---|---|---|
| Por archivo | 13 + 14 + 9 + 9 + 1 | 46 |
| Por criterio | C1 9 + C2 20 + C3 9 + C4 4 + C4b 3 + C4c 0 + DEP-INV 1 | 46 |
| Por severidad | Alta 37 + Media 9 | 46 |

Los tres ejes cuadran entre sí, y la matriz archivo × criterio que genera el script coincide celda a celda con la tabla de la sección 11.

**Otras declaraciones:**
- **Cobertura:** los 4 formularios están evaluados con los 4 criterios (C4 subdividido en C4, C4b y C4c). Cada 0 corresponde a una celda revisada, no a una celda vacía.
- **Fragmentos:** los citados son los que se verificaron con `grep -F` en la corrida v1. En esta versión no se reanalizó ningún archivo fuente.
- **Sin modificaciones:** no se tocó ningún archivo del proyecto. El reporte está fuera del repositorio, y `git status` sigue mostrando las mismas 23 entradas.
