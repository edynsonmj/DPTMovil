import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

class Gruporepositorio {
  Conexiongrupos conexion;
  Gruporepositorio({required this.conexion});

  Future<RespuestaModelo> listarGruposDe(String categoria, String curso) async {
    final RespuestaModelo respuesta = await conexion.obtenerGruposDe(
      categoria,
      curso,
    );
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    List<GrupoModelo> listaModelo = respuesta.datos as List<GrupoModelo>;
    List<Grupoentidad> listEntidad = [];
    for (GrupoModelo item in listaModelo) {
      Grupoentidad entidad = Grupoentidad.fromModelo(item);
      listEntidad.add(entidad);
    }
    respuesta.datos = listEntidad;
    return respuesta;
  }

  Future<RespuestaModelo> listarGruposDisponiblesInscripcion() async {
    final RespuestaModelo respuesta =
        await conexion.obtenerGruposInscripcionDisponible();
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    List<GrupoModelo> listaModelo = respuesta.datos as List<GrupoModelo>;
    List<Grupoentidad> listEntidad = [];
    for (GrupoModelo item in listaModelo) {
      Grupoentidad entidad = Grupoentidad.fromModelo(item);
      listEntidad.add(entidad);
    }
    respuesta.datos = listEntidad;
    return respuesta;
  }

  Future<RespuestaModelo> listarGruposInstructores(String idInstructor) async {
    final RespuestaModelo respuesta = await conexion.obtenerGruposInstructor(
      idInstructor,
    );
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    List<GrupoModelo> listaModelo = respuesta.datos as List<GrupoModelo>;
    List<Grupoentidad> listEntidad = [];
    for (GrupoModelo item in listaModelo) {
      Grupoentidad entidad = Grupoentidad.fromModelo(item);
      listEntidad.add(entidad);
    }
    respuesta.datos = listEntidad;
    return respuesta;
  }
}
