import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionclases {
  Future<RespuestaModelo> obtenerClasesGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );
}
