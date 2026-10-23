import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';

class Servicioalumno {
  Alumnosrepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  Servicioalumno(this.repositorio);

  Future<RespuestaModelo> listarAlumnosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    return await repositorio.listarAlumnosGrupo(
      categoria,
      curso,
      anio,
      iterable,
    );
  }
}
