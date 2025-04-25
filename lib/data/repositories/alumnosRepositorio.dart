import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';

class Alumnosrepositorio {
  Conexionalumnos cliente;
  Alumnosrepositorio({required this.cliente});

  Future<RespuestaModelo> listarAlumnosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    final RespuestaModelo respuesta = await cliente.obtenerAlumnosGrupo(
      categoria,
      curso,
      anio,
      iterable,
    );
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    try {
      List<Alumnomodelo> listaModelo = respuesta.datos as List<Alumnomodelo>;
      List<Alumnoentidad> listaEntidad = [];
      for (Alumnomodelo item in listaModelo) {
        Alumnoentidad entidad = Alumnoentidad.fromModelo(item);
        listaEntidad.add(entidad);
      }
      respuesta.datos = listaEntidad;
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'ObtenerAlumnosGrupo',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'GET',
        'ObtenerAlumnosGrupo',
        'repositorio',
      );
    }
  }
}
