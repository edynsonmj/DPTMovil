import 'package:dpt_movil/data/models/estadisticaModelo.dart';

class Estadistica{
  String etiqueta;
  double atenciones;
  double horas;
  Estadistica({
    required this.etiqueta,
    required this.atenciones,
    required this.horas
  });

  factory Estadistica.fromModelo(EstadisticaModelo modelo){
    return Estadistica(etiqueta: modelo.etiqueta, atenciones: modelo.atenciones, horas: modelo.horas);
  }
}