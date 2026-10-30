# Plan de diagnóstico: módulo 5, Estadísticas

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulo anterior: [plan-diagnostico-inscripciones.md](plan-diagnostico-inscripciones.md).

> **Estado al 2026-10-29: ejecutado.** 20 escenarios: 5 pruebas en rojo dan 5 hallazgos (ES-01 a ES-05). ES-05, "el último día del rango no cuenta", es del backend y de severidad M; los demás son B. H-06 a H-09 quedan descartadas y H-10 a H-15 sin verificar; H-12 es una observación para el cliente. Detalle y lista de escenarios en [registro-bugs.md](registro-bugs.md), sección «Módulo 5».

**Regla (la misma que en inscripciones):** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo que sale de leer el código, o de una observación sin una afirmación que falle, va a la lista de **hipótesis**. Una hipótesis cuya prueba sale verde queda **descartada**.

## 1. Alcance

Pantalla `EstadisticasGeneralesView` (ruta `estadisticasGenerales`), del coordinador:

```
diálogo de fechas (AlertFechasEstadisticas, yyyy-mm-dd; la fecha final no puede ser anterior a la inicial)
  → EstadisticasViewModel.cargar(inicio, fin)       tres secciones en paralelo, con contador de peticiones
     → ServicioEstadisticas → EstadisticasRespositorio → Conexionestadisticasremoto
        GET /estadisticas/categorias?inicio&fin
        GET /estadisticas/cursos?inicio&fin
        GET /estadisticas/grupos?inicio&fin
  → cada sección se ordena por horas; "grupos" se puede exportar a Excel
```

Fuera de alcance:
- Las pantallas de estudiantes, instructores e institucionales: la conexión no tiene sus métodos (`institucional*` lanza `UnimplementedError`) y `/estadisticas/alumnos` e `/estadisticas/instructores` no tienen consumidor.
- La exportación a Excel, que escribe en el sistema de archivos del dispositivo.
- La vista: este plan no incluye pruebas de widget.

Contrato del backend (`/v3/api-docs`, 2026-10-29): las tres rutas reciben `inicio` y `fin` obligatorios (`YYYY-MM-DD`) y responden `200 [EstadisticaDto]`. `EstadisticaDto` tiene:
- `leyenda1` a `leyenda4`: categoría, curso, año e iterable, según la ruta;
- `clases`, `horas`, `minutos` y `duracion`, todos `double`. Según el modelo de la app, `minutos` son los que sobran de las horas y `duracion` es el total en minutos.

El backend responde los números como `1.0` y `0.0`.

**Novedad para el módulo 1:** el backend ya publica `GET` y `POST /asistenciasClase`. La app sigue usando `/atencionesporclase` y `/atenciones` (AS-B01), así que aquí solo se usa la ruta nueva para **sembrar** datos de prueba, sin pasar por el código de la app.

## 2. Niveles de prueba

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `EstadisticasRespositorio(ConexionEstadisticasFalsa)` | `test/unitarias/repositorio/estadisticasRepositorio_test.dart` (se amplía) |
| **I-Local** | `EstadisticasViewModel → Servicio → Repositorio → Conexionestadisticasremoto → Dio(AdaptadorHttpFalso)` con fixtures de `test/contratos/estadisticas/`: para sin red y para respuestas que el backend real no da | `test/integracion/estadisticas_integracion_test.dart` (nuevo) |
| **I-Remota** | La misma cadena contra el **backend real**, con un grupo, una clase de 2 h de ayer y una asistencia registrada en `setUpAll` | `test/remoto/viewModel/estadisticas/vmEstadisticasAsistenciaTest.dart` (nuevo, en `main_test.dart`) |

Las pruebas rojas van a `test/diagnostico/estadisticas/` con el prefijo `BUG ES-xx`.

## 3. Hipótesis de partida (lectura del código)

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Repositorio | El repositorio no tiene `try`: cualquier excepción de la conexión lo atraviesa | U-Repo: el doble lanza un `TypeError` → se devuelve `RespuestaModelo` de error |
| H-02 | Modelo / conexión | `EstadisticaModelo.fromJson` con `leyenda1: null` lanza un `TypeError` que escapa de la conexión (solo captura `Exception`) y del repositorio. El VM lo atrapa y la sección muestra el texto técnico | I-Local: la sección muestra el error con el formato normal (`Código: …`) |
| H-03 | Modelo | `fromJson` asigna `json['clases']` a un `double`: un número entero en el JSON (`1` en vez de `1.0`) lanza un `TypeError` | I-Local: 200 con enteros → se convierte sin error |
| H-04 | VM | Se ordena solo por `horas` y se ignoran los `minutos`: 1 h 10 min puede quedar delante de 1 h 50 min | I-Local: dos filas con `horas: 1` → la de más `duracion` primero |
| H-05 | Backend | El día final del rango no cuenta: la clase es un *date-time* y el filtro es por *date* | I-Remota: el rango `[ayer, ayer]` incluye la clase de ayer |
| H-06 | Backend | Las estadísticas no reflejan una asistencia recién registrada | I-Remota: la categoría nueva aparece con 1 clase y 120 minutos |
| H-07 | Backend | Registrar dos veces la misma asistencia la cuenta dos veces | I-Remota: tras repetir el POST, los valores no cambian |
| H-08 | Backend | Los totales no cuadran entre secciones o dentro de una fila | I-Remota: en todas las filas de las 3 secciones `horas × 60 + minutos == duracion`; la categoría nueva, su curso y su grupo (los únicos que tiene) dan los mismos totales |
| H-09 | Backend | Un rango que no incluye la clase la cuenta igual | I-Remota: la categoría nueva queda en 0 o no aparece |
| H-10 | Backend / cliente | Un rango sin clases devuelve todas las categorías en 0 en lugar de una lista vacía (ya fijado por `prueba3RangoSinClases`, señal D4) | Sin prueba nueva: es una regla del cliente, no un comportamiento correcto definido |
| H-11 | Backend | Un rango invertido (`inicio > fin`) responde 200 con ceros en vez de 400 | Sin prueba: el diálogo de fechas ya impide elegirlo (`primeraFecha` del selector final) |
| H-12 | Backend / cliente | No está definido si `clases` cuenta clases dictadas o asistencias | Observación en I-Remota (se marca un segundo alumno y se imprime el resultado); queda para el cliente |

## 4. Pruebas a escribir

### 4.1 U-Repo

| Caso | Afirma |
|---|---|
| Categorías 200 | Entidades con `leyenda1` y sin `leyenda2` |
| Cursos 200 | Entidades con categoría y curso |
| `200 []` en las 3 rutas | Lista vacía de entidades, código 200 |
| Error en categorías y grupos | Pasa sin cambios (`same`) |
| 200 sin lista en cursos y grupos | Código 0 con error (en categorías ya existe) |
| H-01 | Un `TypeError` del doble se devuelve como error |

### 4.2 I-Local

| Caso | Afirma |
|---|---|
| Carga con el contrato | 3 GET con `inicio` y `fin` exactos en la query; secciones con sus filas, sin error |
| `200 []` | Secciones vacías, sin error, no se puede exportar |
| Sin red | Las 3 secciones con `Código: 503` |
| 400 en texto plano | `Código: 400` y el texto del backend |
| 200 con un objeto | `Código: 406` |
| H-02, H-03, H-04 | Según la tabla 3 |

### 4.3 I-Remota

Ver H-05 a H-09 y H-12 en la tabla 3. Datos en `setUpAll`, con cada paso por su VM: categoría, curso, grupo, apertura de inscripciones, dos alumnos inscritos y una clase de 2 h con fecha de ayer. La asistencia del alumno A se registra con `POST /asistenciasClase`.

## 5. Criterio de terminado

- Las pruebas ejecutadas y cada roja con su fila **ES-xx** en `registro-bugs.md` y su archivo en `test/diagnostico/estadisticas/`.
- Cada hipótesis queda como *confirmada → ES-xx*, *descartada* o *sin verificar*.
- El registro incluye la lista de escenarios implementados con su resultado.
- La suite sin backend y la remota siguen en verde, y `flutter analyze` sin warnings nuevos (31).
