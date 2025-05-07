import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexioninstructores {
  Future<RespuestaModelo> obtenerInstructores();
}
