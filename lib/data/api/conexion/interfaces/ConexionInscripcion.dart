import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexioninscripcion {
  Future<RespuestaModelo> agregarInscripcion(Inscripcionmodelo inscripcion);
  Future<RespuestaModelo> validarInscripcion(Inscripcionmodelo inscripcion);
  Future<RespuestaModelo> eliminarInscripcion(Inscripcionmodelo inscripcion);
}
