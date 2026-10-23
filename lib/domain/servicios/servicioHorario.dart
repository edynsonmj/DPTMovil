import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';

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
}
