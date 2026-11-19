import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/mappers/estadisticaMapper.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class EstadisticasRespositorio {
  ConexionEstadisticas conexion;
  EstadisticasRespositorio({required this.conexion});

  //AGRUPA LAS ATENCIONES Y HORAS POR CATEGORIA
  Future<RespuestaModelo> generalCategorias(String fechaInicio, String fechaFin) {
    return _consultar(
      () => conexion.generalCategorias(fechaInicio, fechaFin),
      '/estadisticas/categorias',
    );
  }

  //AGRUPA LAS ATENCIONES Y HORAS POR CURSOS
  Future<RespuestaModelo> generalCursos(String fechaInicio, String fechaFin) {
    return _consultar(
      () => conexion.generalCursos(fechaInicio, fechaFin),
      '/estadisticas/cursos',
    );
  }

  Future<RespuestaModelo> generalGrupos(String fechaInicio, String fechaFin) {
    return _consultar(
      () => conexion.generalGrupos(fechaInicio, fechaFin),
      '/estadisticas/grupos',
    );
  }

  //las tres rutas se convierten igual. Cualquier error de la conexion o de la
  //conversion se devuelve, no se lanza (ES-01); un codigo distinto de 200 pasa
  //tal cual porque ya lleva el error
  Future<RespuestaModelo> _consultar(
    Future<RespuestaModelo> Function() llamada,
    String url,
  ) async {
    try {
      final RespuestaModelo respuesta = await llamada();
      if (respuesta.codigoHttp != 200) return respuesta;
      //el servidor respondio bien pero la conexion no entrego la lista esperada
      if (respuesta.datos is! List<EstadisticaModelo>) {
        respuesta.codigoHttp = 0;
        respuesta.error = ErrorModelo(
          codigoHttp: 0,
          mensaje:
              'El servidor ha respondido correctamente, pero el formato entonctrado no corresponde a una lista de EstadisticaModelo',
          url: url,
          metodo: 'GET',
        );
        return respuesta;
      }
      respuesta.datos = EstadisticaMapper.aEntidades(
        respuesta.datos as List<EstadisticaModelo>,
      );
      return respuesta;
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, 'GET', url, 'repositorio');
    }
  }
}
