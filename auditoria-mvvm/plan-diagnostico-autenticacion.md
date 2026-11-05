# Plan de diagnóstico: módulo 10, Autenticación

Fecha: 2026-11-05 · Rama: `refactor/inyeccion-dependencias`
Método general: [plan-diagnostico-pruebas.md](plan-diagnostico-pruebas.md). Registro: [registro-bugs.md](registro-bugs.md), sección «Módulo 10».

> **Estado al 2026-11-05: ejecutado sin backend.** 21 escenarios. 14 pruebas en rojo dan 10 hallazgos (AU-01 a AU-10). Una prueba remota confirmó además **AU-B01**: el backend local exige ahora un JWT y responde `401` a todo, incluido `/login`. Por eso la parte contra el backend (I-Remota) no se pudo hacer. CAT-12 / T-04 quedan descartadas.

**Regla:** solo es **hallazgo** lo que demuestra una prueba unitaria o de integración **en rojo**. Lo demás va a **hipótesis**; una hipótesis cuya prueba sale verde queda **descartada**. El registro incluye la lista de escenarios.

## 1. Alcance

```
Menú lateral (Menulateral)                  Pantalla de registro (Autenticacionview)
  "Iniciar sesion" → Google o correo          formulario → registroAlumno
  → AutenticacionViewModel.login               → Servicioautenticacion → Autenticacionrepositorio
  → Servicioautenticacion → Autenticacionrepositorio → Conexionautenticacionremoto
  → GET /login?email=                          → POST /RegistroPerfilAlumno
  200 → sesión · 404 → registro · otro → "Error: <código>"
"Cerrar sesion" → logout → pushNamed(categorias)
```

Fuera de alcance:
- Las reglas de qué ve cada rol en cada pantalla. Siguen en AS-01, AS-01c y O-01, a la espera del cliente. Aquí solo se prueba que las rutas del coordinador no miran el rol (AU-10).
- El inicio con Google de punta a punta: necesita el plugin nativo. Se usa `GoogleSignInFalso`.
- La parte contra el backend: bloqueada por AU-B01.

Contrato (`/v3/api-docs`, 2026-11-05): `GET /login?email` documenta `200 PerfilDto` y `404`. `POST /RegistroPerfilAlumno` documenta `201`, `400` y `409` "El perfil ya existe". `PerfilDto` trae además `alumnoCodigo`, `programa` y `dependencia`. Hay una ruta nueva, `POST /auth/token`, que cambia un Google ID Token por un JWT propio: `200 {token, perfil}`, `401` o `404`. Los fixtures de `test/contratos/autenticacion/` son **documentados, no observados**.

## 2. Niveles

| Nivel | Qué se arma | Archivo |
|---|---|---|
| U-Conexión | `Conexionautenticacionremoto` → `Dio(AdaptadorHttpFalso)` | `test/unitarias/conexion/conexionAutenticacionRemoto_test.dart` (nuevo) |
| U-VM | `AutenticacionViewModel` con dobles | `test/diagnostico/autenticacion/viewModel_diagnostico_test.dart` |
| I-Local | Menú lateral real, rutas reales y la cadena real hasta el transporte falso (montaje `test/integracion/montajeAutenticacion.dart`) | `test/integracion/autenticacion_integracion_test.dart` (nuevo) y `test/diagnostico/autenticacion/vista_diagnostico_test.dart` |
| U-Vista | `CategoriasView` con el VM de sesión sobre el doble (CAT-12 / T-04) | `test/unitarias/vista/categoriasView_test.dart` (+1) |
| I-Remota | La prueba remota que ya existía (`VmLoginTest`) | `test/main_test.dart` |

Las rojas van a `test/diagnostico/autenticacion/` con el prefijo `BUG AU-xx`.

## 3. Hipótesis

| ID | Capa | Hipótesis | Cómo se verifica | Resultado |
|---|---|---|---|---|
| H-01 | Conexión | El correo va sin codificar en `/login?email=`: un `+` llega como espacio y un `&` parte la query (como GR-05) | U-Conexión | ❌ AU-01 |
| H-02 | Modelo | `Perfilmodelo.fromJson` no lee `facultad` | U-Conexión | ❌ AU-02 |
| H-03 | Conexión | Un perfil incompleto, o un 201 sin cuerpo, lanza un `Error` que la conexión no captura | U-Conexión | ❌ AU-03 |
| H-04 | VM | Si `signOut` de Google falla, `logout` lanza y no borra la sesión | U-VM | ❌ AU-04 |
| H-05 | Vista | Al escribir el nombre y elegir otro campo, el campo del nombre se cambia por un texto fijo | I-Local | ❌ AU-05 |
| H-06 | Vista | Un 409 o 400 del registro cierra el formulario sin decir el motivo | I-Local | ❌ AU-06 |
| H-07 | Vista | Dos toques en GUARDAR envían dos registros | I-Local | ❌ AU-07 |
| H-08 | Vista | Un error de login se muestra como `Error: <código>` | I-Local con el 401 que da hoy el backend | ❌ AU-08 |
| H-09 | Vista / navegación | Cerrar sesión deja debajo las pantallas del rol anterior | I-Local | ❌ AU-09 |
| H-10 | Rutas | Las rutas del coordinador no comprueban el rol | I-Local con control | ❌ AU-10 |
| H-11 | VM | `perfilSesion` cambia sin notificar y la vista no se entera (CAT-12 / T-04) | U-Vista e I-Local | ✅ descartada |
| H-12 | Backend | El backend publicado sigue aceptando `/login` sin credenciales | I-Remota | ❌ AU-B01 (`401`) |

## 4. Criterio de terminado

- Cada roja con su fila **AU-xx** y su archivo en `test/diagnostico/autenticacion/`. Cada hipótesis confirmada, descartada o sin verificar.
- La lista de escenarios queda en el registro.
- La suite sin backend sigue en verde y `flutter analyze` no suma warnings.
