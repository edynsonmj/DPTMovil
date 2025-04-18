import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';

class Serviciohorario {
  Horariorepositorio repositorio;
  Serviciohorario()
    : repositorio = Horariorepositorio(
        conexion:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionHorarios(),
      );

  Future<RespuestaModelo> listarHoariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) {
    return repositorio.obtenerHoariosGrupo(categoria, curso, anio, iterable);
  }
}
