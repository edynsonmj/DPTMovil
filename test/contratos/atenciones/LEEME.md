# Contrato: atenciones (toma de asistencia)

**Estado: observado.** Hasta el 2026-10-28 esta carpeta era una propuesta: el backend no tenía endpoints de asistencia. El 2026-10-29 el backend publicó `/asistenciasClase` en `/v3/api-docs` (tag *Asistencias*) con una forma distinta a la propuesta. Los archivos se reescribieron con esa forma, comprobada contra el backend local (`GET /asistenciasClase?idClase=207` y una clase inexistente).

## Endpoints

| Método | Ruta (sobre `/api/v2`) | Respuesta |
|---|---|---|
| GET | `/asistenciasClase?idClase=` | `200` con `listar_200.json` (lista de `AsistenciaAlumnoDto`: `{alumno, asistio}`); grupo sin alumnos: `200` con `listar_vacia.json`; clase inexistente: `404` `GC-0003` |
| POST | `/asistenciasClase?idClase=` | Cuerpo: `registrar_peticion.json` (lista de `RegistroAsistenciaDto`: `{idPerfil, asistio}`). `200` con `registrar_200.json` (`ResultadoAsistenciaDto`). `400` cuerpo vacío o inválido, `404` clase inexistente, `424` algún alumno no pertenece al grupo de la clase (no se aplica ningún cambio) |

Según la descripción del endpoint, el POST **sincroniza**: inserta las marcadas que no existían, elimina las desmarcadas que existían y no toca a los alumnos que no se envían. Por eso un segundo POST con el mismo cuerpo no debería duplicar (no comprobado todavía contra el backend).

## Archivos

- `listar_200.json`: tres alumnos de la clase 210, uno ya marcado. Incluye `codigo` e `imagen` del alumno.
- `listar_vacia.json`: grupo sin alumnos.
- `registrar_peticion.json`: lo que la app debe enviar después de cargar `listar_200.json` y marcar el alumno de índice 1 (Luis Perez).
- `registrar_200.json`: resumen de cambios que responde el POST.

## Diferencias con la propuesta anterior

| Propuesta | Backend real |
|---|---|
| `GET /atencionesporclase?categoria=&curso=&anio=&iterable=&claseid=` | `GET /asistenciasClase?idClase=` |
| `POST /atenciones?idclase=` | `POST /asistenciasClase?idClase=` |
| Elemento `{alumno, idClase, estaAtendido}` | Elemento `{alumno, asistio}` (la clase no se repite) |
| POST con el alumno completo | POST con `{idPerfil, asistio}` |

`Atencionmodelo` conserva `idClase` para la app: la conexión lo toma de la petición.

## Preguntas abiertas para el backend

1. ¿El GET incluye alumnos retirados (`eliminadoestado: 1`)? (AS-11)
