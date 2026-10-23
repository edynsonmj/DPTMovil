
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCurso.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class ConexionCursoLocal implements ConexionCurso {
  @override
  Future<RespuestaModelo> agregarCurso(CursoModelo curso) {
    // TODO: implement agregarCurso
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> eliminarCurso(CursoModelo curso) {
    // TODO: implement eliminarCurso
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> enconcontrarCursosDe(String tituloCategoria) {
    // TODO: implement enconcontrarCursosDe
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) {
    // TODO: implement obtenerCurso
    throw UnimplementedError();
  }

  //sin servidor no hay imagenes: la tarjeta cae en su imagen por defecto
  @override
  String urlImagen(int idImagen) => '';
}
