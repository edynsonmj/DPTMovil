import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionclases {
  Future<RespuestaModelo> obtenerClasesGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );
  Future<RespuestaModelo> agregarClaseGrupo(Clasemodelo modelo);
  Future<RespuestaModelo> eliminarClase(int id);
}
