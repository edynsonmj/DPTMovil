# Plan de diagnóstico: módulo 8, Cursos

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulos anteriores: [inscripciones](plan-diagnostico-inscripciones.md), [estadísticas](plan-diagnostico-estadisticas.md), [grupos](plan-diagnostico-grupos.md).

> **Estado al 2026-10-29: ejecutado.** 21 escenarios: 6 pruebas en rojo dan 5 hallazgos (CU-01 a CU-05). El de más peso es CU-02: con un `&` en el título, la categoría pierde sus cursos y el curso da 404 (confirmado contra el backend). H-06 a H-08 quedan descartadas. Además se corrigió el `AdaptadorHttpFalso`, que no aceptaba cuerpos binarios. Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 8».

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios implementados.

## 1. Alcance

```
Categoría → CursosView      CursosViewModel.listarCursosDe(context, categoria)   GET  /cursosbycategoria?prmCategoria
                              (estilo antiguo: si hay error, el propio VM abre DialogError)
FormularioCurso (alta)      CursosViewModel.agregarCurso(entidad)                POST /imagenMultipart  →  POST /curso
Pantalla del curso / grupo  CursosViewModel.obtenerCurso / DetalleGrupoViewModel GET  /curso?prmCategoria&prmCurso
```

`ConexionCursoRemoto` concatena la categoría y el curso en la URL, sin codificar.

Fuera de alcance:
- El modo edición del formulario: `_manejarEditar` está vacío, pero ninguna pantalla abre el formulario con `esEdicion: true`.
- `eliminarCurso`, que lanza `UnimplementedError` y no tiene llamadores.
- Las vistas.

Contrato (`/v3/api-docs`, 2026-10-29):
- `GET /cursosbycategoria` → `200 [CursoDto]`. Comprobado a mano: una categoría sin cursos da `200 []`.
- `GET /curso` → `200`. Comprobado a mano: un curso inexistente da `404 GC-0003`.
- `POST /curso` documenta `200`, pero el backend real responde `201` (lo fijan las pruebas remotas que crean cursos).

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `CursoRepositorio(ConexionCursoFalsa)` | `test/unitarias/repositorio/cursoRepositorio_test.dart` (se amplía) |
| **I-Local** | `CursosViewModel` / `CursoRepositorio` → `ConexionCursoRemoto` + `Conexionimagenremoto` → `Dio(AdaptadorHttpFalso)`, con fixtures en `test/contratos/cursos/` | `test/integracion/cursos_integracion_test.dart` (nuevo) |
| **I-Remota** | `CursosViewModel` contra el **backend**, con categorías propias en `setUpAll` (una de ellas con `&`) | `test/remoto/viewModel/curso/vmCursoDiagnosticoTest.dart` (nuevo, en `main_test.dart`) |

Las rojas van a `test/diagnostico/cursos/` con el prefijo `BUG CU-xx`.

## 3. Hipótesis de partida

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Conexión | `/cursosbycategoria` y `/curso` concatenan los títulos sin codificar: con un `&` la categoría no muestra sus cursos y el curso no se encuentra (en la pantalla del grupo ya se vio el 404: GR-05) | I-Local (query enviada) + I-Remota (categoría y curso con `&` creados en la corrida) |
| H-02 | Conexión | `agregarCurso` hace `curso.imagenFile!`: sin archivo lanza un `TypeError` que atraviesa conexión, repositorio y VM (`agregarCurso` del VM no tiene `try`). Es la versión de cursos de CAT-01 | I-Local: el VM devuelve un error, sin lanzar |
| H-03 | Repositorio | El repositorio no tiene `try`: un `TypeError` de la conexión lo atraviesa | U-Repo con el doble lanzando |
| H-04 | Conexión | `obtenerCurso` y `enconcontrarCursosDe` solo capturan `Exception`: un curso incompleto en el JSON lanza un `TypeError` desde `CursoModelo.fromJson` | I-Local: el repositorio sobre la conexión real devuelve un error, sin lanzar |
| H-05 | VM | `listarCursosDe` con un error abre **dos** diálogos: el del código y, como `datos` no es una lista, otro de "datos inconsistentes" | I-Local con `testWidgets`: un 500 → un solo `DialogError` |
| H-06 | Backend | Un curso con el mismo nombre en la misma categoría se crea dos veces | I-Remota: el segundo alta no da 201 |
| H-07 | Backend | Un curso en una categoría inexistente, o con nombre o descripción vacíos, se crea igual | I-Remota: no da 201 |
| H-08 | Conexión / VM | Una categoría sin cursos da error en lugar de lista vacía | I-Remota (visto a mano: `200 []`) |
| H-09 | Vista | `_submitForm` vacía el formulario **antes** de enviar: si el alta falla, el usuario pierde lo que escribió | Sin prueba: es de la vista |
| H-10 | Conexión | Si el `POST /curso` falla después de subir la imagen, la imagen queda huérfana | Sin prueba como hallazgo: es esperado por cómo están hechos los dos pasos, y en la BD de pruebas se acepta |

## 4. Criterio de terminado

- Las pruebas ejecutadas. Cada roja tiene su fila **CU-xx** y su archivo en `test/diagnostico/cursos/`; cada hipótesis queda confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- La suite sin backend y la remota siguen en verde, y `flutter analyze` sin warnings nuevos.
