import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart';

//peticion tal como salio por la red: la uri completa (con la query que arma
//la conexion) y el cuerpo ya decodificado del json que se envio
class PeticionRegistrada {
  final String metodo;
  final Uri uri;
  final dynamic cuerpo;

  PeticionRegistrada(this.metodo, this.uri, this.cuerpo);

  //ruta sin la base, como la escribe la conexion: '/atenciones'
  String get ruta => uri.path.substring(AdaptadorHttpFalso._basePath.length);

  @override
  String toString() => '$metodo $uri ${cuerpo ?? ''}';
}

//doble del transporte de Dio: debajo de la conexion remota real, asi se
//prueba su codigo (armado de urls, codigos, fromJson, excepciones) sin
//backend. Programable como los demas dobles: el test fija que responde cada
//ruta antes de actuar y despues revisa las peticiones que salieron
class AdaptadorHttpFalso implements HttpClientAdapter {
  static const String baseUrl = 'http://falso/api/v2';
  static final String _basePath = Uri.parse(baseUrl).path;

  final Map<String, ({int codigo, dynamic cuerpo})> _respuestas = {};
  final Map<String, DioExceptionType> _fallos = {};
  final Map<String, Completer<void>> _retenidas = {};

  final List<PeticionRegistrada> peticiones = [];

  //la clave usa la ruta sin query: la query la arma la conexion y es justo
  //lo que se quiere revisar despues en peticiones
  String _clave(String metodo, String ruta) => '${metodo.toUpperCase()} $ruta';

  //cuerpo: Map o List se envian como json; un String como texto plano, que
  //es como el backend manda varios mensajes de error
  void responder(String metodo, String ruta, int codigo, [dynamic cuerpo]) {
    _respuestas[_clave(metodo, ruta)] = (codigo: codigo, cuerpo: cuerpo);
  }

  //la ruta falla antes de obtener respuesta: sin red, timeout, ...
  void fallar(String metodo, String ruta, DioExceptionType tipo) {
    _fallos[_clave(metodo, ruta)] = tipo;
  }

  //la respuesta no sale hasta completar el Completer: para revisar el
  //estado a mitad de peticion o mandar dos peticiones a la vez
  Completer<void> retener(String metodo, String ruta) {
    return _retenidas[_clave(metodo, ruta)] = Completer<void>();
  }

  List<PeticionRegistrada> peticionesA(String metodo, String ruta) =>
      peticiones
          .where((p) => p.metodo == metodo.toUpperCase() && p.ruta == ruta)
          .toList();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final metodo = options.method.toUpperCase();
    final peticion = PeticionRegistrada(
      metodo,
      options.uri,
      await _leerCuerpo(requestStream),
    );
    peticiones.add(peticion);
    final clave = _clave(metodo, peticion.ruta);

    await _retenidas[clave]?.future;

    final fallo = _fallos[clave];
    if (fallo != null) {
      throw DioException(
        requestOptions: options,
        type: fallo,
        message: 'fallo programado en el adaptador falso',
      );
    }

    final respuesta = _respuestas[clave];
    if (respuesta == null) {
      //una ruta sin programar se ve en el error del test, no pasa callada
      return ResponseBody.fromString(
        'ruta no programada en AdaptadorHttpFalso: $clave',
        404,
        headers: {
          Headers.contentTypeHeader: ['text/plain'],
        },
      );
    }
    final cuerpo = respuesta.cuerpo;
    final esTexto = cuerpo is String;
    return ResponseBody.fromString(
      cuerpo == null ? '' : (esTexto ? cuerpo : jsonEncode(cuerpo)),
      respuesta.codigo,
      headers: {
        Headers.contentTypeHeader: [
          esTexto ? 'text/plain' : Headers.jsonContentType,
        ],
      },
    );
  }

  Future<dynamic> _leerCuerpo(Stream<Uint8List>? requestStream) async {
    if (requestStream == null) return null;
    final bytes = await requestStream.expand((trozo) => trozo).toList();
    if (bytes.isEmpty) return null;
    final texto = utf8.decode(bytes);
    try {
      return jsonDecode(texto);
    } on FormatException {
      return texto;
    }
  }

  @override
  void close({bool force = false}) {}
}

//mismo Dio que la raiz de composicion (timeouts incluidos), con el
//transporte cambiado por el adaptador
Dio crearDioFalso(AdaptadorHttpFalso adaptador) =>
    crearClienteHttp(AdaptadorHttpFalso.baseUrl)..httpClientAdapter = adaptador;
