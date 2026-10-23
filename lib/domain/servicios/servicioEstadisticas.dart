import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';

class ServicioEstadisticas {
  EstadisticasRespositorio repositorio;
  //el repositorio lo arma la raiz de composicion (fase 7)
  ServicioEstadisticas(this.repositorio);

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
