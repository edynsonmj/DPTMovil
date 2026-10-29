# Plan de implementación: abrir y cerrar inscripciones de un grupo

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias` · Hallazgos relacionados: IN-01 a IN-07 en [registro-bugs.md](registro-bugs.md)

## 1. Punto de partida

**App:** las pantallas del coordinador para abrir, cerrar y programar inscripciones son maquetas.
- Los botones no llaman a nada (IN-01, IN-02).
- La lista de grupos por grupo es ficticia (IN-03).
- `GrupoModelo` no lee ninguna fecha de inscripción.

**Backend:** ya publica dos endpoints nuevos. Se probaron el 2026-10-29 contra el backend levantado, sobre el grupo de prueba `prueba_actualizar_20260817183250444203 / curso prueba / 2026 / 2`, que quedó cerrado al terminar.

### 1.1 Contrato observado

```
PUT /api/v2/abrirInscripcionesGrupo?categoria=&curso=&anio=&iterable=
Content-Type: application/json
{ "fechaInscripcionApertura": "yyyy-MM-dd", "fechaIncripcionCierre": "yyyy-MM-dd" }   (ambos opcionales; el cuerpo también)

PUT /api/v2/cerrarInscripcionesGrupo?categoria=&curso=&anio=&iterable=   (sin cuerpo)
```

Ambos devuelven el **grupo completo** (`GrupoDto`), que ahora trae `fechaInscripcionApertura` y `fechaIncripcionCierre`. **Ojo:** el backend escribe `Incripcion`, sin la segunda "s", en el campo de cierre.

| Caso probado | Respuesta |
|---|---|
| Abrir sin cuerpo, o con `{}` | `200`; apertura = hoy, cierre = `null` (sin fecha límite) |
| Abrir con apertura hoy y cierre 2026-11-30 | `200`; el grupo **aparece** en `GET /gruposInscripcion` |
| Abrir con apertura **futura** (2026-12-01 a 2026-12-20) | `200`; el grupo **no aparece** en `/gruposInscripcion`. Esto es "programar" |
| Cierre anterior a la apertura, o cierre en el pasado | `400 {"cierreValido": "la fecha de cierre no puede ser anterior a la fecha de apertura ni a la fecha actual"}` |
| Fecha mal formada (`29/10/2026`) | `400 {"mensaje": "...JSON mal formado...", "detalle": "Text '29/10/2026' could not be parsed..."}` |
| Grupo inexistente (abrir o cerrar) | `404 {"codigoError": "GC-0003", "mensaje": "...", ...}` |
| Cerrar | `200`; **apertura y cierre pasan a ser ayer** (`2026-10-28`); el grupo deja de aparecer en `/gruposInscripcion` |
| Sin parámetros de query | `400` con el **stack trace completo** de Spring en el cuerpo |

**Regla deducida de las pruebas:** un grupo es inscribible si `apertura <= hoy` y (`cierre` es nulo o `cierre >= hoy`). Que el día de cierre cuente como abierto se infiere de que "cerrar" pone el cierre en ayer. Falta confirmarlo con una prueba remota (fase 5).

**Lista de grupos para el coordinador:** `GET /gruposNoEliminados` (14 grupos en la BD de pruebas) ya trae las dos fechas en cada grupo. La app hoy no tiene un método para ese endpoint.

### 1.2 Observaciones para el backend (no bloquean)

| # | Observación | Propuesta |
|---|---|---|
| BK-01 | Errata en el contrato: `fechaIncripcionCierre` | Corregirla a `fechaInscripcionCierre` **ahora**, antes de que la app dependa de ella. Si no se corrige, la app usa la clave tal cual (decisión D2) |
| BK-02 | "Cerrar" sobrescribe la fecha de apertura con la de ayer, así que se pierde cuándo se abrió | Que cerrar solo toque el cierre, si interesa el histórico |
| BK-03 | Un `400` por parámetro faltante devuelve el stack trace completo | Desactivar `server.error.include-stacktrace` (fuga de información interna) |
| BK-04 | No hay endpoint para abrir o cerrar **todos los grupos de una categoría** (la pantalla "Inscripciones generales") | Ver decisión D1 |
| — | Aparte de esto: tu endpoint de asistencias es `GET/POST /asistenciasClase?idClase=`, distinto de lo que la app usa hoy (`/atencionesporclase`, `/atenciones?idclase=`) y del contrato propuesto | Se trata en el módulo de asistencias como diferencia de contrato (AS-C, ver B-09 del informe) |

## 2. Decisiones

> **Tomadas el 2026-10-29 (las recomendadas):**
> - **D1 = c + b:** "Inscripciones generales" se deshabilita en la app hasta que el backend tenga un endpoint por categoría, y se le pide ese endpoint al backend.
> - **D2 = a, con b de respaldo:** se pide al backend corregir `fechaIncripcionCierre`. Mientras no lo haga, la app usa la clave tal cual, solo en la capa de modelos, y los contratos de `test/contratos/inscripciones/` la conservan porque reflejan lo que el backend responde hoy.
> - **D3:** sigue fuera de alcance.

| # | Decisión | Opciones | Recomendación |
|---|---|---|---|
| **D1** | Pantalla "Inscripciones generales" (abrir o cerrar **por categoría**) | a) La app llama al endpoint por grupo, uno por cada grupo de la categoría (N peticiones y fallos parciales que hay que mostrar). b) Pedir al backend un endpoint por categoría. c) Ocultar o deshabilitar esa pantalla hasta que exista | **c ahora y b después**: no implementar el bucle en la app. Lo que hoy existe es por grupo |
| **D2** | Errata `fechaIncripcionCierre` | a) El backend la corrige ya. b) La app usa la clave con la errata, aislada en `GrupoModelo` y `PeriodoInscripcionModelo` | **a**. Si no es posible, b: el nombre en Dart será correcto y la errata solo aparecerá en la clave JSON |
| **D3** | ¿El alumno ve las fechas de inscripción en sus tarjetas? | Sí / no | Fuera de este plan. Se puede agregar después sin cambiar la capa de datos |

## 3. Diseño

Sigue la arquitectura del proyecto (CLAUDE.md): Vista → VM por ruta → `Servicio*` → `*Repositorio` → `Conexion*`. Los métodos nuevos devuelven `Resultado` o `RespuestaModelo` sin recibir `context`.

### Datos
- **Modelo y entidad de grupo:**
  - `GrupoModelo.fromJson` lee `fechaInscripcionApertura` y `fechaIncripcionCierre`.
  - Campos nuevos `String?` en `GrupoModelo` y `Grupoentidad`, con el nombre correcto en Dart: `fechaInscripcionApertura` y `fechaInscripcionCierre`.
  - `toJson` (POST `/grupo`) **no** cambia.
- **Modelo nuevo `PeriodoInscripcionModelo`** `{ String? apertura; String? cierre }`:
  - `toJson` **omite las claves nulas**. Se probó `{}` y sin cuerpo, pero no `null` explícito.
- **`Conexiongrupos`** (interfaz y `Conexiongruposremoto`), tres métodos nuevos:
  - `obtenerGruposNoEliminados()`;
  - `abrirInscripciones(categoria, curso, anio, iterable, PeriodoInscripcionModelo)`;
  - `cerrarInscripciones(categoria, curso, anio, iterable)`.

  Los parámetros van con **`queryParameters` de Dio**, no interpolados en la URL, para no repetir AS-04: los títulos de categoría tienen espacios y tildes. Éxito = `200`, con un `GrupoModelo` en `datos`.
- **`ConexiongruposFalsa`:** implementa los tres métodos con el patrón programable (`respuestaX`, `ultimoX`, `llamadasX`, `copiaRespuesta`). Es obligatorio para que compilen las pruebas existentes.
- **`Gruporepositorio` y `Serviciogrupo`:** métodos equivalentes que convierten a `Grupoentidad`. No hay servicio nuevo, así que `dependencias.dart` y la prueba de humo de la raíz no cambian.

### Dominio
- **Estado de inscripción en `Grupoentidad`:** `EstadoInscripcion estadoInscripcion(DateTime hoy)`, con los valores:
  - `abierta`;
  - `programada` (apertura futura);
  - `cerrada`;
  - `sinPeriodo` (ambas fechas nulas).

  Se calcula con la regla de 1.1. Recibe `hoy` para poder probarla sin depender del reloj.

### Presentación
- **ViewModel nuevo `PeriodoInscripcionViewModel`**, con `NotificacionSegura` y creado en la ruta `InscripcionesParticulares`:
  - `cargar()`: lista de `gruposNoEliminados` en un `EstadoSeccion<List<Grupoentidad>>`.
  - `filtrar(categoria?)`: el filtro por categoría se hace en la app, porque no hay endpoint por categoría.
  - `abrir(grupo, {apertura, cierre})` y `cerrar(grupo)` → `Resultado<Grupoentidad>`. Al terminar bien, **reemplazan solo ese grupo** con el `GrupoDto` devuelto, sin recargar la lista.
  - `procesando(grupo)`: el botón de ese grupo se deshabilita mientras su operación está en camino, como en `Inscripcionviewmodel`, para no repetir AS-02.
- **Vista `InscripcionesParticularesView`:**
  - Lista real en lugar de los 20 grupos ficticios.
  - El estado real, con las fechas, en la tarjeta.
  - Diálogo con:
    - **Abrir ahora:** apertura hoy y cierre opcional.
    - **Programar:** rango de fechas con `AlertFechas`; usa el mismo endpoint de abrir con apertura futura.
    - **Cerrar.**
  - El resultado se muestra con `DialogExito`/`DialogError`. Los `400` del backend son JSON, y `DialogError` ya los desglosa.
- **Carga de categorías:** el filtro sigue usando `CategoriaViewModel` para la lista de categorías, pero con `listarYNotificarCategorias()`, no con el `cargarCategorias(context)` antiguo (CAT-05).
- **Ruta:** `AppRutas.InscripcionesParticulares` pasa de `_conCategorias(...)` a un `MultiProvider` con `CategoriaViewModel` y `PeriodoInscripcionViewModel`, este último con `..cargar()`.
- **Vista `InscripcionesGeneralesView`:** según D1.
- **Roles:** el acceso sigue limitado por el menú lateral (solo coordinador). La comprobación en pantalla y ruta queda para el módulo de roles, **al final**, por decisión del 2026-10-29.

## 4. Fases

Cada fase termina con `flutter test test/unitarias test/raiz_composicion_test.dart test/integracion` en verde y `flutter analyze` sin warnings nuevos (línea base: 31).

> **Estado:**
> - **Fase 0 cerrada (2026-10-29).** `test/contratos/inscripciones/` tiene 6 JSON y un `LEEME.md`. Los 5 de respuestas individuales coinciden exactamente con lo capturado del backend; `gruposNoEliminados_200.json` es un recorte de 3 de los 14 grupos reales: abierto, sin periodo y cerrado.
> - El grupo de prueba `prueba_.../2` quedó cerrado al terminar la captura.
> - Suite sin backend: 113 pruebas en verde.
> - **Fase 1 cerrada (2026-10-29).** `test/diagnostico/inscripciones/vista_diagnostico_test.dart` tiene 5 pruebas en rojo y 1 de control en verde. Montaje compartido: `test/integracion/montajeInscripciones.dart` (rutas reales, `Serviciogrupo` real sobre el adaptador y contrato observado). IN-01, IN-02 e IN-03 pasan a **confirmado por prueba**.
> - **Fase 2 cerrada (2026-10-29).** Capa de datos:
>   - `GrupoModelo` y `Grupoentidad` tienen `fechaInscripcionApertura` y `fechaInscripcionCierre`; la clave con errata está aislada en `GrupoModelo.claveCierreInscripcion`.
>   - `PeriodoInscripcionModelo` es nuevo y no envía las fechas nulas.
>   - `Conexiongrupos` tiene los métodos `obtenerGruposNoEliminados`, `abrirInscripciones` y `cerrarInscripciones`. Usan `queryParameters` y también capturan `Error` (`TypeError`) con `fromObjectError`.
>   - `ConexiongruposFalsa`, `Gruporepositorio` (las fechas viajan como `DateTime` → `yyyy-MM-dd`) y `Serviciogrupo` están al día.
>   - Pruebas: +18 (4 de modelo, 9 de conexión, 5 de repositorio). Suite sin backend: **131 en verde**. Diagnóstico sin cambios (24 rojas), porque la vista no se ha tocado. `flutter analyze`: 31 warnings, sin cambios.
> - **Fase 3 cerrada (2026-10-29).**
>   - `EstadoInscripcion` (abierta, programada, cerrada o sin periodo) y `Grupoentidad.estadoInscripcion(hoy)` con la regla observada; la hora del día no influye.
>   - `PeriodoInscripcionViewModel` (con `NotificacionSegura`): `cargar`, `filtrar`, `gruposFiltrados`, `estadoDe` (con un reloj inyectable), `abrir`, `cerrar` y `procesando`. Abrir y cerrar reemplazan solo ese grupo con el que devuelve el backend, sin recargar la lista. Una segunda operación sobre el mismo grupo mientras la primera sigue en camino devuelve `Fallo(0)` y no sale a la red.
>   - Pruebas: +16 (7 de dominio, 9 de ViewModel). Suite sin backend: **147 en verde**; diagnóstico sin cambios; 31 warnings.
>   - El ViewModel todavía **no está conectado a ninguna ruta**: eso es la fase 4.
> - En la fase 4, estas 5 pruebas deben pasar a verde **sin cambiar lo que afirman**.
> - **Fase 4 cerrada (2026-10-29).**
>   - `InscripcionesParticularesView` está reescrita sobre `PeriodoInscripcionViewModel`:
>     - lista real de grupos activos, con el estado (Abiertas, Programadas, Cerradas o Sin abrir) y las fechas;
>     - filtro por categoría, con la opción "Todas";
>     - diálogo por grupo con Abrir (desde hoy, sin límite), Cerrar y Programar (rango con `AlertFechas`), deshabilitados mientras el grupo procesa;
>     - confirmaciones con el `context` de la pantalla y resultado con `DialogExito`/`DialogError`.
>   - La ruta `InscripcionesParticulares` usa ahora `MultiProvider` con `CategoriaViewModel(..listarYNotificarCategorias())` y `PeriodoInscripcionViewModel(..cargar())`. Ya no usa `cargarCategorias(context)`.
>   - `InscripcionesGeneralesView` aplica D1: Abrir, Cerrar y Programar se muestran deshabilitados, con un aviso que remite a la configuración detallada. Se quitaron los diálogos que confirmaban sin hacer nada y los `print`.
>   - Las 6 pruebas de la fase 1 pasaron a verde **sin cambiar lo que afirman** y se movieron a `test/unitarias/vista/inscripcionesCoordinador_test.dart`, sin etiqueta ni prefijo `BUG`. IN-01, IN-02 e IN-03 quedan **corregidos**.
>   - Suite sin backend: **153 en verde**. `test/diagnostico`: 19 en rojo (los de asistencias). `flutter analyze`: 31 warnings, sin cambios; las infos bajan de 317 a 312.
> - **Fase 5 cerrada (2026-10-29).**
>   - **I-Local:** `test/integracion/inscripciones_integracion_test.dart`, 3 casos en verde: abrir un grupo, con una carga y una apertura, sin recarga, y el estado cambia a "Abiertas"; un 400 se muestra en `DialogError` y el grupo no cambia; el filtro por categoría no vuelve a pedir datos.
>   - **I-Remota:** `test/remoto/viewModel/grupo/vmPeriodoInscripcionTest.dart`, 7 casos en verde contra el backend, sobre un grupo propio cuya categoría lleva espacio y tilde:
>     - un grupo nuevo no tiene periodo;
>     - abrir lo hace inscribible;
>     - **el día del cierre sigue siendo inscribible** (confirma la regla que se había inferido);
>     - una apertura futura queda programada y no es inscribible;
>     - un cierre anterior a la apertura da 400 y no cambia nada;
>     - cerrar lo deja no inscribible;
>     - un grupo inexistente da 404.
>   - **Hallazgos del backend al correr la suite remota completa:**
>     1. `POST /inscripcion` exige ahora inscripciones abiertas (`409 GC-0012`). `VmGruposInscripcionTest` se actualizó: un caso nuevo fija la regla y el ciclo abre el grupo antes de inscribir.
>     2. **`GET /validarInscripcion` cambió de cuerpo a parámetros de query y la app sigue enviando cuerpo → IN-07 confirmado.** La validación siempre devuelve `false`. El ciclo de inscripción queda **en rojo** hasta corregirlo.
>   - **Suites:** sin backend, **156 en verde**; remota, **64 de 65** (falla solo el ciclo de inscripción por IN-07); `flutter analyze`: 31 warnings.
> - **IN-07 corregido (2026-10-29), fuera del alcance original pero bloqueaba el flujo completo:** `Conexioninscripcionremoto.validarInscripcion` envía `queryParameters` en vez de cuerpo y también captura `Error`. +4 pruebas de conexión. Sin backend: **160 en verde**; remota: **65 de 65**; 31 warnings. Solo puede ajustarse cómo se encuentra la tarjeta del grupo (hoy `MiniTarjeta`), si la vista nueva usa otro widget.

| Fase | Contenido | Pruebas | Criterio de salida |
|---|---|---|---|
| **0. Contrato real** | `test/contratos/inscripciones/` con las respuestas **observadas** (no propuestas): `abrir_200.json`, `cerrar_200.json`, `abrir_400_cierre.json`, `abrir_400_formato.json`, `grupo_404.json` y `gruposNoEliminados_200.json`, más un `LEEME.md` con la tabla 1.1 | — | Archivos revisados contra las respuestas de esta sesión |
| **1. Diagnóstico primero** | Pruebas rojas en `test/diagnostico/inscripciones/` para IN-01, IN-02 e IN-03: confirmar "Abrir" produce una llamada; "Programar" envía las fechas; la lista muestra los grupos del backend y no 20 ficticios | U-Vista, con dobles | Las pruebas salen en rojo y pasan a *confirmado* en el registro |
| **2. Capa de datos** | Modelo, `PeriodoInscripcionModelo`, conexión, doble, repositorio, servicio | **U-Modelo:** `fromJson` lee las dos fechas con la clave real. **U-Con** con `AdaptadorHttpFalso`: URI con `queryParameters` codificados (categoría con espacio y tilde), cuerpo sin claves nulas, sin cuerpo en cerrar, 200 → modelo, 400 → mensaje `cierreValido`, 404 → `GC-0003`, sin red → 503. **U-Repo:** conversión y errores sin cambios (`same`) | Suite verde |
| **3. Dominio y ViewModel** | `estadoInscripcion(hoy)` y `PeriodoInscripcionViewModel` | **U-Dominio:** los 4 estados y los bordes (cierre = hoy, apertura = hoy). **U-VM:** carga, filtro, abrir y cerrar reemplazan solo el grupo, `procesando` durante la operación, `Fallo` con el mensaje del 400 y del 404, sin notificar tras `dispose` | Suite verde |
| **4. Vista y ruta** | `InscripcionesParticularesView` real, ruta con `MultiProvider` y decisión D1 en la vista general | **U-Vista:** lista real; estado y fechas por tarjeta; abrir, programar y cerrar con diálogo de resultado; botón deshabilitado mientras procesa. Las pruebas de la fase 1 pasan a verde y **se mueven** a `test/unitarias/vista/` | IN-01 a IN-03 pasan a *corregido* |
| **5. Integración** | **I-Local** (`test/integracion/`): ruta real + cadena real sobre `AdaptadorHttpFalso` → abrir y ver el estado actualizado. **I-Remota** (`test/remoto/`, registrada en `main_test.dart`): con grupo propio creado en `setUpAll` (patrón de `VmGruposInscripcionTest`): abrir → aparece en `/gruposInscripcion` → cerrar → desaparece; programar a futuro → no aparece; cierre inválido → 400; **cierre = hoy** → ¿aparece? (confirma la regla de 1.1) | I-Local e I-Remota | Suite sin backend verde y suite remota verde con el backend levantado |
| **6. Cierre** | Registro (IN-01 a IN-03 corregidos; BK-01 a BK-04 enviados al backend); `CLAUDE.md` (comportamientos del backend fijados por las pruebas nuevas, sección "Backend behaviours") | — | Documentación al día |

**Tamaño estimado:**
- fases 0 a 2: pequeñas;
- fase 3: pequeña;
- fase 4: mediana, porque se reescribe la vista;
- fase 5: pequeña o mediana.

## 5. Fuera de alcance

- Abrir o cerrar por categoría, salvo que se decida D1-a.
- Mostrar las fechas al alumno (D3).
- Comprobación de rol en pantalla y ruta: módulo de roles, al final.
- Corregir el resto de `InscripcionesGeneralesView` (sigue con `cargarCategorias(context)` mientras no se toque).
