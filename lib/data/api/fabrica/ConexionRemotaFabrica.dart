import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionEstadisticasRemoto.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';

class ConexionRemotaFabrica implements ConexionFabricaAbstracta {
  @override
  ConexionEstadisticas crearConexionEstadisticas() {
    return Conexionestadisticasremoto();
  }

  @override
  Conexionatenciones crearConexionAtenciones() {
    return Conexionatencionesremoto();
  }
}
