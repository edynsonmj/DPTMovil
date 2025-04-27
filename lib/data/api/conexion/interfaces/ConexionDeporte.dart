import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexiondeporte {
  Future<RespuestaModelo> obtenerDeportes();
}
