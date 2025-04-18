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

  Future<RespuestaModelo> generalesCategorias() async {
    return await repositorio.generalCategorias();
  }

  Future<RespuestaModelo> generalesGrupos(String categoria) async {
    return await repositorio.generalCursos(categoria);
  }
}
