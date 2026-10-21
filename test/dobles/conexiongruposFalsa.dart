import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

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

  @override
  Future<RespuestaModelo> obtenerGruposDe(
    String categoriaTitulo,
    String nombreCurso,
  ) async {
    llamadasGruposDe++;
    ultimaCategoria = categoriaTitulo;
    ultimoCurso = nombreCurso;
    return respuestaGruposDe;
  }

  @override
  Future<RespuestaModelo> obtenerGruposInscripcionDisponible() async =>
      respuestaInscripcion;

  @override
  Future<RespuestaModelo> obtenerGruposInstructor(String idInstructor) async {
    ultimoInstructor = idInstructor;
    return respuestaInstructor;
  }

  @override
  Future<RespuestaModelo> insertarGrupo(GrupoModelo grupo) async {
    llamadasInsertar++;
    ultimoInsertado = grupo;
    return respuestaInsertar;
  }
}
