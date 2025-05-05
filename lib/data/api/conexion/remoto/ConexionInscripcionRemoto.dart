import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionInscripcion.dart';
import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexioninscripcionremoto implements Conexioninscripcion {
  final _dio = Dio(
    BaseOptions(
      baseUrl: ConfigServicio().obtenerBaseApi(),
      connectTimeout: Duration(minutes: 10),
      receiveTimeout: Duration(minutes: 10),
      sendTimeout: Duration(minutes: 10),
    ),
  );
  @override
  Future<RespuestaModelo> agregarInscripcion(Inscripcionmodelo modelo) async {
    String metodo = "POST";
    String path = "/inscripcion";
    try {
      final response = await _dio.post(
        path,
        data: modelo,
        options: Options(contentType: 'application/json'),
      );
      if (response.statusCode != 201) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: 201);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        path,
        'conexion',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(error, metodo, path, 'conexion');
    }
  }

  @override
  Future<RespuestaModelo> validarInscripcion(Inscripcionmodelo modelo) async {
    String metodo = "GET";
    String path = "/validarInscripcion";
    String capa = "Conexion";
    try {
      final response = await _dio.get(
        path,
        data: modelo,
        options: Options(contentType: 'application/json'),
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: 200, datos: response.data as bool);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        path,
        capa,
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(error, metodo, path, 'conexion');
    }
  }

  @override
  Future<RespuestaModelo> eliminarInscripcion(Inscripcionmodelo modelo) async {
    String metodo = "POST";
    String path = "/desvincularInscripcion";
    try {
      final response = await _dio.put(
        path,
        data: modelo,
        options: Options(contentType: 'application/json'),
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: 200);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        path,
        'conexion',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(error, metodo, path, 'conexion');
    }
  }
}
