import 'package:dio/dio.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';

class RespuestaModelo {
  int codigoHttp;
  dynamic? datos;
  ErrorModelo? error;

  RespuestaModelo({required this.codigoHttp, this.datos, this.error});

  factory RespuestaModelo.fromResponse(
    Response<dynamic> response,
    String metodo,
  ) {
    String url = response.realUri.toString();
    switch (response.statusCode) {
      case null:
        return RespuestaModelo(
          codigoHttp: -1,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 0,
            mensaje: 'La peticion ha fallado antes de completarse',
            url: url,
            metodo: metodo,
          ),
        );
      case 400:
        return RespuestaModelo(
          codigoHttp: 400,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 400,
            mensaje: _textoDe(response),
            url: url,
            metodo: metodo,
          ),
        );
      case 409:
        return RespuestaModelo(
          codigoHttp: 409,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 409,
            mensaje: _textoDe(response),
            url: url,
            metodo: metodo,
          ),
        );
      case 500:
        return RespuestaModelo(
          codigoHttp: 500,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 500,
            mensaje: _textoDe(response),
            url: url,
            metodo: metodo,
          ),
        );
      case 204:
        return RespuestaModelo(
          codigoHttp: 204,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 204,
            mensaje:
                response.statusMessage ??
                'La informacion buscada no fue encontrada o esta vacio el registro',
            url: url,
            metodo: metodo,
          ),
        );
      default:
        return RespuestaModelo(
          codigoHttp: response.statusCode ?? -1,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 0,
            mensaje: _textoDe(response),
            url: url,
            metodo: metodo,
          ),
        );
    }
  }
  //el cuerpo de una respuesta no siempre es texto: un 2xx inesperado suele
  //traer un Map, que como mensaje lanzaba un TypeError (CAT-07, BK-08)
  static String _textoDe(Response<dynamic> response) {
    final datos = response.data;
    return datos is String
        ? datos
        : 'Respuesta inesperada del servidor. Código: ${response.statusCode}';
  }

  //el motivo de un rechazo para mostrarlo tal cual: el `mensaje` del backend, no
  //el JSON entero (IN-16). Un 400 por campo sigue como JSON: DialogError lista
  //cada campo. Sin cuerpo, como el 401 y el 403, se explica por el codigo (IN-17)
  static String _motivoDe(Response<dynamic>? response) {
    final cuerpo = response?.data;
    if (cuerpo is Map) {
      final mensaje = cuerpo['mensaje'];
      if (mensaje is String && mensaje.trim().isNotEmpty) return mensaje;
    }
    if (cuerpo != null && response.toString().trim().isNotEmpty) {
      return response.toString();
    }
    switch (response?.statusCode) {
      case 401:
        return 'Tu sesión no está activa. Inicia sesión de nuevo.';
      case 403:
        return 'No tienes permiso para realizar esta acción.';
      default:
        return 'El servidor no dio más detalle. Código: ${response?.statusCode}';
    }
  }

  factory RespuestaModelo.fromDioException(
    DioException excepcion,
    String metodo,
  ) {
    String url = excepcion.requestOptions.uri.toString();
    switch (excepcion.type) {
      case DioExceptionType.connectionError:
        return RespuestaModelo(
          codigoHttp: 503,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 503,
            mensaje: 'No hay conexion a internet',
            url: url,
            metodo: metodo,
          ),
        );
      case DioExceptionType.connectionTimeout:
        return RespuestaModelo(
          codigoHttp: 408,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 408,
            mensaje: 'La conexion a agotado el tiempo de espera',
            url: url,
            metodo: metodo,
          ),
        );
      case DioExceptionType.sendTimeout:
        return RespuestaModelo(
          codigoHttp: 408,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 408,
            mensaje: 'La conexion a agotado el tiempo de espera',
            url: url,
            metodo: metodo,
          ),
        );
      case DioExceptionType.badCertificate:
        return RespuestaModelo(
          codigoHttp: 495,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 495,
            mensaje: 'Error de certificado SSL',
            url: url,
            metodo: metodo,
          ),
        );
      case DioExceptionType.badResponse:
        return RespuestaModelo(
          codigoHttp: excepcion.response?.statusCode ?? 500,
          datos: null,
          error: ErrorModelo(
            codigoHttp: excepcion.response?.statusCode ?? 500,
            mensaje: _motivoDe(excepcion.response),
            url: url,
            metodo: metodo,
          ),
        );
      default:
        return RespuestaModelo(
          codigoHttp: excepcion.response?.statusCode ?? 0,
          datos: null,
          error: ErrorModelo(
            codigoHttp: excepcion.response?.statusCode ?? 0,
            mensaje: '${excepcion.message}',
            url: url,
            metodo: metodo,
          ),
        );
    }
  }
  factory RespuestaModelo.fromFormatException(
    FormatException exception,
    String metodo,
    String url,
    String capa,
  ) {
    return RespuestaModelo(
      codigoHttp: 0,
      error: ErrorModelo(
        codigoHttp: 0,
        mensaje: 'imposible parsear en $capa: ${exception.message}',
        url: url,
        metodo: metodo,
      ),
    );
  }

  factory RespuestaModelo.fromException(
    Exception exception,
    String metodo,
    String url,
    String capa,
  ) {
    return RespuestaModelo(
      codigoHttp: 0,
      error: ErrorModelo(
        codigoHttp: 0,
        mensaje: 'excepcion $capa: ${exception.toString()}',
        url: url,
        metodo: metodo,
      ),
    );
  }

  factory RespuestaModelo.fromObjectError(
    Object error,
    String metodo,
    String url,
    String capa,
  ) {
    return RespuestaModelo(
      codigoHttp: 0,
      error: ErrorModelo(
        codigoHttp: 0,
        mensaje: 'en $capa error no controlado: ${error.toString()}',
        url: url,
        metodo: metodo,
      ),
    );
  }
}
