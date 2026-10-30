# Plan de diagnóstico: módulo 6, Horarios

Fecha: 2026-10-29 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulos ya hechos: inscripciones, estadísticas, grupos, cursos, categorías y clases.

> **Estado al 2026-10-29: ejecutado.** 15 escenarios: 5 pruebas en rojo dan 3 hallazgos (HO-01 a HO-03), todos B, y una evidencia más de GR-05. H-06 queda descartada. Lo de más peso no es un hallazgo de prueba sino una observación: **no existe forma de registrar horarios** (H-07). Detalle en [registro-bugs.md](registro-bugs.md), sección «Módulo 6».

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios.

## 1. Alcance

Horarios es **solo lectura**:

```
Grupos asignados (instructor) / Grupos de inscripción (alumno)
   Horariosviewmodel.cargarHorariosDe(grupos)    una petición por grupo, en paralelo; cada tarjeta lee horariosDe(grupo)
Pantalla del grupo
   DetalleGrupoViewModel._cargarHorarios
        → Serviciohorario → Horariorepositorio → Conexionhorariosremoto   GET /horarios?categoria&curso&anio&iterable
```

**Límite importante, comprobado el 2026-10-29:**
- `/v3/api-docs` publica **solo** `GET /horarios`: no hay ninguna ruta para crear, editar ni eliminar horarios.
- La BD de pruebas tiene **0 horarios** en sus 124 grupos (consultados uno por uno).

Por eso la parte remota solo puede comprobar la lectura vacía. Los casos con datos van por la integración local, con un contrato **armado a partir del esquema** `HorarioEntidad` de `/v3/api-docs` (`id`, `categoria`, `curso`, `anio`, `iterable`, `dia`, `horaInicio`, `horaFin`, `escenario`, `eliminado`), no observado.

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **U-Repo** | `Horariorepositorio(ConexionhorariosFalsa)` | `test/unitarias/repositorio/horarioRepositorio_test.dart` (nuevo; el caso feliz ya está en `horarioAlumnoInstructorRepositorio_test.dart`) |
| **I-Local** | `Horariosviewmodel` → `Conexionhorariosremoto` → `Dio(AdaptadorHttpFalso)` | `test/integracion/horarios_integracion_test.dart` (nuevo) |
| **I-Remota** | `Horariosviewmodel` y `DetalleGrupoViewModel` contra el **backend**, con un grupo propio | `test/remoto/viewModel/horario/vmHorarioDiagnosticoTest.dart` (nuevo, en `main_test.dart`) |

Las rojas van a `test/diagnostico/horarios/` con el prefijo `BUG HO-xx`.

## 3. Hipótesis

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-01 | Modelo / repositorio | El `id` del horario se pierde: `HorarioModelo.fromJson` no lo lee y `Horarioentidad.fromModelo` no lo copia | U-Repo (del modelo a la entidad) + I-Local (del JSON a la entidad) |
| H-02 | Conexión | Un horario con un campo obligatorio nulo lanza un `TypeError` desde `fromJson` que atraviesa la conexión (solo captura `Exception`), el repositorio (la llamada está fuera de su `try`) y `listarHorariosGrupo` del VM; la tarjeta muestra el texto técnico | I-Local: el error de la tarjeta tiene el formato `Código: …` |
| H-03 | Repositorio | Un `TypeError` de la conexión atraviesa el repositorio | U-Repo con el doble lanzando |
| H-04 | Conexión | `/horarios` concatena la llave sin codificar (es la familia de GR-05) | I-Local: query enviada. Contra el backend no se puede ver: sin horarios, "consulta rota" y "sin horarios" dan lo mismo |
| H-05 | Modelo | La app no lee `eliminado`: si el backend devolviera horarios eliminados, se pintarían | Sin prueba: no hay datos ni forma de crearlos para saber si el backend los filtra |
| H-06 | Backend | Un grupo sin horarios, o inexistente, da error en lugar de lista vacía | I-Remota |
| H-07 | Backend / cliente | No existe ninguna forma de registrar horarios: la funcionalidad se muestra en tres pantallas, pero no se puede alimentar | Sin prueba (es una funcionalidad que no existe, como IN-05); se registra como observación |

## 4. Criterio de terminado

- Las pruebas ejecutadas; cada roja con su fila **HO-xx** y su archivo en `test/diagnostico/horarios/`; cada hipótesis confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- Las suites normales siguen en verde y `flutter analyze` sin warnings nuevos.
