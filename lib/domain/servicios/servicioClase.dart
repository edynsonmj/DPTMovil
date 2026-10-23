import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';

class Servicioclase {
  Claserepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  Servicioclase(this.repositorio);

  Future<RespuestaModelo> eliminarClase(int id) async {
    return repositorio.eliminarClase(id);
  }

  Future<RespuestaModelo> guardarClaseGrupo(Claseentidad entidad) async {
    return repositorio.agregarClase(entidad);
  }

  Future<RespuestaModelo> listarClasesGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    return repositorio.listarClaseGrupo(categoria, curso, anio, iterable);
  }
}
