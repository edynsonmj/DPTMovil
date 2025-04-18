import 'package:dpt_movil/data/models/horarioModelo.dart';

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

  factory Horarioentidad.fromModelo(HorarioModelo modelo) {
    return Horarioentidad(
      categoria: modelo.categoria,
      curso: modelo.curso,
      anio: modelo.anio,
      iterable: modelo.iterable,
      dia: modelo.dia,
      horaInicio: modelo.horaInicio,
      horaFin: modelo.horaFin,
      escenario: modelo.escenario,
    );
  }
}
