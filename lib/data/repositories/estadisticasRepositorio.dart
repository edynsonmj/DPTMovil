import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';

class EstadisticasRespositorio {
  ConexionEstadisticas conexion;
  EstadisticasRespositorio({required this.conexion});

  //AGRUPA LAS ATENCIONES Y HORAS POR CATEGORIA
  Future<RespuestaModelo> generalCategorias() async {
    RespuestaModelo respuesta = await conexion.generalCategorias();
    if (respuesta.codigoHttp == 200) {
      //El servidor ha respondido correctamente pero se ha convertido al formato correcto
      if (respuesta.datos is! List<EstadisticaModelo>) {
        respuesta.codigoHttp = 0;
        respuesta.error = ErrorModelo(
          codigoHttp: 0,
          mensaje:
              'El servidor ha respondido correctamente, pero el formato entonctrado no corresponde a una lista de EstadisticaModelo',
          url: '/estadisticasGenerales/categorias',
          metodo: 'GET',
        );
        return respuesta;
      }
      //El servidor ha respondido correctamente, se transforman los datos
      List<EstadisticaModelo> listaModelo =
          respuesta.datos as List<EstadisticaModelo>;
      List<Estadistica> listaEntidad = [];
      for (var item in listaModelo) {
        Estadistica entidad = Estadistica.fromModelo(item);
        listaEntidad.add(entidad);
      }
      respuesta.datos = listaEntidad;
      return respuesta;
    }
    //si el codigo no corresponde, se envia la informacion contenida, esta debe llevar el codigo y la informacion relacionada
    return respuesta;
  }

  //AGRUPA LAS ATENCIONES Y HORAS POR CURSOS SEGUN UNA CATEGORIA DADA
  Future<RespuestaModelo> generalCursos(String categoria) async {
    RespuestaModelo respuesta = await conexion.generalCursos(categoria);
    if (respuesta.codigoHttp == 200) {
      //El servidor ha respondido correctamente pero se ha convertido al formato correcto
      if (respuesta.datos is! List<EstadisticaModelo>) {
        respuesta.codigoHttp = 0;
        respuesta.error = ErrorModelo(
          codigoHttp: 0,
          mensaje:
              'El servidor ha respondido correctamente, pero el formato entonctrado no corresponde a una lista de EstadisticaModelo',
          url: '/estadisticasGenerales/categorias',
          metodo: 'GET',
        );
        return respuesta;
      }
      //El servidor ha respondido correctamente, se transforman los datos
      List<EstadisticaModelo> listaModelo =
          respuesta.datos as List<EstadisticaModelo>;
      List<Estadistica> listaEntidad = [];
      for (var item in listaModelo) {
        Estadistica entidad = Estadistica.fromModelo(item);
        listaEntidad.add(entidad);
      }
      respuesta.datos = listaEntidad;
      return respuesta;
    }
    //si no son los codigos evaluados se retorna la informacion contenida que debe tener la informacion del error
    return respuesta;
  }
}
