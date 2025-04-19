import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';

class Servicioalumno {
  Alumnosrepositorio repositorio;

  Servicioalumno()
    : repositorio = Alumnosrepositorio(
        cliente:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionAlumnos(),
      );

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
