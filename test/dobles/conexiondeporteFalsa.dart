import 'package:dpt_movil/data/api/conexion/interfaces/ConexionDeporte.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de deportes: el test fija la respuesta.
//Como la real, entrega los nombres ya extraidos (List<String>)
class ConexiondeporteFalsa implements Conexiondeporte {
  RespuestaModelo respuestaDeportes = RespuestaModelo(
    codigoHttp: 200,
    datos: <String>[],
  );
  int llamadasDeportes = 0;
  //si se fija, la conexion lanza esto en vez de responder
  Object? lanzar;

  @override
  Future<RespuestaModelo> obtenerDeportes() async {
    llamadasDeportes++;
    if (lanzar != null) throw lanzar!;
    return respuestaDeportes;
  }
}
