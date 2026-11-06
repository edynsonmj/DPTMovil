# Contrato observado: programas

**Estado: observado.** Respuestas del backend local del 2026-11-05 (`GET /programas?facultad=`, público: lo usa el registro antes de tener JWT).

| Archivo | Ruta | Origen |
|---|---|---|
| `programas_200.json` | `GET /programas?facultad=Facultad de Artes` | Respuesta real completa: lista `[{nombre, facultad}]` |
| `programas_200_vacio.json` | `GET /programas?facultad=Facultad de Ingeniería Civil` | Facultad sin programas: **200 con un objeto `GC-0002`**, no `[]`. La conexión lo convierte en lista vacía |

Sin el parámetro `facultad` el backend responde 400.

**Codificación:** el backend local devuelve los nombres con doble codificación (`Artes PlÃ¡sticas`, `Facultad de IngenierÃ­a Civil`), también en `/facultades`: los datos se cargaron en la BD sin `--default-character-set=utf8mb4`. Los contratos guardan el texto bien escrito (`Artes Plásticas`). La app envía de vuelta el nombre tal como lo recibió, así que la validación del registro sigue coincidiendo con la BD.
