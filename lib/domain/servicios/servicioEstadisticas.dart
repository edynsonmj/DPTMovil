import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';

class ServicioEstadisticas {
  EstadisticasRespositorio repositorio;
  ServicioEstadisticas()
    : repositorio = EstadisticasRespositorio(
        conexion:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionEstadisticas(),
      );

  Future<RespuestaModelo> generalesCategorias(
    String fechaInicio,
    String fechaFin,
  ) async {
    return await repositorio.generalCategorias(fechaInicio, fechaFin);
  }

  Future<RespuestaModelo> generalesCursos(fechaInicio, fechaFin) {
    return repositorio.generalCursos(fechaInicio, fechaFin);
  }

  Future<RespuestaModelo> generalesGrupos(
    String fechaInicio,
    String fechaFin,
  ) async {
    return await repositorio.generalGrupos(fechaInicio, fechaFin);
  }
}
