import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionfacultades {
  Future<RespuestaModelo> obtenerFacultades();

  //programas academicos de una facultad (publico, lo usa el registro)
  Future<RespuestaModelo> obtenerProgramas(String facultad);
}
