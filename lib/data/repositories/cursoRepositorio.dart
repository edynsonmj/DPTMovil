import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCurso.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';

class CursoRepositorio {
  ConexionCurso cliente;
  CursoRepositorio({required this.cliente});

  String urlImagen(int idImagen) => cliente.urlImagen(idImagen);

  Future<RespuestaModelo> listarCursosDe(CategoriaEntidad categoria) async {
    RespuestaModelo respuesta = await cliente.enconcontrarCursosDe(
      categoria.titulo,
    );

    if (respuesta.codigoHttp == 200) {
      List<CursoModelo> listaModelo = respuesta.datos as List<CursoModelo>;
      List<CursoEntidad> listaEntidad = [];
      for (var item in listaModelo) {
        print('>>> cargarImagen llamada con id: ${item.imagen}');
        CursoEntidad entidad = CursoEntidad.fromModelo(item);
        listaEntidad.add(entidad);
      }
      respuesta.datos = listaEntidad;
      return respuesta;
    }
    return respuesta;
  }

  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) async {
    RespuestaModelo respuesta = await cliente.obtenerCurso(categoria, curso);
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    CursoEntidad entidad = CursoEntidad.fromModelo(respuesta.datos);
    respuesta.datos = entidad;
    return respuesta;
  }

  Future<RespuestaModelo> guardaCurso(CursoEntidad entidad) async {
    CursoModelo modeloPeticion = CursoModelo.fromEntidad(entidad);
    RespuestaModelo respuesta = await cliente.agregarCurso(modeloPeticion);
    if (respuesta.codigoHttp == 201) {
      CursoEntidad entidadRespuesta = CursoEntidad.fromModelo(
        respuesta.datos as CursoModelo,
      );
      respuesta.datos = entidadRespuesta;
    }
    return respuesta;
  }
}
