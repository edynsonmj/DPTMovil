import 'package:dpt_movil/data/api/conexion/interfaces/ConexionClases.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de clases: cada test fija la respuesta
//que quiere y despues revisa lo que llego a la conexion
class ConexionclasesFalsa implements Conexionclases {
  RespuestaModelo respuestaClases = RespuestaModelo(
    codigoHttp: 200,
    datos: <Clasemodelo>[],
  );
  RespuestaModelo respuestaAgregar = RespuestaModelo(codigoHttp: 201);
  RespuestaModelo respuestaEliminar = RespuestaModelo(codigoHttp: 200);

  //grupo pedido, como "categoria/curso/anio/iterable"
  String? ultimoGrupo;
  Clasemodelo? ultimaAgregada;
  int? ultimoIdEliminado;
  int llamadasClases = 0;
  int llamadasAgregar = 0;
  int llamadasEliminar = 0;
  //si se fija, los tres metodos lanzan esto en vez de responder: la conexion
  //real solo captura Exception, asi que un TypeError de Clasemodelo.fromJson
  //sale hacia el repositorio
  Object? lanzar;

  @override
  Future<RespuestaModelo> obtenerClasesGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    llamadasClases++;
    ultimoGrupo = '$categoria/$curso/$anio/$iterable';
    if (lanzar != null) throw lanzar!;
    return respuestaClases;
  }

  @override
  Future<RespuestaModelo> agregarClaseGrupo(Clasemodelo modelo) async {
    llamadasAgregar++;
    ultimaAgregada = modelo;
    if (lanzar != null) throw lanzar!;
    return respuestaAgregar;
  }

  @override
  Future<RespuestaModelo> eliminarClase(int id) async {
    llamadasEliminar++;
    ultimoIdEliminado = id;
    if (lanzar != null) throw lanzar!;
    return respuestaEliminar;
  }
}
