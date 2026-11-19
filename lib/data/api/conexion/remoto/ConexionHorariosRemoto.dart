import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionHorarios.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionhorariosremoto extends Conexionhorarios {
  //el Dio compartido llega desde la raiz de composicion, con la baseUrl
  final Dio _dio;

  Conexionhorariosremoto(this._dio);

  @override
  Future<RespuestaModelo> obtenerHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    String metodo = "GET";
    String path = '/horarios';
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
      //un grupo sin horarios responde 200 con un objeto GC-0002 ("listado
      //vacio"), no con []: es una lista vacia, no un error (BK-05)
      if (response.data is Map && response.data['codigoError'] == 'GC-0002') {
        return RespuestaModelo(codigoHttp: 200, datos: <HorarioModelo>[]);
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
      List<HorarioModelo> horarios =
          data.map((json) => HorarioModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: horarios);
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
  Future<RespuestaModelo> agregarHorario(HorarioModelo modelo) async {
    String metodo = "POST";
    String path = '/horario';
    try {
      final response = await _dio.post(
        path,
        data: modelo.toJson(),
        options: Options(contentType: 'application/json'),
      );
      if (response.statusCode != 201) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: 201);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }

  @override
  Future<RespuestaModelo> eliminarHorario(int id) async {
    String metodo = "DELETE";
    String path = '/horario';
    try {
      final response = await _dio.delete(path, queryParameters: {'prmId': id});
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: 200);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }
}
