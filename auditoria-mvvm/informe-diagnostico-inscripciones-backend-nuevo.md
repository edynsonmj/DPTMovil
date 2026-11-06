# Inscripciones contra el backend nuevo: informe de diagnóstico (2026-11-05)

Backend: `BackDeporteParaTodos (Nuevo)` en `localhost:8082`, arriba durante todo el diagnóstico. Detalle y evidencia de cada ID: [registro-bugs.md](registro-bugs.md), «Módulo 4: revisión contra el backend nuevo» y «Compatibilidad con el backend nuevo». No se tocó `lib/` ni se hizo commit.

## Conclusión

El flujo básico funciona: las tres rutas de la app existen y aceptan lo que se les envía. Lo que falla es lo nuevo del backend. La lista de espera no existe para la app, y el estado que ve el alumno puede ser falso justo después de inscribirse. Lo más grave es IN-14: un alumno inscrito puede perder su cupo.

## Parte 1: lo probado

Cada fila tiene una prueba en rojo con su ID. La severidad se fija por lo que la prueba demuestra.

| Sev. | ID | Qué pasa | Responsable |
|---|---|---|---|
| A | IN-14 | Repetir la inscripción con el grupo lleno pasa al alumno de `INSCRITO` a `EN_ESPERA`. El cupo queda libre y nadie lo ocupa | backend |
| A | BK-06 | Con el grupo lleno, la pantalla dice «Te has inscrito al grupo» aunque el alumno quedó en lista de espera | app |
| M | BK-09 | Si la inscripción se envía en la segunda mitad de un segundo, la tarjeta vuelve a «Matricular», sin error. **Causa probada:** la fecha se redondea al segundo siguiente y queda en el futuro | backend |
| M | BK-07 | Repetir una inscripción activa responde 201 y reescribe la fecha. Un alumno inexistente da 500 con la traza de Spring | backend |
| M | IN-15 | Un alumno en lista de espera ve «Matricular» y no puede saber que está en la lista ni salir de ella | app |
| M | IN-16 | Todo rechazo se muestra como el JSON de la respuesta, con `codigoError`, `url` y `metodo` | app |
| M | IN-17 | Con el token vencido, el diálogo de error se abre en blanco | app |
| B | IN-11 | Una inscripción con fecha no se puede enviar. Latente: la pantalla no pone fechas | app |
| B | IN-12 | Un `TypeError` de la conexión escapa del repositorio. Latente | app |

### Cambios de estado

- **Corregido:** IN-13, por el backend. Su prueba quedó en verde y pasó a la suite remota.
- **Siguen corregidos:** IN-01 a IN-03 e IN-06 a IN-10.
- **Descartado como bug:** el 422 de un grupo cerrado (parte de BK-07). Es regla nueva y la app lo trata bien.
- **Corrección al registro:** un grupo inexistente sí da 404. BK-07 decía 500.
- **Causa anterior de BK-09 descartada:** no era la zona horaria de Bogotá.

### Pruebas con expectativa vieja

Estas pruebas siguen en rojo porque esperan reglas del backend anterior. No se cambiaron, porque la instrucción era no tocar pruebas rojas:

| Prueba | Espera | Hoy |
|---|---|---|
| `VmInscripcionTest` · prueba1 | 409 al repetir | 201 (BK-07, se decide con el backend) |
| `VmInscripcionTest` · prueba4 | 409 con el grupo lleno | 201 `EN_ESPERA`, regla nueva |
| `VmInscripcionTest` · prueba5 | 404 con alumno inexistente | 500 (BK-07) |
| `VmGruposInscripcionTest` · prueba3 | 409 `GC-0012` con el grupo sin abrir | 422 |

`prueba2`, `prueba7` y `VmGruposInscripcionTest` · prueba4 solo salen rojas cuando BK-09 les toca: el resultado cambia entre corridas (5 o 3 rojas en el grupo de inscripción).

## Parte 2: lo que queda por comprobar

**Con el equipo del backend**
- El tipo de la columna `inscr_fechainscripcion`. La causa de BK-09 se observó en la respuesta y en la prueba, no en el esquema.
- Si repetir una inscripción activa debe dar 409. Las pruebas del backend cubren reactivar filas desvinculadas, no filas activas.
- La vigencia del JWT (`app.jwt.expiration-ms`), para saber cuán seguido ocurre IN-17 en uso normal.
- Si un alumno en lista de espera puede pasar a `INSCRITO` saltándose la cola (H-IN-05, solo lectura del código).

**Con el cliente**
- Si el catálogo debe ocultar cursos que no van dirigidos al alumno (H-IN-01).
- Si el alumno debe saber antes de pulsar que llegó al límite de 3 cursos (H-IN-02).
- Si la lista de espera, la promoción y la disponibilidad deben tener pantalla en la app móvil (H-IN-04).
- Si las fechas de inscripción van solo por grupo (IN-05).

**Sin probar**
- IN-14 se probó repitiendo la petición desde el ViewModel, no tocando el botón dos veces en el emulador.
- Nada de esto se vio en el emulador ni con un login real de Google: la suite firma su propio JWT.
- Cuántas inscripciones afecta BK-09: se deduce que cerca de la mitad, pero no se midió (H-IN-06).

## Orden sugerido para corregir

1. **IN-14 y BK-09, en el backend:** son los que dejan datos o estado incorrectos.
2. **BK-06 e IN-15, en la app:** leer `estado` del 201 y de `/inscripcion/misCursos`.
3. **IN-16 e IN-17:** extraer `mensaje` de la respuesta y poner un texto para 401. Conviene hacerlo junto con IT-01, porque la causa es la misma.

## Archivos de prueba

- `test/diagnostico/inscripciones/vista_diagnostico_test.dart`, nuevo.
- `test/diagnostico/inscripciones/remoto_diagnostico_test.dart` y `test/remoto/viewModel/inscripcion/vmInscripcionTest.dart`, casos nuevos.
- `test/contratos/inscripciones/`, 7 contratos nuevos.
- `test/main_test.dart`, una línea para la prueba de IN-13.

Los totales de `CLAUDE.md` quedan desactualizados: la suite remota pasa de 108 a 109 y la de diagnóstico de 78 a 90.
