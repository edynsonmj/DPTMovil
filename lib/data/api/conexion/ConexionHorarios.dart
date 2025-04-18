import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionhorarios {
  Future<RespuestaModelo> obtenerHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );
}
