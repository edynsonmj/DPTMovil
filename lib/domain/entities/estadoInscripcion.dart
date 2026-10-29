//estado de las inscripciones de un grupo segun su periodo (apertura y
//cierre). Lo calcula Grupoentidad.estadoInscripcion con la regla que aplica
//el backend en GET /gruposInscripcion
enum EstadoInscripcion {
  //apertura <= hoy y (sin cierre o cierre >= hoy): el alumno puede inscribirse
  abierta,
  //apertura en el futuro: se abrira sola ese dia
  programada,
  //el cierre ya paso
  cerrada,
  //nunca se abrio (sin fecha de apertura)
  sinPeriodo,
}
