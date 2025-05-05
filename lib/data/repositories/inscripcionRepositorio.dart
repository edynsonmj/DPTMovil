import 'package:dpt_movil/data/api/conexion/interfaces/ConexionInscripcion.dart';
import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';

class Inscripcionrepositorio {
  Conexioninscripcion conexion;
  Inscripcionrepositorio({required this.conexion});

  Future<RespuestaModelo> agregarInscripcion(
    Inscripcionentidad inscripcion,
  ) async {
    try {
      Inscripcionmodelo modelo = Inscripcionmodelo.fromEntidad(inscripcion);
      RespuestaModelo respuesta = await conexion.agregarInscripcion(modelo);
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'POST',
        'AgregarInscripcion',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'POST',
        'AgregarInscripcion',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> eliminarInscripcion(
    Inscripcionentidad inscripcion,
  ) async {
    try {
      Inscripcionmodelo modelo = Inscripcionmodelo.fromEntidad(inscripcion);
      RespuestaModelo respuesta = await conexion.eliminarInscripcion(modelo);
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'PUT',
        'EliminarInscripcion',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'PUT',
        'EliminarInscripcion',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> validarInscripcion(Inscripcionentidad entidad) async {
    try {
      Inscripcionmodelo modelo = Inscripcionmodelo.fromEntidad(entidad);
      RespuestaModelo respuesta = await conexion.validarInscripcion(modelo);
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'validarInscripcion',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'GET',
        'ValidarInscripcion',
        'repositorio',
      );
    }
  }
}
