# Estadísticas contra el backend nuevo: informe de diagnóstico (2026-11-05)

Backend: `BackDeporteParaTodos (Nuevo)` en `localhost:8082`, arriba durante todo el diagnóstico. Detalle y evidencia de cada ID: [registro-bugs.md](registro-bugs.md), «Módulo 5: revisión contra el backend nuevo». No se tocó `lib/` ni se hizo commit.

## Conclusión

El módulo sigue funcionando: las rutas no cambiaron y ES-05 quedó corregido por el backend. El problema nuevo es **ES-06**: la gráfica muestra menos horas de las reales cuando un horario no es de horas exactas. La pregunta abierta más importante es para el cliente: las estadísticas cuentan clases registradas, no asistencias.

## Parte 1: lo probado

Cada fila tiene una prueba en rojo con su ID. La severidad se fija por lo que la prueba demuestra.

| Sev. | ID | Qué pasa | Responsable |
|---|---|---|---|
| M | **ES-06** (nuevo) | Tres clases de 1 h 30 llegan como 3 horas y 90 minutos. La gráfica pinta 3 en lugar de 4,5 y ordena mal | backend o app |
| B | **ES-07** (nuevo) | Con el token vencido, cada sección muestra `Código: 401 - ` sin texto | app |
| B | ES-04 | El orden solo mira `horas`: 1 h 10 min queda delante de 1 h 50 min | app |
| B | ES-01 | Un `TypeError` atraviesa el repositorio. Latente | app |
| B | ES-02 | Una fila sin `leyenda1` muestra el texto de la excepción. Latente | app |
| B | ES-03 | Un número entero en el JSON rompe la sección. Latente: el backend siempre manda `.0` | app |

BK-02 sigue confirmado (la app registra asistencia en una ruta que da 404), ahora con una prueba propia.

### Cambios de estado

- **Corregido:** ES-05, por el backend. Su prueba quedó en verde y pasó a la suite remota.
- **Siguen descartadas:** H-06 a H-09.
- **Volvieron a correr:** los casos de `VmEstadisticasAsistenciaTest`, antes bloqueados por su `setUpAll`. Ahora están en verde.

### Cambio en las pruebas

`VmEstadisticasAsistenciaTest` sembraba la asistencia por una ruta que ya no existe. Ahora usa `PUT /clase/{codigo}/asistencia`. Es un cambio de siembra: no se tocó ninguna aserción.

## Parte 2: lo que queda por comprobar

**Con el cliente**
- Qué debe medir la gráfica. Hoy cuenta clases registradas, aunque el backend la describe como «atenciones brindadas» (H-12).
- Si debe sumar una clase sin asistencia confirmada. Observado: suma (H-13).
- Si debe sumar una clase con novedad `NO_REALIZADA`. Observado: suma, aunque el cálculo de faltas del backend sí las excluye (H-ES-01).
- Si un grupo eliminado debe seguir apareciendo con sus horas. Observado: aparece (H-ES-02).
- Si quiere ver en la app las estadísticas por alumno y por instructor (H-ES-04).

**Con el equipo del backend**
- Si `horas` y `minutos` deben llegar normalizados. De eso depende dónde se corrige ES-06.
- La vigencia del JWT, para saber cuán seguido ocurre ES-07.

**Sin probar**
- H-13, H-ES-01 y H-ES-02 se observaron con peticiones directas y no tienen prueba, porque falta la regla que diga cuál es el resultado correcto.
- Nada de esto se vio en el emulador ni con un login real de Google.
- Exportar a Excel no se ejecutó; que herede ES-06 sale de leer el código (H-ES-03).

## Orden sugerido para corregir

1. **ES-06 y ES-04, juntos:** ordenar y graficar por `duracion` resuelve los dos desde la app, sin esperar al backend.
2. **ES-07:** va junto con IN-16, IN-17 e IT-01, porque la causa es la misma.
3. **ES-01 a ES-03:** son latentes, no bloquean.

Antes de tocar las gráficas conviene resolver H-12 con el cliente: si deben contar asistencias, cambia la consulta del backend.

## Archivos de prueba

- `test/diagnostico/estadisticas/integracion_diagnostico_test.dart` y `remoto_diagnostico_test.dart`, casos nuevos.
- `test/remoto/viewModel/estadisticas/vmEstadisticasAsistenciaTest.dart`, siembra y casos nuevos.
- `test/main_test.dart`, una línea para la prueba de ES-05 y un comentario.
- `test/contratos/estadisticas/LEEME.md`, la forma observada de los minutos.

Los totales de `CLAUDE.md` siguen desactualizados: la suite remota pasa de 109 a 110 y la de diagnóstico de 90 a 94, contando lo de inscripciones. También quedó viejo lo que dice de `DELETE /clase`, que ahora sí borra.
