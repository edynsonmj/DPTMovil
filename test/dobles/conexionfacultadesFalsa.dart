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
  //si se fija, la conexion lanza esto en vez de responder: la real solo
  //captura Exception, asi que un TypeError de Facultadmodelo.fromJson sale
  //hacia el repositorio
  Object? lanzar;

  @override
  Future<RespuestaModelo> obtenerFacultades() async {
    llamadasListar++;
    if (lanzar != null) throw lanzar!;
    return respuestaListar;
  }
}
