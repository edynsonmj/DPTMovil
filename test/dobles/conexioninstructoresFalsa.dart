import 'package:dpt_movil/data/api/conexion/interfaces/ConexionInstructores.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de instructores: el test fija la respuesta
class ConexioninstructoresFalsa implements Conexioninstructores {
  RespuestaModelo respuestaInstructores = RespuestaModelo(
    codigoHttp: 200,
    datos: <Instructormodelo>[],
  );
  int llamadasInstructores = 0;

  @override
  Future<RespuestaModelo> obtenerInstructores() async {
    llamadasInstructores++;
    return respuestaInstructores;
  }
}
