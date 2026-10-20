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
}
