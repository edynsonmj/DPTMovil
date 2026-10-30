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
  //si se fija, los tres metodos lanzan esto en vez de responder: la conexion
  //real solo captura Exception, asi que un TypeError (fromJson incompleto o
  //imagenFile! nulo) sale hacia el repositorio
  Object? lanzar;

  @override
  Future<RespuestaModelo> enconcontrarCursosDe(String tituloCategoria) async {
    llamadasCursosDe++;
    ultimaCategoria = tituloCategoria;
    if (lanzar != null) throw lanzar!;
    return respuestaCursosDe;
  }

  @override
  Future<RespuestaModelo> agregarCurso(CursoModelo curso) async {
    llamadasAgregar++;
    ultimoAgregado = curso;
    if (lanzar != null) throw lanzar!;
    return respuestaAgregar;
  }

  @override
  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) async {
    llamadasObtener++;
    ultimaCategoria = categoria;
    ultimoCurso = curso;
    if (lanzar != null) throw lanzar!;
    return respuestaObtener;
  }

  @override
  String urlImagen(int idImagen) =>
      'http://falso/imagenStream?idImagen=$idImagen';

  //sin uso en la app
  @override
  Future<RespuestaModelo> eliminarCurso(CursoModelo curso) async =>
      RespuestaModelo(codigoHttp: 200);
}
