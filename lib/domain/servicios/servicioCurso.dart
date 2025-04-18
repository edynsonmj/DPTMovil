import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/presentation/view/views/grupo.dart';

class ServicioCurso {
  CursoRepositorio repositorio;
  ServicioCurso()
    : repositorio = CursoRepositorio(
        cliente:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionCurso(),
      );

  Future<List<CursoEntidad>> call() async {
    return await repositorio.obtenerCursos();
  }

  Future<RespuestaModelo> listarTodosCursos() async {
    return repositorio.listarTodosLosCursos();
  }

  Future<RespuestaModelo> listarCursosDe(CategoriaEntidad categoria) async {
    return await repositorio.listarCursosDe(categoria);
  }

  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) async {
    return await repositorio.obtenerCurso(categoria, curso);
  }
}
