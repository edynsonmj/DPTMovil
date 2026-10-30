# Plan de diagnóstico: módulo 2, Clases

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulos ya hechos: [inscripciones](plan-diagnostico-inscripciones.md), [estadísticas](plan-diagnostico-estadisticas.md), [grupos](plan-diagnostico-grupos.md), [cursos](plan-diagnostico-cursos.md), [categorías](plan-diagnostico-categorias.md).

> **Estado al 2026-10-29: ejecutado.** 19 escenarios: 6 pruebas en rojo dan 5 hallazgos nuevos (CL-01, CL-03 a CL-06) y una evidencia más de GR-05. El más grave es **CL-06 (A)**: la fecha elegida en el selector se guarda un día antes, porque el backend toma como UTC la hora sin zona. CL-01: eliminar una clase no la quita. H-02 y H-03 quedan descartadas. Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 2».

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios.

## 1. Alcance

```
Pantalla del grupo     DetalleGrupoViewModel.cargarClases       GET    /clasesGrupo?categoria&curso&anio&iterable
                       DetalleGrupoViewModel.eliminarClase      DELETE /clase?id=   → recarga la lista
Formulario de clase    Clasesviewmodel.registrarClase(fecha, horasTexto)   POST /claseGrupo
                         valida fecha, horas > 0 y grupo inicializado; minutos siempre 0
```

Es el paso previo a la toma de asistencia: sin clase no hay asistencia, y las estadísticas suman sus horas.

Fuera de alcance:
- La toma de asistencia (módulo 1; hay una migración a `/asistenciasClase` en curso en el mismo árbol).
- La vista de la lista de clases (`widgetListaClases`).
- La codificación de `/clasesGrupo`, ya confirmada como GR-05; aquí solo se repite en la conexión de clases como evidencia, sin crear un ID nuevo.

Contrato (`/v3/api-docs`, 2026-10-29):
- `POST /claseGrupo` documenta `200`; el backend real responde `201` (lo fija `VmModuloGrupoTest`).
- `GET /clasesGrupo` → `200`. Un grupo sin clases responde `200` con un objeto `GC-0002`, que la conexión convierte en 406 y el VM trata como lista vacía.
- `DELETE /clase?id=` → `200`. Visto el 2026-10-21: responde 200 **pero la clase sigue en la lista** con `eliminado: 0`. `VmModuloGrupoTest.prueba6EliminarClase200` solo fija ese 200 (señal D4).
- La clase guarda `fecha` como fecha sin hora (`"2026-10-28"`). La app envía `fecha.toIso8601String()` con hora local.

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `Claserepositorio(ConexionclasesFalsa)` | `test/unitarias/repositorio/claseRepositorio_test.dart` (se amplía) |
| **I-Local** | `Clasesviewmodel` y `DetalleGrupoViewModel` → `Conexionclasesremoto` → `Dio(AdaptadorHttpFalso)`, con fixtures en `test/contratos/clases/` | `test/integracion/clases_integracion_test.dart` (nuevo) |
| **I-Remota** | Los mismos VM contra el **backend**, con un grupo propio creado en `setUpAll` | `test/remoto/viewModel/clase/vmClaseDiagnosticoTest.dart` (nuevo, en `main_test.dart`) |

Las rojas van a `test/diagnostico/clases/` con el prefijo `BUG CL-xx`.

## 3. Hipótesis

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Backend | `DELETE /clase` responde 200 pero no borra: la clase sigue en la pantalla del grupo, así que se le podría tomar asistencia y suma en estadísticas | I-Remota: eliminar → `Exito` y la clase ya no está en la lista |
| H-02 | Backend | Eliminar una clase inexistente también responde 200 | I-Remota: el VM devuelve `Fallo` |
| H-03 | Backend / app | Una clase con fecha de **hoy** se rechaza (por un comentario de `VmModuloGrupoTest`: "hoy puede quedar en el futuro para el backend según la zona horaria") | I-Remota: registrar con `DateTime.now()` → `Exito` |
| H-04 | Conexión / backend | La fecha cambia de día al guardarse: la app envía fecha y hora local sin zona y el backend guarda solo la fecha | I-Remota: clases a las 00:30 y a las 23:30 de un día D → las dos se listan con fecha D |
| H-05 | Conexión | `Clasemodelo.fromJson` con `fecha` o `horas` nulas lanza un `TypeError` que atraviesa conexión y repositorio (la conversión del repositorio está dentro del `try`, pero la llamada a la conexión no); la pantalla del grupo muestra el texto técnico | I-Local: la sección de clases muestra un error con el formato `Código: …` |
| H-06 | Repositorio | `Clasemodelo.fromEntidad` hace `fecha!`, `horas!` y `minutos!`: una entidad incompleta lanza un `TypeError` y `agregarClase` solo captura `Exception` | U-Repo: devuelve un error, sin lanzar |
| H-07 | Repositorio | `listarClaseGrupo` y `eliminarClase` no protegen la llamada a la conexión de un `Error` | U-Repo con el doble lanzando |
| H-08 | Cliente | Se puede registrar una clase futura o de 30 horas (AS-13) | Observación en I-Remota (se imprime) |
| H-09 | Conexión | `eliminarClase` etiqueta sus errores con `metodo = "delete"` en minúsculas | Sin prueba: es cosmético |

## 4. Criterio de terminado

- Las pruebas ejecutadas; cada roja con su fila **CL-xx** y su archivo en `test/diagnostico/clases/`; cada hipótesis confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- Las suites normales siguen en verde y `flutter analyze` sin warnings nuevos.
