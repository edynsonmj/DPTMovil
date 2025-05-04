import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionfacultades {
  Future<RespuestaModelo> obtenerFacultades();
}
