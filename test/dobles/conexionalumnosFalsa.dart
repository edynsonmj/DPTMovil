import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAlumnos.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de alumnos: el test fija la respuesta
class ConexionalumnosFalsa implements Conexionalumnos {
  RespuestaModelo respuestaAlumnos = RespuestaModelo(
    codigoHttp: 200,
    datos: <Alumnomodelo>[],
  );

  //grupo pedido, como "categoria/curso/anio/iterable"
  String? ultimoGrupo;
  int llamadasAlumnos = 0;

  @override
  Future<RespuestaModelo> obtenerAlumnosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    llamadasAlumnos++;
    ultimoGrupo = '$categoria/$curso/$anio/$iterable';
    return respuestaAlumnos;
  }
}
