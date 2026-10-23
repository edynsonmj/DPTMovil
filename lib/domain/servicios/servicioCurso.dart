import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';

class ServicioCurso {
  CursoRepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  //(lib/config/inyeccion/dependencias.dart)
  ServicioCurso(this.repositorio);

  Future<RespuestaModelo> listarCursosDe(CategoriaEntidad categoria) async {
    return await repositorio.listarCursosDe(categoria);
  }

  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) async {
    return await repositorio.obtenerCurso(categoria, curso);
  }

  Future<RespuestaModelo> insertarCurso(CursoEntidad entidad) async {
    return await repositorio.guardaCurso(entidad);
  }

  String urlImagen(int idImagen) => repositorio.urlImagen(idImagen);
}
