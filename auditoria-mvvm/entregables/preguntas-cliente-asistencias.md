# Preguntas sobre la toma de asistencia

**Para:** coordinación de "Deporte para Todos" · **Fecha:** 2026-10-29

Revisando la toma de asistencia de la app encontramos situaciones en las que no sabemos qué debe pasar. Sus respuestas definen si cada situación es un error que hay que corregir o un comportamiento aceptado. Las opciones son sugerencias; pueden responder otra cosa.

---

**1. ¿Quién puede tomar asistencia de una clase?**
- a) Solo el instructor asignado a ese grupo.
- b) El instructor del grupo y también el coordinador.
- c) Cualquier instructor.

*Hoy la app deja tomar asistencia a cualquiera, incluso a un alumno o a alguien que no inició sesión. Eso se va a corregir en cualquier caso; la respuesta define a quién se le permite.*

**2. ¿Se puede corregir una asistencia ya guardada?**
- a) Sí, sin límite.
- b) Sí, solo hasta cierto plazo después de la clase. ¿Cuál?
- c) No; una vez guardada no se cambia.

**3. ¿Se puede tomar asistencia de una clase que todavía no ha ocurrido (fecha futura)?**
- a) No.
- b) Sí.

**4. ¿Los alumnos retirados o dados de baja deben aparecer en la lista de asistencia?**
- a) No, solo los activos.
- b) Sí, pero marcados como retirados y sin poder marcarlos.
- c) Sí, como cualquier alumno.

**5. Cuando el instructor vuelve a abrir una clase que ya registró, ¿qué debe ver?**
- a) Las marcas que guardó, para revisarlas o corregirlas.
- b) La lista vacía otra vez.

**6. Si el instructor marcó alumnos y sale de la pantalla sin guardar, ¿qué debe pasar?**
- a) Preguntarle si quiere salir sin guardar.
- b) Salir sin preguntar (se pierden las marcas).
- c) Guardar automáticamente.

**7. En la lista de cursos de una categoría, ¿quién puede abrir el detalle de un curso (sus grupos)?**
- a) Solo el coordinador, como hoy.
- b) El coordinador y los instructores.
- c) Todos, incluidos los alumnos (solo para consultar).

*Hoy solo el coordinador puede abrirlo. Para los demás la tarjeta reacciona al toque pero no pasa nada, lo que parece un error. Si se mantiene así, haremos que la tarjeta no parezca tocable.*

---

| Pregunta | Hallazgo del diagnóstico que resuelve |
|---|---|
| 1 | AS-01 (caso del instructor de otro grupo) |
| 2 y 3 | AS-13 |
| 4 | AS-11 |
| 5 | Contrato con el backend, pregunta 6 |
| 6 | AS-10 |
| 7 | O-01 |
