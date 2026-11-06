import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';

//una inscripcion activa del alumno, con su estado
class Inscripcionresumenentidad {
  String categoria;
  String curso;
  int anio;
  int iterable;
  String estado;

  Inscripcionresumenentidad({
    required this.categoria,
    required this.curso,
    required this.anio,
    required this.iterable,
    required this.estado,
  });

  bool get enEspera => estado == Inscripcionentidad.estadoEnEspera;
}
