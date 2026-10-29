# Contrato propuesto: atenciones (toma de asistencia)

**Estado: propuesta, pendiente de validar con el equipo del backend.**

El 2026-10-28 el backend no publica ningún endpoint de atenciones. Su lista de rutas en `/v3/api-docs` tiene 33 rutas y ninguna es de atenciones o asistencias. Estos archivos escriben lo que la app espera hoy, según `Conexionatencionesremoto` y `Atencionmodelo`/`Alumnomodelo`, para que la forma de los datos no viva escondida en un doble.

Cuando el backend implemente los endpoints:
- se compara su respuesta real con estos archivos;
- cada diferencia (ruta, nombre de campo, código de éxito) se registra como hallazgo **AS-C-xx** en `auditoria-mvvm/registro-bugs.md`.

## Endpoints

| Método | Ruta (sobre `/api/v2`) | Respuesta esperada |
|---|---|---|
| GET | `/atencionesporclase?categoria=&curso=&anio=&iterable=&claseid=` | `200` con `listar_200.json`; clase sin alumnos: `200` con `listar_vacia.json` |
| POST | `/atenciones?idclase=` | Cuerpo: `registrar_peticion.json`. Código de éxito **por acordar**: la app solo acepta `200` (hipótesis AS-07) |

## Archivos

- `listar_200.json`: tres alumnos de la clase 210. Incluye `codigo` e `imagen` para detectar si la app los pierde (AS-05), y un alumno ya marcado.
- `listar_vacia.json`: clase sin alumnos.
- `registrar_peticion.json`: lo que la app debe enviar después de cargar `listar_200.json` y marcar el alumno de índice 1 (Luis Perez). Cada alumno va completo, tal como llegó.

## Preguntas abiertas para el backend

1. ¿Código de éxito del POST: 200, 201 o 204?
2. ¿Qué pasa con un segundo POST de la misma clase: reemplaza o duplica?
3. ¿El POST guarda el alumno anidado o solo su `id`?
4. Clase inexistente o alumno no inscrito en el grupo: ¿qué código responde?
5. ¿El GET incluye alumnos retirados (`eliminadoestado: 1`)?
