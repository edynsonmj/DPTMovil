import 'package:dpt_movil/data/models/inscripcionModelo.dart';

class Inscripcionentidad {
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

  factory Inscripcionentidad.fromModelo(Inscripcionmodelo modelo) {
    return Inscripcionentidad(
      alumnoId: modelo.alumnoId,
      categoria: modelo.categoria,
      curso: modelo.curso,
      anio: modelo.anio,
      iterable: modelo.iterable,
      fechaInscripcion: modelo.fechaInscripcion,
      fechaDesvinculacion: modelo.fechaDesvinculacion,
    );
  }
}
