//una fila de GET /inscripcion/misCursos. Solo lo que la app usa: el grupo y el
//estado de la inscripcion (INSCRITO o EN_ESPERA)
class Inscripcionresumenmodelo {
  String categoria;
  String curso;
  int anio;
  int iterable;
  String estado;

  Inscripcionresumenmodelo({
    required this.categoria,
    required this.curso,
    required this.anio,
    required this.iterable,
    required this.estado,
  });

  factory Inscripcionresumenmodelo.fromJson(dynamic json) {
    return Inscripcionresumenmodelo(
      categoria: json['categoria'],
      curso: json['curso'],
      anio: json['anio'],
      iterable: json['iterable'],
      estado: json['estado'],
    );
  }
}
