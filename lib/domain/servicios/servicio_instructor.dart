import 'package:dpt_movil/data/api/conexion/remoto/ConexionInstructoresRemoto.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';

class ServicioInstructor {
  final Instructoresrepositorio _repositorio;

  ServicioInstructor()
    : _repositorio = Instructoresrepositorio(
        conexion: Conexioninstructoresremoto(),
      );

  Future<RespuestaModelo> listarInstructores() {
    return _repositorio.listarInstructores();
  }
}
