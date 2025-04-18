class HorarioModelo {
  int? id;
  String categoria;
  String curso;
  int anio;
  int iterable;
  String dia;
  String horaInicio;
  String horaFin;
  String escenario;

  HorarioModelo({
    this.id,
    required this.categoria,
    required this.curso,
    required this.anio,
    required this.iterable,
    required this.dia,
    required this.horaInicio,
    required this.horaFin,
    required this.escenario,
  });

  factory HorarioModelo.fromJson(dynamic json) {
    return HorarioModelo(
      categoria: json['categoria'],
      curso: json['curso'],
      anio: json['anio'],
      iterable: json['iterable'],
      dia: json['dia'],
      horaInicio: json['horaInicio'],
      horaFin: json['horaFin'],
      escenario: json['escenario'],
    );
  }
}
