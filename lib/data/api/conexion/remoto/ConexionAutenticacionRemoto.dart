import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAutenticacion.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionautenticacionremoto implements Conexionautenticacion {
  final _dio = Dio(
    BaseOptions(
      baseUrl: ConfigServicio().obtenerBaseApi(),
      connectTimeout: Duration(minutes: 1),
      receiveTimeout: Duration(minutes: 1),
      sendTimeout: Duration(minutes: 1),
    ),
  );
  @override
  Future<RespuestaModelo> login(String email) async {
    String metodo = "GET";
    String path = "/login?email=$email";
    try {
      final response = await _dio.get(path);
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      Perfilmodelo perfil = Perfilmodelo.fromJson(response.data);
      return RespuestaModelo(codigoHttp: 200, datos: perfil);
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
  Future<RespuestaModelo> registro(Perfilmodelo modelo) async {
    String metodo = "POST";
    String path = "/RegistroPerfilAlumno";
    String capa = "Conexion";
    try {
      final response = await _dio.post(
        path,
        data: modelo,
        options: Options(contentType: ContentType.json.toString()),
      );
      if (response.statusCode != 201) {
        RespuestaModelo.fromResponse(response, metodo);
      }
      Perfilmodelo respuesta = Perfilmodelo.fromJson(response.data);
      return RespuestaModelo(
        codigoHttp: response.statusCode!,
        datos: respuesta,
      );
    } on DioException catch (dioExc) {
      //Se ha generado un error en la peticion, generar respuesta segun tipo de excepcion
      return RespuestaModelo.fromDioException(dioExc, metodo);
    } on FormatException catch (exception) {
      return RespuestaModelo.fromFormatException(exception, metodo, path, capa);
    } on Exception catch (exception) {
      return RespuestaModelo.fromException(exception, metodo, path, capa);
    }
  }
}
