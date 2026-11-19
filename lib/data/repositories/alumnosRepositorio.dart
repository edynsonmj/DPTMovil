import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/mappers/alumnoMapper.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Alumnosrepositorio {
  Conexionalumnos cliente;
  Alumnosrepositorio({required this.cliente});

  Future<RespuestaModelo> listarAlumnosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    //la llamada va dentro del try: nada que lance la conexion atraviesa esta
    //capa (AL-02)
    try {
      final RespuestaModelo respuesta = await cliente.obtenerAlumnosGrupo(
        categoria,
        curso,
        anio,
        iterable,
      );
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      List<Alumnomodelo> listaModelo = respuesta.datos as List<Alumnomodelo>;
      respuesta.datos = listaModelo.map(AlumnoMapper.aEntidad).toList();
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'ObtenerAlumnosGrupo',
        'Repositorio',
      );
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'ObtenerAlumnosGrupo',
        'repositorio',
      );
    }
  }
}
