import 'package:dpt_movil/data/api/conexion/interfaces/ConexionFacultades.dart';
import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de facultades: el test fija la respuesta
class ConexionfacultadesFalsa implements Conexionfacultades {
  RespuestaModelo respuestaListar = RespuestaModelo(
    codigoHttp: 200,
    datos: <Facultadmodelo>[],
  );
  int llamadasListar = 0;

  @override
  Future<RespuestaModelo> obtenerFacultades() async {
    llamadasListar++;
    return respuestaListar;
  }
}
