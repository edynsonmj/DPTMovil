import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionEstadisticas.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionestadisticasremoto implements ConexionEstadisticas {
  final _dio = Dio(BaseOptions(baseUrl: ConfigServicio().obtenerBaseApi()));

  @override
  Future<RespuestaModelo> generalCategorias(
    String fechaInicio,
    String fechafin,
  ) async {
    String metodo = "GET";
    String path = '/estadisticas/categorias?inicio=$fechaInicio&fin=$fechafin';
    String capa = "Conexion";
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
      List<dynamic> data = response.data;
      List<EstadisticaModelo> clases =
          data.map((json) => EstadisticaModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: clases);
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
      return RespuestaModelo.fromException(error, metodo, path, capa);
    }
  }

  @override
  Future<RespuestaModelo> generalCursos(
    String fechaInicio,
    String fechafin,
  ) async {
    String metodo = "GET";
    String path = '/estadisticas/cursos?inicio=$fechaInicio&fin=$fechafin';
    String capa = "Conexion";
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
      List<dynamic> data = response.data;
      List<EstadisticaModelo> clases =
          data.map((json) => EstadisticaModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: clases);
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
      return RespuestaModelo.fromException(error, metodo, path, capa);
    }
  }

  @override
  Future<RespuestaModelo> generalGrupos(
    String fechaInicio,
    String fechafin,
  ) async {
    String metodo = "GET";
    String path = '/estadisticas/grupos?inicio=$fechaInicio&fin=$fechafin';
    String capa = "Conexion";
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
      List<dynamic> data = response.data;
      List<EstadisticaModelo> clases =
          data.map((json) => EstadisticaModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: clases);
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
      return RespuestaModelo.fromException(error, metodo, path, capa);
    }
  }

  @override
  Future<RespuestaModelo> institucionalFacultades() {
    // TODO: implement institucionalFacultades
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> institucionalProgramas(String facultad) {
    // TODO: implement institucionalProgramas
    throw UnimplementedError();
  }
}
