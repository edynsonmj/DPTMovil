import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';

class Inscripcionmodelo {
  DateTime? fechaInscripcion;

  DateTime? fechaDesvinculacion;

  String alumnoId;

  String categoria;

  String curso;

  int anio;

  int iterable;

  Inscripcionmodelo({
    this.fechaInscripcion,
    this.fechaDesvinculacion,
    required this.alumnoId,
    required this.categoria,
    required this.curso,
    required this.anio,
    required this.iterable,
  });

  factory Inscripcionmodelo.fromJson(dynamic json) {
    return Inscripcionmodelo(
      alumnoId: json['alumnoId'],
      categoria: json['categoria'],
      curso: json['curso'],
      anio: json['anio'],
      iterable: json['iterable'],
      fechaInscripcion: json['fechaInscripcion'],
      fechaDesvinculacion: json['fechaDesvinculacion'],
    );
  }

  factory Inscripcionmodelo.fromEntidad(Inscripcionentidad entidad) {
    return Inscripcionmodelo(
      alumnoId: entidad.alumnoId,
      categoria: entidad.categoria,
      curso: entidad.curso,
      anio: entidad.anio,
      iterable: entidad.iterable,
      fechaInscripcion: entidad.fechaInscripcion,
      fechaDesvinculacion: entidad.fechaDesvinculacion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fechaInscripcion': fechaInscripcion,

      'fechaDesvinculacion': fechaDesvinculacion,

      'alumnoId': alumnoId,

      'categoria': categoria,

      'curso': curso,

      'anio': anio,

      'iterable': iterable,

      'eliminado': 0,
    };
  }
}
