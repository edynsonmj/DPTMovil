import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';

class Servicioclase {
  Claserepositorio repositorio;

  Servicioclase()
    : repositorio = Claserepositorio(
        cliente:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionClases(),
      );

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
