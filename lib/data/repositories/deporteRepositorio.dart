import 'package:dpt_movil/data/api/conexion/interfaces/ConexionDeporte.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Deporterepositorio {
  Conexiondeporte cliente;
  Deporterepositorio({required this.cliente});

  Future<RespuestaModelo> obtenerDeportes() async {
    return await cliente.obtenerDeportes();
  }
}
