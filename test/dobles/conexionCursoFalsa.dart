import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCurso.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de cursos: cada test fija la respuesta
//que quiere y despues revisa lo que llego a la conexion
class ConexionCursoFalsa implements ConexionCurso {
  //respuesta que devuelve cada metodo; el test la fija antes de actuar
  RespuestaModelo respuestaCursosDe = RespuestaModelo(
    codigoHttp: 200,
    datos: <CursoModelo>[],
  );
  RespuestaModelo respuestaAgregar = RespuestaModelo(codigoHttp: 201);
  RespuestaModelo respuestaObtener = RespuestaModelo(codigoHttp: 200);

  //lo que recibio, para comprobar que el repositorio armo bien la peticion
  CursoModelo? ultimoAgregado;
  String? ultimaCategoria;
  String? ultimoCurso;
  int llamadasCursosDe = 0;
  int llamadasAgregar = 0;
  int llamadasObtener = 0;

  @override
  Future<RespuestaModelo> enconcontrarCursosDe(String tituloCategoria) async {
    llamadasCursosDe++;
    ultimaCategoria = tituloCategoria;
    return respuestaCursosDe;
  }

  @override
  Future<RespuestaModelo> agregarCurso(CursoModelo curso) async {
    llamadasAgregar++;
    ultimoAgregado = curso;
    return respuestaAgregar;
  }

  @override
  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) async {
    llamadasObtener++;
    ultimaCategoria = categoria;
    ultimoCurso = curso;
    return respuestaObtener;
  }

  @override
  String urlImagen(int idImagen) =>
      'http://falso/imagenStream?idImagen=$idImagen';

  //sin uso en la app (la conexion remota no implementa los dos ultimos)
  @override
  Future<List<CursoModelo>> obtenerCursos() async => [];

  @override
  Future<RespuestaModelo> encontrarTodosCursos() async =>
      RespuestaModelo(codigoHttp: 200, datos: <CursoModelo>[]);

  @override
  Future<RespuestaModelo> eliminarCurso(CursoModelo curso) async =>
      RespuestaModelo(codigoHttp: 200);
}
