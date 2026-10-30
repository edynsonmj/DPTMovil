# Plan de diagnóstico: módulo 7, Categorías

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md) (las hipótesis de partida son las del **anexo A**, CAT-01 a CAT-12 y T-01 a T-05). Registro: [registro-bugs.md](registro-bugs.md). Módulos anteriores: [inscripciones](plan-diagnostico-inscripciones.md), [estadísticas](plan-diagnostico-estadisticas.md), [grupos](plan-diagnostico-grupos.md), [cursos](plan-diagnostico-cursos.md).

> **Estado al 2026-10-29: ejecutado.** 23 escenarios: 10 pruebas en rojo dan 9 hallazgos (CAT-01 a CAT-06, CAT-09, CAT-13 y CAT-14). El de más peso es CAT-03: una categoría con `&` no se puede editar ni eliminar (confirmado contra el backend). T-01 a T-03 quedan confirmadas como pruebas hechas para pasar, y CAT-15 queda descartada. CAT-16 (borrado lógico) es una observación para el cliente. Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 7».

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. Los ID del anexo A se conservan (un `CAT-xx` confirmado sigue siendo `CAT-xx`) y las hipótesis nuevas siguen desde CAT-13. El registro incluye la lista de escenarios.

## 1. Alcance

```
CategoriasView (inicio)         CategoriaViewModel.listarYNotificarCategorias   GET    /categorias2
InscripcionesGenerales           cargarCategorias(context)  (estilo antiguo, abre DialogError)
CategoriaFormulario              guardarCategoria → insertarCategoria            POST   /imagenMultipart → POST /categoria
                                                  → actualizarCategoria          [POST /imagenMultipart] → PUT /categoria?titulo=
Eliminar (CategoriasView)        eliminarCategoria                               DELETE /categoria?titulo=
```

En `PUT` y `DELETE`, el título va **concatenado** en la URL, sin codificar.

Fuera de alcance:
- CAT-10, el botón de quitar imagen del formulario, que es de la vista.
- CAT-12, `perfilSesion`, que se aplaza al módulo de autenticación por decisión del 2026-10-29.
- CAT-08 (`receiveTimeout` → 0), ya confirmado como AS-12, que es transversal.

Contrato (`/v3/api-docs`, 2026-10-29):
- `GET /categorias2` → 200.
- `POST /categoria` → 201.
- `PUT /categoria?titulo=` → 200.
- `DELETE /categoria?titulo=` → 200.
- `GET /categoria?titulo=` devuelve la categoría "aunque esté marcada como eliminada", lo que indica un **borrado lógico**.

La suite remota ya fija 24 casos: alta, validaciones 400, actualización, borrado, 404 y formulario. Este plan no los repite.

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `CategoriaRepositorio(ConexionCategoriaFalsa)` | `test/unitarias/repositorio/categoriaRepositorio_test.dart` (se amplía) |
| **I-Local** | `CategoriaViewModel` → `ConexionCategoriaRemota` + `Conexionimagenremoto` → `Dio(AdaptadorHttpFalso)`, con fixtures en `test/contratos/categorias/` | `test/integracion/categorias_integracion_test.dart` (nuevo) |
| **I-Remota** | `CategoriaViewModel` contra el **backend** | `test/remoto/viewModel/categoria/vmCategoriaDiagnosticoTest.dart` (nuevo, en `main_test.dart`) |

Las rojas van a `test/diagnostico/categorias/` con su `BUG CAT-xx`.

## 3. Hipótesis

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| CAT-01 / T-01 | Conexión → VM | Insertar con `idImagen` y sin archivo: la conexión hace `datos.imagenFile!` y el `TypeError` llega al VM, que devuelve `Fallo(-1, "Null check…")`. La prueba unitaria T-01 pasa en verde con el doble porque este acepta lo que la conexión real no | I-Local con la cadena real |
| CAT-14 | Repositorio | `insertarCategoria` acepta `idImagen` como imagen suficiente, pero arma el modelo **sin** `imagenId`: la imagen existente se pierde | U-Repo: el modelo enviado lleva `imagenId` |
| CAT-02 | Conexión / repositorio | Un `POST /categoria` con 201 y sin cuerpo (o un `PUT` con 200 y sin cuerpo) no llega como éxito: `fromJson(null)` lanza, o el repositorio lo cambia a 204 y el VM devuelve `Fallo` | I-Local: 201 sin cuerpo → `Exito` |
| CAT-03 | Conexión | `PUT` y `DELETE` concatenan `?titulo=` sin codificar: una categoría con `&` no se puede editar ni eliminar | I-Local (query) + I-Remota (categoría con `&` creada en la corrida) |
| CAT-04 | VM | `CategoriaViewModel` no usa `NotificacionSegura`: si la ruta se cierra mientras se carga, notifica después de `dispose` y lanza | I-Local: respuesta retenida, `dispose`, liberar → sin excepción |
| CAT-05 | VM | `cargarCategorias(context)` pinta `DialogError` con **código 204** en cualquier error (un 500 se muestra como 204) | I-Local con `testWidgets`: un 500 → el diálogo lleva 500 |
| CAT-06 | Conexión | `categoriaModelo.fromJson` con un campo obligatorio nulo lanza un `TypeError` que atraviesa conexión y repositorio; el VM muestra el texto técnico | I-Local: el error tiene el formato `Código: …` |
| CAT-09 | VM | Dos cargas solapadas sin contador: la respuesta **vieja** puede llegar la última y pisar la nueva | I-Local: primera carga retenida, segunda con la lista nueva, liberar la primera → queda la nueva |
| CAT-13 | Repositorio | El repositorio no tiene `try`: un `TypeError` de la conexión lo atraviesa | U-Repo con el doble lanzando |
| CAT-15 | Backend | Se puede crear dos veces una categoría con el mismo título | I-Remota: el segundo alta no es `Exito` |
| CAT-16 | Backend / cliente | Después de eliminar una categoría (borrado lógico), ¿se puede volver a crear con el mismo título? ¿Qué pasa con sus cursos? | Observación en I-Remota (se imprime; sin afirmación) |
| CAT-07 | Modelo | `ErrorModelo.mensaje` (`String`) recibe `response.data`, que puede ser un `Map`, en `fromResponse` | Sin prueba nueva: solo ocurre con un 2xx inesperado con cuerpo JSON; queda cubierto en parte por CAT-02 |
| CAT-11 | Rutas | `route_generator.dart:30` importa `views/Categorias/`, pero la carpeta es `categorias/`: no compila en un sistema que distingue mayúsculas | Sin prueba: en Windows compila. Confirmado leyendo el código y `git ls-files` |

## 4. Criterio de terminado

- Las pruebas ejecutadas; cada roja con su fila en el registro y su archivo en `test/diagnostico/categorias/`; cada hipótesis confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- Las suites normales siguen en verde y `flutter analyze` sin warnings nuevos.
