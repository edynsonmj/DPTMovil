import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class ConexionEstadisticas{
  Future<RespuestaModelo> generalCategorias();
  Future<RespuestaModelo> generalCursos(String categoria);
  Future<RespuestaModelo> generalGrupos(String categoria, String curso);
  Future<RespuestaModelo> institucionalFacultades();
  Future<RespuestaModelo> institucionalProgramas(String facultad);
}