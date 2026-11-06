class Inscripcionentidad {
  //estado que da el backend a una inscripcion en un grupo sin cupos
  static const String estadoEnEspera = 'EN_ESPERA';

  DateTime? fechaInscripcion;

  DateTime? fechaDesvinculacion;

  String alumnoId;

  String categoria;

  String curso;

  int anio;

  int iterable;

  Inscripcionentidad({
    this.fechaInscripcion,
    this.fechaDesvinculacion,
    required this.alumnoId,
    required this.categoria,
    required this.curso,
    required this.anio,
    required this.iterable,
  });
}
