import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionInscripcion.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:dpt_movil/data/models/inscripcionResumenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexioninscripcionremoto implements Conexioninscripcion {
  //el Dio compartido llega desde la raiz de composicion. Antes esta conexion
  //esperaba hasta 10 minutos; desde la fase 6 usa los 20 s del compartido
  final Dio _dio;

  Conexioninscripcionremoto(this._dio);

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
      //el 201 no dice si entro al grupo: `estado` puede ser EN_ESPERA (BK-06)
      return RespuestaModelo(codigoHttp: 201, datos: _estadoDe(response.data));
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
      //incluye el TypeError de armar el error con un cuerpo JSON (IN-12)
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }

  @override
  Future<RespuestaModelo> validarInscripcion(Inscripcionmodelo modelo) async {
    String metodo = "GET";
    String path = "/validarInscripcion";
    String capa = "Conexion";
    try {
      //el backend espera la inscripcion como parametros de query desde el
      //2026-10-29 (IN-07); antes iba en el cuerpo del GET, que ahora da 400.
      //queryParameters los codifica: los titulos llevan espacios y tildes
      final response = await _dio.get(
        path,
        queryParameters: {
          'alumnoId': modelo.alumnoId,
          'categoria': modelo.categoria,
          'curso': modelo.curso,
          'anio': modelo.anio,
          'iterable': modelo.iterable,
        },
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
    } catch (error) {
      //incluye el TypeError si la respuesta no es un booleano
      return RespuestaModelo.fromObjectError(error, metodo, path, capa);
    }
  }

  @override
  Future<RespuestaModelo> eliminarInscripcion(Inscripcionmodelo modelo) async {
    //la peticion es un PUT: el origen de un error debe nombrar el metodo que
    //salio (antes decia POST, IN-08)
    String metodo = "PUT";
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
    } catch (error) {
      //incluye el TypeError de armar el error con un cuerpo JSON (IN-12)
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }

  //inscripciones activas del alumno de la sesion: el backend lo saca del JWT.
  //Es la unica ruta que dice si esta en lista de espera (IN-15)
  @override
  Future<RespuestaModelo> obtenerMisCursos() async {
    String metodo = "GET";
    String path = "/inscripcion/misCursos";
    try {
      final response = await _dio.get(path);
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
      return RespuestaModelo(
        codigoHttp: 200,
        datos:
            (response.data as List)
                .map<Inscripcionresumenmodelo>(
                  Inscripcionresumenmodelo.fromJson,
                )
                .toList(),
      );
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

  String? _estadoDe(dynamic cuerpo) =>
      cuerpo is Map ? cuerpo['estado']?.toString() : null;
}
