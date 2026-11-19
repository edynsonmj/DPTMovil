import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/mappers/grupoMapper.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/periodoInscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

class Gruporepositorio {
  Conexiongrupos conexion;
  Gruporepositorio({required this.conexion});

  String urlImagen(int idImagen) => conexion.urlImagen(idImagen);

  Future<RespuestaModelo> listarGruposDe(String categoria, String curso) async {
    try {
      final RespuestaModelo respuesta = await conexion.obtenerGruposDe(
        categoria,
        curso,
      );
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      respuesta.datos = GrupoMapper.aEntidades(
        respuesta.datos as List<GrupoModelo>,
      );
      return respuesta;
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'obtenerGruposDe',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> listarGruposDisponiblesInscripcion() async {
    try {
      final RespuestaModelo respuesta =
          await conexion.obtenerGruposInscripcionDisponible();
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      respuesta.datos = GrupoMapper.aEntidades(
        respuesta.datos as List<GrupoModelo>,
      );
      return respuesta;
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'obtenerGruposInscripcionDisponible',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> listarGruposInstructores(String idInstructor) async {
    try {
      final RespuestaModelo respuesta = await conexion.obtenerGruposInstructor(
        idInstructor,
      );
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      respuesta.datos = GrupoMapper.aEntidades(
        respuesta.datos as List<GrupoModelo>,
      );
      return respuesta;
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'obtenerGruposInstructor',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> insertarGrupo(Grupoentidad entidad) async {
    GrupoModelo modeloPeticion = GrupoMapper.aModelo(entidad);
    RespuestaModelo respuesta = await conexion.insertarGrupo(modeloPeticion);
    return respuesta;
  }

  Future<RespuestaModelo> listarGruposNoEliminados() async {
    try {
      final RespuestaModelo respuesta =
          await conexion.obtenerGruposNoEliminados();
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      respuesta.datos = GrupoMapper.aEntidades(
        respuesta.datos as List<GrupoModelo>,
      );
      return respuesta;
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'obtenerGruposNoEliminados',
        'repositorio',
      );
    }
  }

  //las fechas viajan como yyyy-MM-dd; sin apertura el grupo conserva la suya.
  //El periodo no reabre un grupo cerrado a mano, y quitar ese cierre exige
  //que la fecha ya sea vigente: por eso primero el periodo
  Future<RespuestaModelo> abrirInscripciones(
    Grupoentidad grupo, {
    DateTime? apertura,
    required DateTime cierre,
  }) async {
    final RespuestaModelo respuesta = await conexion.abrirInscripciones(
      grupo.categoria,
      grupo.curso,
      grupo.anio,
      grupo.iterable,
      PeriodoInscripcionModelo(
        apertura:
            apertura == null ? null : FormatDate.fechaACadena(apertura, '-'),
        cierre: FormatDate.fechaACadena(cierre, '-'),
      ),
    );
    if (respuesta.codigoHttp != 200 || !grupo.inscripcionesCerradasManual) {
      return _aEntidad(respuesta);
    }
    return _aEntidad(
      await conexion.reabrirInscripciones(
        grupo.categoria,
        grupo.curso,
        grupo.anio,
        grupo.iterable,
      ),
    );
  }

  Future<RespuestaModelo> cerrarInscripciones(Grupoentidad grupo) async {
    final RespuestaModelo respuesta = await conexion.cerrarInscripciones(
      grupo.categoria,
      grupo.curso,
      grupo.anio,
      grupo.iterable,
    );
    return _aEntidad(respuesta);
  }

  //abrir y cerrar responden el grupo actualizado: sale como entidad
  RespuestaModelo _aEntidad(RespuestaModelo respuesta) {
    if (respuesta.codigoHttp == 200 && respuesta.datos is GrupoModelo) {
      respuesta.datos = GrupoMapper.aEntidad(respuesta.datos as GrupoModelo);
    }
    return respuesta;
  }
}
