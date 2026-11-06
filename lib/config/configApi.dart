import 'package:dio/dio.dart';

//fuente unica de la direccion del backend. Se fija al compilar:
//flutter run --dart-define=API_HOST=192.168.1.20
//sin el parametro usa 10.0.2.2, el alias del pc en el emulador de android
class ConfigApi {
  static const String host = String.fromEnvironment(
    'API_HOST',
    defaultValue: '10.0.2.2',
  );
  static const int puerto = 8082;
  static const String baseUrl = 'http://$host:$puerto/api/v2';

  //client ID web de Google Cloud (mismo proyecto que el cliente Android de
  //co.edu.unicauca.dpt_movil). Sin el, Android no entrega el ID Token que
  //pide POST /auth/token. No es secreto; se cambia con
  //--dart-define=GOOGLE_SERVER_CLIENT_ID=...
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue:
        '612503201417-n3nfshmljq67fssjfrm2o3p9g040avsi.apps.googleusercontent.com',
  );
}

//cliente http que comparten las conexiones migradas. La raiz lo crea con
//ConfigApi.baseUrl; los tests remotos le pasan la direccion de pruebas.
//Los 20 s son los que ya usaba la conexion de categorias; la de imagenes
//pide 30 s en cada peticion
Dio crearClienteHttp([String baseUrl = ConfigApi.baseUrl]) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 20),
    ),
  );
}
