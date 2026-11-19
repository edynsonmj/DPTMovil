import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/mappers/horarioMapper.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';

class Horariorepositorio {
  Conexionhorarios conexion;
  Horariorepositorio({required this.conexion});

  Future<RespuestaModelo> obtenerHoariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    try {
      final RespuestaModelo respuesta = await conexion.obtenerHorariosGrupo(
        categoria,
        curso,
        anio,
        iterable,
      );
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      List<HorarioModelo> listaModelo = respuesta.datos as List<HorarioModelo>;
      respuesta.datos = listaModelo.map(HorarioMapper.aEntidad).toList();
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'ObtenerHoariosGrupo',
        'Repositorio',
      );
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'ObtenerHoariosGrupos',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> agregarHorario(Horarioentidad entidad) async {
    try {
      return await conexion.agregarHorario(HorarioMapper.aModelo(entidad));
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'POST',
        'AgregarHorario',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> eliminarHorario(int id) async {
    try {
      return await conexion.eliminarHorario(id);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'DELETE',
        'EliminarHorario',
        'repositorio',
      );
    }
  }
}
