import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

import 'copiaRespuesta.dart';

//doble programable de la conexion de estadisticas: cada test fija la
//respuesta que quiere y despues revisa el rango que llego a la conexion
class ConexionEstadisticasFalsa implements ConexionEstadisticas {
  RespuestaModelo respuestaCategorias = RespuestaModelo(
    codigoHttp: 200,
    datos: <EstadisticaModelo>[],
  );
  RespuestaModelo respuestaCursos = RespuestaModelo(
    codigoHttp: 200,
    datos: <EstadisticaModelo>[],
  );
  RespuestaModelo respuestaGrupos = RespuestaModelo(
    codigoHttp: 200,
    datos: <EstadisticaModelo>[],
  );

  //si se fija, cada peticion la espera antes de responder: permite ver el
  //estado del vm a mitad de carga o hacer llegar tarde un rango anterior
  Future<void> Function(String inicio)? antesDeResponder;

  //rango de la ultima peticion, sea cual sea la seccion
  String? ultimoInicio;
  String? ultimoFin;
  int llamadasCategorias = 0;
  int llamadasCursos = 0;
  int llamadasGrupos = 0;

  Future<RespuestaModelo> _responder(
    String inicio,
    String fin,
    RespuestaModelo Function() respuesta,
  ) async {
    ultimoInicio = inicio;
    ultimoFin = fin;
    await antesDeResponder?.call(inicio);
    //se lee al responder (no al pedir) y se copia: el vm pide varias veces
    //con la misma respuesta
    return copiaRespuesta(respuesta());
  }

  @override
  Future<RespuestaModelo> generalCategorias(
    String fechaInicio,
    String fechafin,
  ) {
    llamadasCategorias++;
    return _responder(fechaInicio, fechafin, () => respuestaCategorias);
  }

  @override
  Future<RespuestaModelo> generalCursos(String fechaInicio, String fechafin) {
    llamadasCursos++;
    return _responder(fechaInicio, fechafin, () => respuestaCursos);
  }

  @override
  Future<RespuestaModelo> generalGrupos(String fechaInicio, String fechafin) {
    llamadasGrupos++;
    return _responder(fechaInicio, fechafin, () => respuestaGrupos);
  }

  //la conexion remota tampoco los implementa
  @override
  Future<RespuestaModelo> institucionalFacultades() {
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> institucionalProgramas(String facultad) {
    throw UnimplementedError();
  }
}
