import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionClases.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionclasesremoto implements Conexionclases {
  //el Dio compartido llega desde la raiz de composicion, con la baseUrl
  final Dio _dio;

  Conexionclasesremoto(this._dio);

  @override
  Future<RespuestaModelo> obtenerClasesGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    String metodo = "GET";
    String path = '/clasesGrupo';
    try {
      final response = await _dio.get(
        path,
        queryParameters: {
          'categoria': categoria,
          'curso': curso,
          'anio': anio,
          'iterable': iterable,
        },
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      if (response.data is! List) {
        return RespuestaModelo(
          codigoHttp: 406,
          datos: response.data,
          error: ErrorModelo(
            codigoHttp: 406,
            mensaje: "se esperaba una lista",
            url: path,
            metodo: metodo,
          ),
        );
      }
      List<dynamic> data = response.data;
      List<Clasemodelo> clases =
          data.map((json) => Clasemodelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: clases);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        path,
        'conexion',
      );
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }

  @override
  Future<RespuestaModelo> agregarClaseGrupo(Clasemodelo modelo) async {
    String metodo = "POST";
    String path = "/claseGrupo";
    try {
      final response = await _dio.post(
        path,
        data: modelo,
        options: Options(contentType: 'application/json'),
      );
      //201: clase nueva. 200: el backend reutilizo la clase que ya existia en
      //esa fecha, no es un error (BK-08). El vm distingue los dos casos
      if (response.statusCode != 201 && response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: response.statusCode!);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        path,
        'conexion',
      );
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }

  @override
  Future<RespuestaModelo> eliminarClase(int id) async {
    String metodo = "delete";
    String path = "/clase?id=$id";
    try {
      final response = await _dio.delete(path);
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
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }
}
