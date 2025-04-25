import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionalumnoslocal implements Conexionalumnos {
  @override
  Future<RespuestaModelo> obtenerAlumnosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) {
    // TODO: implement obtenerAlumnosGrupo
    throw UnimplementedError();
  }
}
