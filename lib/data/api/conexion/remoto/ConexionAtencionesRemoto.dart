import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//GET y POST /asistenciasClase?idClase= (publicados en /v3/api-docs el
//2026-10-29). El backend solo usa el codigo de la clase: categoria, curso,
//anio e iterable ya no viajan
class Conexionatencionesremoto implements Conexionatenciones {
  //el Dio compartido llega desde la raiz de composicion, con la baseUrl
  final Dio _dio;

  Conexionatencionesremoto(this._dio);

  @override
  Future<RespuestaModelo> obtenerAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int claseid,
  ) async {
    String metodo = "GET";
    String path = '/asistenciasClase';
    try {
      final response = await _dio.get(
        path,
        queryParameters: {'idClase': claseid},
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
      List<Atencionmodelo> atenciones =
          data.map((json) => Atencionmodelo.fromJson(json, claseid)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: atenciones);
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
  Future<RespuestaModelo> registrarAtencionesClase(
    List<Atencionmodelo> atenciones,
    int idClase,
  ) async {
    String metodo = "POST";
    String path = '/asistenciasClase';
    try {
      //responde 200 con el resumen {idClase, registradas, eliminadas,
      //sinCambios}; la app solo necesita saber que se guardo
      final response = await _dio.post(
        path,
        queryParameters: {'idClase': idClase},
        data: atenciones.map((atencion) => atencion.toJson()).toList(),
        options: Options(headers: {'Content-Type': 'application/json'}),
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
