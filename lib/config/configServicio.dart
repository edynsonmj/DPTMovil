import 'package:dpt_movil/config/configApi.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';

class ConfigServicio {
  final String fakeServer =
      "https://41a5c51d-8572-4278-a147-e20426a0169e.mock.pstmn.io";

  static String tipoFabricaServicio = ConexionFabricaAbstracta.SERVICIO_REMOTO;
  static bool servicioFalso = false;
  //solo lo fijan los tests y page1; si nadie lo fija manda ConfigApi
  static String? ip;

  String obtenerBaseApi() {
    if (servicioFalso) {
      return fakeServer;
    }
    if (ip == null || ip!.isEmpty) {
      return ConfigApi.baseUrl;
    }
    return 'http://$ip:8082/api/v2';
  }
}
