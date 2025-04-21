import 'package:dpt_movil/data/api/conexion/ConexionClases.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';

class Claserepositorio {
  Conexionclases cliente;
  Claserepositorio({required this.cliente});

  Future<RespuestaModelo> eliminarClase(int id) async {
    try {
      final RespuestaModelo respuesta = await cliente.eliminarClase(id);
      return respuesta;
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'DELETE',
        'Clase',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> agregarClase(Claseentidad entidad) async {
    try {
      Clasemodelo modelo = Clasemodelo.fromEntidad(entidad);
      final RespuestaModelo respuesta = await cliente.agregarClaseGrupo(modelo);
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'POST',
        'agregarClaseGrupo',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'POST',
        'AgregarClaseGrupo',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> listarClaseGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    final RespuestaModelo respuesta = await cliente.obtenerClasesGrupo(
      categoria,
      curso,
      anio,
      iterable,
    );
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    try {
      List<Clasemodelo> listaModelo = respuesta.datos as List<Clasemodelo>;
      List<Claseentidad> listaEntidad = [];
      for (Clasemodelo item in listaModelo) {
        Claseentidad entidad = Claseentidad.fromModelo(item);
        listaEntidad.add(entidad);
      }
      respuesta.datos = listaEntidad;
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'ObtenerClasesGrupo',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'GET',
        'ObtenerClasesGrupo',
        'repositorio',
      );
    }
  }
}
