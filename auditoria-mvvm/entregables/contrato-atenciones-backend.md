# Contrato propuesto: endpoints de atenciones (toma de asistencia)

**Para:** equipo del backend · **De:** equipo de la app móvil · **Fecha:** 2026-10-29
**Estado:** propuesta para revisar. Hasta que se acuerde, es lo que la app envía y espera hoy.

## Contexto

La app móvil ya tiene la pantalla de toma de asistencia, pero el backend no publica los endpoints que usa. Revisamos `/v3/api-docs` el 2026-10-28: tiene 33 rutas y ninguna es de atenciones o asistencias. Sí existen `/estadisticas/*`, que agregan atenciones, así que el modelo de datos parece estar en la base de datos.

Los archivos JSON de referencia están en el repositorio de la app, en `test/contratos/atenciones/`. Las pruebas de la app los usan: si el contrato cambia, las pruebas lo detectan.

## Endpoint 1: listar las atenciones de una clase

```
GET /api/v2/atencionesporclase?categoria={titulo}&curso={nombre}&anio={anio}&iterable={iterable}&claseid={codigo}
```

Los valores de `categoria` y `curso` van codificados en la URL (`Fútbol%20%26%20Voleibol`). La app no los codificaba (bug AS-04, que se corrige en la app).

**Respuesta 200** (`listar_200.json`): todos los alumnos del grupo, con su marca para esa clase.

```json
[
  {
    "alumno": {
      "eliminadoestado": 0,
      "id": "1061001",
      "codigo": "104619011001",
      "tipo": "Estudiante",
      "nombre": "Ana Gomez",
      "correo": "anagomez@unicauca.edu.co",
      "sexo": "F",
      "tipoid": "CC",
      "imagen": 12
    },
    "idClase": 210,
    "estaAtendido": false
  }
]
```

- Grupo sin alumnos: `200 []` (`listar_vacia.json`).
- Campos obligatorios para la app: `alumno.id`, `tipo`, `nombre`, `correo`, `sexo`, `tipoid`, más `idClase` (entero) y `estaAtendido` (booleano, **nunca nulo**). Un `null` en `estaAtendido` hoy hace fallar la app (bug AS-06, que también se corrige en la app).

## Endpoint 2: registrar las atenciones de una clase

```
POST /api/v2/atenciones?idclase={codigo}
Content-Type: application/json
```

**Cuerpo** (`registrar_peticion.json`): la lista completa de la clase con el estado final de cada alumno, con la misma forma que el GET.

**Respuesta de éxito:** hoy la app solo acepta `200` sin cuerpo. Con `201` o `204` mostraba error aunque se hubiera guardado (bug AS-07, que se corrige en la app para aceptar cualquier 2xx). Necesitamos saber cuál van a usar.

## Preguntas abiertas

| # | Pregunta | Por qué importa | Hallazgo relacionado |
|---|---|---|---|
| 1 | ¿Qué código responde el POST cuando sale bien: 200, 201 o 204? ¿Con cuerpo? | Hasta que la app se corrija, cualquier código distinto de 200 se muestra como error | AS-07 |
| 2 | Un segundo POST de la misma clase, ¿**reemplaza** las marcas o **agrega** registros? | La app tenía un doble envío (AS-02). Si el POST agrega, cada reintento duplica la asistencia y las estadísticas | AS-02 |
| 3 | ¿El POST guarda o actualiza el **alumno anidado**, o solo usa `alumno.id`? | La app enviaba el alumno con `codigo` e `imagen` nulos y `eliminadoestado: 0`. Si el backend lo guarda, borra datos y reactiva alumnos retirados | AS-05 |
| 4 | Clase inexistente, alumno que no pertenece al grupo, o `idClase` del cuerpo distinto de `?idclase=`: ¿qué código responde? | Para mostrar un mensaje útil y no un error genérico | AS-08 |
| 5 | ¿El GET incluye alumnos **retirados** (`eliminadoestado: 1`)? | Depende también de una regla del cliente; necesitamos saber qué llega | AS-11 |
| 6 | ¿El GET de una clase ya registrada devuelve las marcas guardadas? | Al volver a abrir una clase, el instructor debe ver lo que registró | — |

## Cambios del lado de la app que no requieren nada del backend

Ya identificados y en cola de corrección:
- codificar `categoria` y `curso` en la URL (AS-04);
- aceptar cualquier 2xx como éxito (AS-07);
- no perder datos del alumno al reenviarlo (AS-05);
- bloquear el doble envío (AS-02);
- no dejar escapar excepciones si el JSON está incompleto (AS-06).

## Cuando estén los endpoints

Avisar al equipo de la app. Se ejecutarán las pruebas contra el backend real (listar → registrar → volver a abrir → registrar de nuevo → ver la asistencia en estadísticas). Cada diferencia con este contrato se registrará como hallazgo AS-C-xx.
