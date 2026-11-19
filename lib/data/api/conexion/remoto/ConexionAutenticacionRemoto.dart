import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAutenticacion.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/models/tokenModelo.dart';

class Conexionautenticacionremoto implements Conexionautenticacion {
  //el Dio compartido llega desde la raiz de composicion
  final Dio _dio;

  //esta conexion esperaba hasta 1 minuto antes de usar el Dio compartido
  //(20 s): se conserva pidiendolo en cada peticion
  static final Options _opcionesAutenticacion = Options(
    sendTimeout: const Duration(minutes: 1),
    receiveTimeout: const Duration(minutes: 1),
  );

  Conexionautenticacionremoto(this._dio);

  @override
  Future<RespuestaModelo> login(String email) async {
    String metodo = "GET";
    String path = "/login";
    try {
      //el correo va como parametro de la query, codificado por Dio: pegado a
      //la URL, un + llegaba como espacio y un & partia la query (AU-01)
      final response = await _dio.get(
        path,
        queryParameters: {'email': email},
        options: _opcionesAutenticacion,
      );
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
    } catch (error) {
      //un perfil con un campo obligatorio nulo hace lanzar un TypeError a
      //fromJson: se devuelve en lugar de dejarlo escapar (AU-03)
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
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
        options: _opcionesAutenticacion.copyWith(
          contentType: ContentType.json.toString(),
        ),
      );
      if (response.statusCode != 201) {
        return RespuestaModelo.fromResponse(response, metodo);
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
    } catch (error) {
      //un 201 sin cuerpo o con un perfil incompleto hace fallar fromJson con
      //un Error (AU-03)
      return RespuestaModelo.fromObjectError(error, metodo, path, capa);
    }
  }

  @override
  Future<RespuestaModelo> intercambiarToken(String idTokenGoogle) async {
    String metodo = "POST";
    String path = "/auth/token";
    String capa = "Conexion";
    try {
      //el ID Token de Google va en la cabecera; InterceptorToken no la pisa
      final response = await _dio.post(
        path,
        options: _opcionesAutenticacion.copyWith(
          headers: {'Authorization': 'Bearer $idTokenGoogle'},
        ),
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(
        codigoHttp: 200,
        datos: Tokenmodelo.fromJson(response.data),
      );
    } on DioException catch (dioExc) {
      return RespuestaModelo.fromDioException(dioExc, metodo);
    } on FormatException catch (exception) {
      return RespuestaModelo.fromFormatException(exception, metodo, path, capa);
    } on Exception catch (exception) {
      return RespuestaModelo.fromException(exception, metodo, path, capa);
    } catch (error) {
      //un cuerpo sin token o sin perfil hace fallar fromJson con un Error
      //(no una Exception): se devuelve en lugar de dejarlo escapar (AU-03)
      return RespuestaModelo.fromObjectError(error, metodo, path, capa);
    }
  }
}
