import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class ConexionEstadisticas {
  Future<RespuestaModelo> generalCategorias(
    String fechaInicio,
    String fechafin,
  );
  Future<RespuestaModelo> generalCursos(String fechaInicio, String fechafin);
  Future<RespuestaModelo> generalGrupos(String fechaInicio, String fechafin);
  Future<RespuestaModelo> institucionalFacultades();
  Future<RespuestaModelo> institucionalProgramas(String facultad);
}
