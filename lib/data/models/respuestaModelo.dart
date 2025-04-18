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
            mensaje: response.data,
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
            mensaje: response.data,
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
            mensaje: response.data,
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
            mensaje: response.data,
            url: url,
            metodo: metodo,
          ),
        );
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
            mensaje: excepcion.response.toString(),
            url: url,
            metodo: metodo,
          ),
        );
      default:
        return RespuestaModelo(
          codigoHttp: 0,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 0,
            mensaje: 'Error desconocido: ${excepcion.message}',
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
}
