# Plan de diagnóstico: módulo 6b, Horarios (crear, editar y eliminar)

Fecha: 2026-11-04 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md). Módulo anterior de horarios (solo lectura): [plan-diagnostico-horarios.md](plan-diagnostico-horarios.md).

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios.

## 1. Alcance

El 2026-10-29 el backend solo permitía leer horarios (H-07 del módulo 6). Ahora `/v3/api-docs` publica también la escritura:

| Ruta | Datos | Respuestas documentadas |
|---|---|---|
| `POST /horario?categoria&curso&anio&iterable` | `DatosHorarioDto` | 201 con el `id` · 400 · 404 grupo inexistente |
| `PUT /horario?id=` | `DatosHorarioDto` | 200 · 400 · 404 inexistente o eliminado |
| `DELETE /horario?id=` | — | 200 con el horario marcado · 404 inexistente o ya eliminado |

`DatosHorarioDto` = `{dia, horaInicio, horaFin, escenario}`, los cuatro obligatorios; horas `HH:mm` o `HH:mm:ss`.

La app, leída antes de probar: `Conexionhorarios`, `Horariorepositorio` y `Serviciohorario` solo listan. En la pantalla del grupo (`widgetListaHorarios.dart`), "AGREGAR HORARIO" tiene `onPressed: () {}` y el botón de cerrar de cada tarjeta (`MiniTarjeta.iconoAccion`) solo hace `print('hola')`. No hay formulario ni ruta para horarios.

Fuera de alcance: quién puede gestionar horarios (roles, aplazado al final por decisión del 2026-10-29).

## 2. Observado a mano contra el backend (2026-11-04)

Sobre un grupo `prueba_*` de la BD de pruebas:

- `POST` válido → `201` con el horario completo (sin `eliminado`). Acepta `HH:mm` y `HH:mm:ss` y **devuelve la hora tal como se envió**: un grupo puede tener `08:00` y `14:00:00` a la vez.
- `POST` sin `dia` o con `dia: ""` → `400 {"dia": "el dia no puede estar vacio"}`. Hora `8:00` → `400 {"horaInicio": "…formato HH:mm o HH:mm:ss"}`. Fin igual o anterior al inicio → `400 {"rangoHorasValido": "…"}`. Sin cuerpo → `400 {"mensaje", "detalle"}`. Grupo inexistente → `404 GC-0003`.
- `POST` con `dia: "Xyz"` → `201`. Un segundo horario con el mismo día y las mismas horas → `201`.
- `PUT` válido → `200` con los datos nuevos; inválido → el mismo `400`; inexistente o eliminado → `404 GC-0003`.
- `DELETE` → `200` con el horario; `GET /horarios` **ya no lo lista**; un segundo `DELETE` → `404 GC-0003`.
- `GET /horarios` trae `eliminado: 0` en cada horario.

Las respuestas quedan en `test/contratos/horarios/`.

## 3. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| **I-Remota** | La cadena real de lectura (`DetalleGrupoViewModel`, `Horariosviewmodel`) contra el backend, con horarios **sembrados** por `POST`/`PUT`/`DELETE` directos (la app no tiene cómo crearlos) | `test/remoto/viewModel/horario/vmHorarioDiagnosticoTest.dart` (casos nuevos) |
| **I-Local (vista)** | La pantalla del grupo con su VM y dobles, como `grupoView_test.dart`, con un `NavigatorObserver` | `test/diagnostico/horarios/vista_diagnostico_test.dart` (nuevo) |

## 4. Hipótesis

| ID | Capa | Hipótesis | Cómo se verifica |
|---|---|---|---|
| H-08 | Vista | "AGREGAR HORARIO" no abre nada: el coordinador no puede crear horarios desde la app | I-Local (vista): tocar el botón abre una pantalla o un diálogo |
| H-09 | Vista | El botón de cerrar de la tarjeta de un horario no elimina ni pide confirmación | I-Local (vista): tocarlo abre una confirmación |
| H-10 | Backend → app | Un horario creado en el backend no llega completo a la pantalla del grupo ni a las tarjetas (id, día, horas, escenario) | I-Remota |
| H-11 | Backend → app | Un horario editado sigue mostrándose con los datos viejos | I-Remota |
| H-12 | Backend | Un horario eliminado sigue en la lista, como pasa con las clases (CL-01) | I-Remota |
| H-13 | Backend / cliente | El backend acepta un día que no existe (`Xyz`) y dos horarios iguales en el mismo grupo | Observado a mano. La regla (días válidos, solapes) es del cliente: queda como hipótesis |
| H-14 | Backend → vista | Las horas llegan en dos formatos (`08:00` y `14:00:00`) y la tarjeta las pinta tal cual | Observado a mano. Es de presentación; sin prueba |

## 5. Criterio de terminado

- Las pruebas ejecutadas; cada roja con su fila **HO-xx** y su archivo en `test/diagnostico/horarios/`; cada hipótesis confirmada, descartada o sin verificar.
- Los contratos observados en `test/contratos/horarios/` con su `LEEME.md`.
- Las suites normales siguen en verde y `flutter analyze` sin warnings nuevos.
