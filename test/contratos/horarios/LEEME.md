# Contrato propuesto: horarios

**Estado: propuesto, no observado.** El backend (2026-10-29) publica solo `GET /horarios?categoria=&curso=&anio=&iterable=` y la BD de pruebas no tiene ningún horario en sus 124 grupos, así que no hay respuestas reales que capturar. `horarios_200.json` sigue el esquema `HorarioEntidad` de `/v3/api-docs`: `id`, `categoria`, `curso`, `anio`, `iterable`, `dia`, `horaInicio`, `horaFin`, `escenario` y `eliminado`. El formato de las horas (`HH:mm`) es una suposición.

Observado: un grupo sin horarios responde `200 []`. Plan: `auditoria-mvvm/plan-diagnostico-horarios.md`.
