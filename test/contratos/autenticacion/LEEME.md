# Contrato documentado: autenticación

**Estado: documentado, no observado.** Forma tomada de `PerfilDto` en `/v3/api-docs` (2026-11-05). No se pudo observar la respuesta real: desde el 2026-11-05 el backend local responde `401` (`WWW-Authenticate: Bearer`, cuerpo vacío) a toda ruta, `/login` incluida, si la petición no lleva un JWT (ver AU-B01 en `auditoria-mvvm/registro-bugs.md`). Plan: `auditoria-mvvm/plan-diagnostico-autenticacion.md`.

| Archivo | Ruta | Origen |
|---|---|---|
| `login_200.json` | `GET /login?email=` → 200 | `PerfilDto` documentado; los valores son de prueba |
| `registro_peticion.json` | `POST /RegistroPerfilAlumno` (cuerpo) | Lo que envía `Perfilmodelo.toJson` para el formulario de registro |
| `registro_201.json` | `POST /RegistroPerfilAlumno` → 201 | `PerfilDto` documentado. **Por confirmar:** si la respuesta trae `role` |
| `token_200.json` / `token_200_alumno.json` | `POST /auth/token` → 200 | `TokenResponseDto` documentado (`{token, perfil}`); el token es de prueba, no un JWT real |

`PerfilDto` marca como obligatorios `correo`, `id`, `nombre`, `sexo`, `tipoAlumno` y `tipoId`, y trae tres campos que la app no lee: `alumnoCodigo`, `programa` y `dependencia`. `/login` documenta `200` y `404` "Perfil no encontrado"; `/RegistroPerfilAlumno` documenta `201`, `400` y `409` "El perfil ya existe".

Desde el 2026-11-05 la app usa `POST /auth/token` (cabecera `Authorization` con el Google ID Token) → `200 {token, perfil}`, `401` token inválido, `404` correo no registrado.
