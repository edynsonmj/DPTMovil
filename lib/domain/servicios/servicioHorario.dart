import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';

class Serviciohorario {
  Horariorepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  Serviciohorario(this.repositorio);

  Future<RespuestaModelo> listarHoariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) {
    return repositorio.obtenerHoariosGrupo(categoria, curso, anio, iterable);
  }

  Future<RespuestaModelo> agregarHorario(Horarioentidad horario) {
    return repositorio.agregarHorario(horario);
  }

  Future<RespuestaModelo> eliminarHorario(int id) {
    return repositorio.eliminarHorario(id);
  }
}
