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

  Map<String, dynamic> toJson() {
    return {
      //un DateTime no se puede codificar en JSON (IN-11)
      'fechaInscripcion': fechaInscripcion?.toIso8601String(),

      'fechaDesvinculacion': fechaDesvinculacion?.toIso8601String(),

      'alumnoId': alumnoId,

      'categoria': categoria,

      'curso': curso,

      'anio': anio,

      'iterable': iterable,

      'eliminado': 0,
    };
  }
}
