import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/deporteRepositorio.dart';

class Serviciodeporte {
  Deporterepositorio repositorio;
  Serviciodeporte()
    : repositorio = Deporterepositorio(
        cliente:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionDeporte(),
      );

  Future<RespuestaModelo> obtenerDeportes() async {
    return await repositorio.obtenerDeportes();
  }
}
