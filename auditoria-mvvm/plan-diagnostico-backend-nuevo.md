# Plan de diagnóstico de los módulos restantes contra el backend nuevo

**Fecha:** 2026-11-05. **Backend:** `BackDeporteParaTodos (Nuevo)` en `localhost:8082`.

Inscripciones y estadísticas ya se revisaron con este método: [informe de inscripciones](informe-diagnostico-inscripciones-backend-nuevo.md) e [informe de estadísticas](informe-diagnostico-estadisticas-backend-nuevo.md). Este plan cubre el resto. La evidencia de cada ID está en [registro-bugs.md](registro-bugs.md).

## Conclusión

La mayoría de la app sigue siendo compatible. Dos bugs del backend se resolvieron solos (CL-01 y GR-06). La toma de asistencia es lo único roto por completo: sus dos rutas ya no existen (BK-02). También hay dos problemas nuevos de sesión: sin iniciar sesión, la pantalla inicial solo muestra `Código: 401 - ` (BK-10), y «Continuar con correo» ya no puede funcionar (BK-11).

## Reglas

1. Un hallazgo necesita una prueba en rojo, unitaria o remota, con su ID en el nombre.
2. Lo visto por petición directa se anota como observación, no como hallazgo.
3. Si no hay regla que diga cuál es el resultado correcto, va a hipótesis y se pregunta al cliente.
4. Un bug resuelto por el backend pasa su prueba a la suite verde y queda «corregido por el backend».
5. No se corrige `lib/` ni se debilita una prueba roja. Solo se cambian siembras de datos.

## Método por módulo

1. Comparar las rutas de `Conexion*Remoto` con `/v3/api-docs`.
2. Comparar la autorización de cada ruta con el rol que usa la pantalla, con un JWT de cada rol.
3. Pedir la forma real de cada respuesta, incluidas las listas vacías, y compararla con el modelo.
4. Correr las pruebas remotas y de diagnóstico del módulo.
5. Probar los errores que la pantalla puede recibir: 401, 403, 409, 422.
6. Reclasificar los IDs del módulo y escribir las rojas nuevas.

## Módulos

| Módulo | Qué se revisó | Resultado |
|---|---|---|
| Asistencias | Rutas de lista y registro | **Roto:** BK-02. AS-04 y AS-05 se revisan al reescribir la conexión |
| Clases | Registro con y sin horario, misma fecha, borrado, fecha futura | CL-01 resuelto. BK-04 y BK-08 confirmados, con la causa de BK-08 probada |
| Grupos | Listas, alumnos del grupo, errores de creación | GR-06 resuelto. Sin incompatibilidades nuevas |
| Horarios | Lista vacía y forma de la respuesta | BK-05 confirmado |
| Categorías | Lectura por rol, sin sesión, borrado con cursos | BK-10 nuevo. CAT-16a y CAT-16b siguen sin regla |
| Cursos | Forma de la respuesta, duplicado, deporte inexistente | Sin incompatibilidades nuevas. La app no lee `publico` ni `estadoCurso` |
| Alumnos | Forma de `/alumnosGrupo`, grupo vacío | Sin incompatibilidades nuevas. La app no lee `faltas` |
| Instructores y facultades | Forma de las listas, lectura por rol | Sin incompatibilidades nuevas. Sigue la doble codificación |
| Autenticación | Login sin JWT, token inválido, registro | BK-11 nuevo. AU-B01 sigue sin verificar |

## Qué quedó fuera

- **Login real con Google:** `/auth/token` exige un ID Token firmado por Google. No se puede fabricar en una prueba; hay que comprobarlo en el emulador.
- **Listas vacías de instructores y facultades:** no se pueden vaciar por la API.
- **Lo que depende del cliente:**
  - Si un visitante puede ver el catálogo sin sesión (BK-10).
  - Qué pasa con los grupos de una categoría eliminada (CAT-16a).
  - Si se puede reutilizar el título de una categoría eliminada (CAT-16b).
  - Qué días y solapes de horario son válidos (H-13).
- **Pantallas:** todo se probó desde el ViewModel o la conexión. Nada se vio en el emulador.

## Resultado

| Suite | Verde | Rojo |
|---|---|---|
| Sin backend | 351 | 0 |
| Remota (`main_test.dart`) | 105 | 7, todas explicadas |
| Diagnóstico | 7 | 94 (1 omitida) |

Las 7 rojas de la suite remota:

| Causa | Pruebas |
|---|---|
| BK-05 | `VmModuloGrupoTest` · prueba3, `VmHorarioDiagnosticoTest` · prueba1 |
| BK-06 | `VmInscripcionTest` · prueba4 |
| BK-07 | `VmInscripcionTest` · prueba1 y prueba5 |
| BK-08 | `VmClaseDiagnosticoTest` · prueba3 |
| Expectativa vieja | `VmGruposInscripcionTest` · prueba3 |

## Orden sugerido para corregir

1. **BK-02:** reescribir la conexión de asistencias con `PUT /clase/{codigo}/asistencia` y `GET /atencionesporclase`. Es lo único que bloquea una función completa.
2. **BK-08 y BK-05:** cambios pequeños en la conexión: aceptar el 200 y tratar `GC-0002` como lista vacía.
3. **BK-10 y BK-11:** decidir con el cliente el acceso sin sesión y quitar «Continuar con correo».
4. **BK-04:** añadir la justificación al formulario de clase.
5. **IN-16, IN-17, ES-07 e IT-01:** extraer el mensaje de las respuestas de error. Es una sola corrección para varios módulos.

## Pruebas

- **Nuevo:** `test/diagnostico/transversal/remoto_backend_nuevo_test.dart`, 7 rojas y 1 control.
- **Movidas a la suite remota:** CL-01 (`VmClaseDiagnosticoTest.prueba6EliminarClase`) y GR-06 (`VmGrupoDiagnosticoTest.prueba8AlumnoDesvinculado`).
- **Eliminado:** `test/diagnostico/clases/remoto_diagnostico_test.dart`. Solo tenía el caso de CL-01.

`CLAUDE.md` queda desactualizado en cuatro puntos: la suite remota tiene 112 casos, la de diagnóstico 102, `DELETE /clase` ya borra y ya no son seis los `remoto_diagnostico_test.dart`.
