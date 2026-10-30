import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/periodoInscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

import 'copiaRespuesta.dart';

//doble programable de la conexion de grupos: cada test fija la respuesta
//que quiere y despues revisa lo que llego a la conexion
class ConexiongruposFalsa implements Conexiongrupos {
  RespuestaModelo respuestaGruposDe = RespuestaModelo(
    codigoHttp: 200,
    datos: <GrupoModelo>[],
  );
  RespuestaModelo respuestaInscripcion = RespuestaModelo(
    codigoHttp: 200,
    datos: <GrupoModelo>[],
  );
  RespuestaModelo respuestaInstructor = RespuestaModelo(
    codigoHttp: 200,
    datos: <GrupoModelo>[],
  );
  RespuestaModelo respuestaInsertar = RespuestaModelo(codigoHttp: 201);

  GrupoModelo? ultimoInsertado;
  String? ultimaCategoria;
  String? ultimoCurso;
  String? ultimoInstructor;
  int llamadasGruposDe = 0;
  int llamadasInsertar = 0;
  //si se fija, las tres listas (por curso, inscripcion e instructor) lanzan
  //esto en vez de responder: la conexion real solo captura Exception en
  //ellas, asi que un TypeError de GrupoModelo.fromJson sale hacia el
  //repositorio
  Object? lanzarAlListar;

  @override
  Future<RespuestaModelo> obtenerGruposDe(
    String categoriaTitulo,
    String nombreCurso,
  ) async {
    llamadasGruposDe++;
    ultimaCategoria = categoriaTitulo;
    ultimoCurso = nombreCurso;
    if (lanzarAlListar != null) throw lanzarAlListar!;
    return copiaRespuesta(respuestaGruposDe);
  }

  @override
  Future<RespuestaModelo> obtenerGruposInscripcionDisponible() async {
    if (lanzarAlListar != null) throw lanzarAlListar!;
    return copiaRespuesta(respuestaInscripcion);
  }

  @override
  Future<RespuestaModelo> obtenerGruposInstructor(String idInstructor) async {
    ultimoInstructor = idInstructor;
    if (lanzarAlListar != null) throw lanzarAlListar!;
    return copiaRespuesta(respuestaInstructor);
  }

  @override
  String urlImagen(int idImagen) =>
      'http://falso/imagenStream?idImagen=$idImagen';

  @override
  Future<RespuestaModelo> insertarGrupo(GrupoModelo grupo) async {
    llamadasInsertar++;
    ultimoInsertado = grupo;
    return respuestaInsertar;
  }

  //periodo de inscripcion (plan de abrir inscripciones)
  RespuestaModelo respuestaNoEliminados = RespuestaModelo(
    codigoHttp: 200,
    datos: <GrupoModelo>[],
  );
  //abrir y cerrar devuelven el grupo actualizado, como el backend
  RespuestaModelo respuestaAbrir = RespuestaModelo(codigoHttp: 200);
  RespuestaModelo respuestaCerrar = RespuestaModelo(codigoHttp: 200);

  //grupo pedido, como "categoria/curso/anio/iterable"
  String? ultimoGrupoAbierto;
  String? ultimoGrupoCerrado;
  PeriodoInscripcionModelo? ultimoPeriodo;
  int llamadasNoEliminados = 0;
  int llamadasAbrir = 0;
  int llamadasCerrar = 0;

  @override
  Future<RespuestaModelo> obtenerGruposNoEliminados() async {
    llamadasNoEliminados++;
    return copiaRespuesta(respuestaNoEliminados);
  }

  @override
  Future<RespuestaModelo> abrirInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
    PeriodoInscripcionModelo periodo,
  ) async {
    llamadasAbrir++;
    ultimoGrupoAbierto = '$categoria/$curso/$anio/$iterable';
    ultimoPeriodo = periodo;
    return respuestaAbrir;
  }

  @override
  Future<RespuestaModelo> cerrarInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    llamadasCerrar++;
    ultimoGrupoCerrado = '$categoria/$curso/$anio/$iterable';
    return respuestaCerrar;
  }
}
