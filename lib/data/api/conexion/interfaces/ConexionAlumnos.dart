import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionalumnos {
  Future<RespuestaModelo> obtenerAlumnosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );
}
