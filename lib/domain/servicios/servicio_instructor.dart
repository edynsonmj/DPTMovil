import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';

class ServicioInstructor {
  final Instructoresrepositorio _repositorio;

  //el repositorio llega armado desde la raiz de composicion
  ServicioInstructor(this._repositorio);

  Future<RespuestaModelo> listarInstructores() {
    return _repositorio.listarInstructores();
  }
}
