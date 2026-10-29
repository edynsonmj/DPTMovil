import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/periodoInscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

class Gruporepositorio {
  Conexiongrupos conexion;
  Gruporepositorio({required this.conexion});

  String urlImagen(int idImagen) => conexion.urlImagen(idImagen);

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

  Future<RespuestaModelo> insertarGrupo(Grupoentidad entidad) async {
    GrupoModelo modeloPeticion = GrupoModelo.fromEntidad(entidad);
    RespuestaModelo respuesta = await conexion.insertarGrupo(modeloPeticion);
    return respuesta;
  }

  Future<RespuestaModelo> listarGruposNoEliminados() async {
    final RespuestaModelo respuesta = await conexion.obtenerGruposNoEliminados();
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    List<GrupoModelo> listaModelo = respuesta.datos as List<GrupoModelo>;
    respuesta.datos =
        listaModelo.map((item) => Grupoentidad.fromModelo(item)).toList();
    return respuesta;
  }

  //las fechas viajan como yyyy-MM-dd; una fecha nula no se envia y el
  //backend decide (apertura = hoy, cierre = sin limite)
  Future<RespuestaModelo> abrirInscripciones(
    Grupoentidad grupo, {
    DateTime? apertura,
    DateTime? cierre,
  }) async {
    final RespuestaModelo respuesta = await conexion.abrirInscripciones(
      grupo.categoria,
      grupo.curso,
      grupo.anio,
      grupo.iterable,
      PeriodoInscripcionModelo(
        apertura: apertura == null ? null : FormatDate.fechaACadena(apertura, '-'),
        cierre: cierre == null ? null : FormatDate.fechaACadena(cierre, '-'),
      ),
    );
    return _aEntidad(respuesta);
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
      respuesta.datos = Grupoentidad.fromModelo(respuesta.datos as GrupoModelo);
    }
    return respuesta;
  }
}
