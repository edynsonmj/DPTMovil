import 'package:dpt_movil/data/api/conexion/interfaces/ConexionClases.dart';
import 'package:dpt_movil/data/mappers/claseMapper.dart';
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
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'DELETE',
        'Clase',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> agregarClase(Claseentidad entidad) async {
    try {
      Clasemodelo modelo = ClaseMapper.aModelo(entidad);
      final RespuestaModelo respuesta = await cliente.agregarClaseGrupo(modelo);
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'POST',
        'agregarClaseGrupo',
        'Repositorio',
      );
    } catch (error) {
      return RespuestaModelo.fromObjectError(
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
    try {
      final RespuestaModelo respuesta = await cliente.obtenerClasesGrupo(
        categoria,
        curso,
        anio,
        iterable,
      );
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      List<Clasemodelo> listaModelo = respuesta.datos as List<Clasemodelo>;
      respuesta.datos = listaModelo.map(ClaseMapper.aEntidad).toList();
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'ObtenerClasesGrupo',
        'Repositorio',
      );
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'ObtenerClasesGrupo',
        'repositorio',
      );
    }
  }
}
