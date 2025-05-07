import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexiongruposremoto extends Conexiongrupos {
  final _dio = Dio(BaseOptions(baseUrl: ConfigServicio().obtenerBaseApi()));

  @override
  Future<RespuestaModelo> obtenerGruposDe(
    String categoriaTitulo,
    String nombreCurso,
  ) async {
    String metodo = "GET";
    try {
      String path =
          '/gruposCurso?prmCategoria=$categoriaTitulo&prmCurso=$nombreCurso';
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
      List<GrupoModelo> grupos =
          data.map((json) => GrupoModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: grupos, error: null);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on Exception catch (exc) {
      return RespuestaModelo(
        codigoHttp: 0,
        datos: null,
        error: ErrorModelo(
          codigoHttp: 0,
          mensaje: 'Error fuera de la conexion: ${exc.toString()}',
          url: '',
          metodo: metodo,
        ),
      );
    }
  }

  @override
  Future<RespuestaModelo> obtenerGruposInscripcionDisponible() async {
    String metodo = "GET";
    try {
      String path = '/gruposInscripcion';
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
      List<GrupoModelo> grupos =
          data.map((json) => GrupoModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: grupos, error: null);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on Exception catch (exc) {
      return RespuestaModelo(
        codigoHttp: 0,
        datos: null,
        error: ErrorModelo(
          codigoHttp: 0,
          mensaje: 'Error fuera de la conexion: ${exc.toString()}',
          url: '',
          metodo: metodo,
        ),
      );
    }
  }

  @override
  Future<RespuestaModelo> obtenerGruposInstructor(String idInstructor) async {
    String metodo = "GET";
    String path = '/gruposInstructor?idInstructor=$idInstructor';
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
      List<GrupoModelo> grupos =
          data.map((json) => GrupoModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: grupos, error: null);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on Exception catch (exc) {
      return RespuestaModelo(
        codigoHttp: 0,
        datos: null,
        error: ErrorModelo(
          codigoHttp: 0,
          mensaje: 'Error fuera de la conexion: ${exc.toString()}',
          url: '',
          metodo: metodo,
        ),
      );
    }
  }

  @override
  Future<RespuestaModelo> insertarGrupo(GrupoModelo grupo) async {
    String metodo = "POST";
    String path = "/grupo";
    String capa = "conexion";
    try {
      final response = await _dio.post(
        path,
        data: grupo,
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
        capa,
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(error, metodo, path, capa);
    }
  }
}
