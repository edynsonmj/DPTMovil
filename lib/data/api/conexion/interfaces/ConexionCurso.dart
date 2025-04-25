import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class ConexionCurso {
  Future<List<CursoModelo>> obtenerCursos();
  Future<RespuestaModelo> encontrarTodosCursos();
  Future<RespuestaModelo> enconcontrarCursosDe(String tituloCategoria);
  Future<RespuestaModelo> eliminarCurso(CursoModelo curso);
  Future<RespuestaModelo> agregarCurso(CursoModelo curso);
  Future<RespuestaModelo> obtenerCurso(String categoria, String curso);
}
