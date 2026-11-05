class Horarioentidad {
  int? id;
  String categoria;
  String curso;
  int anio;
  int iterable;
  String dia;
  String horaInicio;
  String horaFin;
  String escenario;

  Horarioentidad({
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
}
