import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';

//ConexionCursoLocal ya no se crea aqui (fase 3); se borra en la fase 8
class ConexionLocalFabrica implements ConexionFabricaAbstracta {
  @override
  ConexionEstadisticas crearConexionEstadisticas() {
    throw UnimplementedError();
  }

  @override
  Conexionatenciones crearConexionAtenciones() {
    // TODO: implement crearConexionAtenciones
    throw UnimplementedError();
  }
}
