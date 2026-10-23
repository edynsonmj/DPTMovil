import 'package:dpt_movil/data/api/conexion/interfaces/ConexionInscripcion.dart';
import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de inscripciones: cada test fija la
//respuesta que quiere y despues revisa lo que llego a la conexion
class ConexioninscripcionFalsa implements Conexioninscripcion {
  RespuestaModelo respuestaAgregar = RespuestaModelo(codigoHttp: 201);
  RespuestaModelo respuestaValidar = RespuestaModelo(
    codigoHttp: 200,
    datos: false,
  );
  RespuestaModelo respuestaEliminar = RespuestaModelo(codigoHttp: 200);

  Inscripcionmodelo? ultimaAgregada;
  Inscripcionmodelo? ultimaValidada;
  //iterable de cada grupo validado, en orden
  final List<int> iterablesValidados = [];
  Inscripcionmodelo? ultimaEliminada;
  int llamadasAgregar = 0;
  int llamadasValidar = 0;
  int llamadasEliminar = 0;

  @override
  Future<RespuestaModelo> agregarInscripcion(
    Inscripcionmodelo inscripcion,
  ) async {
    llamadasAgregar++;
    ultimaAgregada = inscripcion;
    return respuestaAgregar;
  }

  @override
  Future<RespuestaModelo> validarInscripcion(
    Inscripcionmodelo inscripcion,
  ) async {
    llamadasValidar++;
    ultimaValidada = inscripcion;
    iterablesValidados.add(inscripcion.iterable);
    return respuestaValidar;
  }

  @override
  Future<RespuestaModelo> eliminarInscripcion(
    Inscripcionmodelo inscripcion,
  ) async {
    llamadasEliminar++;
    ultimaEliminada = inscripcion;
    return respuestaEliminar;
  }
}
