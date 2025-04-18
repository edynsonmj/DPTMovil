import 'package:dpt_movil/data/api/conexion/ConexionHorarios.dart';
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
    final RespuestaModelo respuesta = await conexion.obtenerHorariosGrupo(
      categoria,
      curso,
      anio,
      iterable,
    );
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    try {
      List<HorarioModelo> listaModelo = respuesta.datos as List<HorarioModelo>;
      List<Horarioentidad> listEntidad = [];
      for (HorarioModelo item in listaModelo) {
        Horarioentidad entidad = Horarioentidad.fromModelo(item);
        listEntidad.add(entidad);
      }
      respuesta.datos = listEntidad;
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'ObtenerHoariosGrupo',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'GET',
        'ObtenerHoariosGrupos',
        'repositorio',
      );
    }
  }
}
