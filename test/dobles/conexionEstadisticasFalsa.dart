import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

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

  //rango de la ultima peticion, sea cual sea la seccion
  String? ultimoInicio;
  String? ultimoFin;
  int llamadasCategorias = 0;
  int llamadasCursos = 0;
  int llamadasGrupos = 0;

  @override
  Future<RespuestaModelo> generalCategorias(
    String fechaInicio,
    String fechafin,
  ) async {
    llamadasCategorias++;
    ultimoInicio = fechaInicio;
    ultimoFin = fechafin;
    return respuestaCategorias;
  }

  @override
  Future<RespuestaModelo> generalCursos(
    String fechaInicio,
    String fechafin,
  ) async {
    llamadasCursos++;
    ultimoInicio = fechaInicio;
    ultimoFin = fechafin;
    return respuestaCursos;
  }

  @override
  Future<RespuestaModelo> generalGrupos(
    String fechaInicio,
    String fechafin,
  ) async {
    llamadasGrupos++;
    ultimoInicio = fechaInicio;
    ultimoFin = fechafin;
    return respuestaGrupos;
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
