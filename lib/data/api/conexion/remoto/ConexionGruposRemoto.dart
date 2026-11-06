import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionGrupos.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/periodoInscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexiongruposremoto extends Conexiongrupos {
  //el Dio compartido llega desde la raiz de composicion, con la baseUrl
  final Dio _dio;

  Conexiongruposremoto(this._dio);

  //misma baseUrl que las peticiones de esta conexion
  @override
  String urlImagen(int idImagen) =>
      '${_dio.options.baseUrl}/imagenStream?idImagen=$idImagen';

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

  @override
  Future<RespuestaModelo> obtenerGruposNoEliminados() async {
    String metodo = "GET";
    String path = '/gruposNoEliminados';
    String capa = "conexion";
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
      return RespuestaModelo(codigoHttp: 200, datos: grupos);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      //incluye TypeError de un json incompleto: no escapa de la capa
      return RespuestaModelo.fromObjectError(error, metodo, path, capa);
    }
  }

  //aplica el periodo (PATCH /grupo/periodo). La ruta admite varios grupos y
  //responde la lista actualizada; aqui va y vuelve uno
  @override
  Future<RespuestaModelo> abrirInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
    PeriodoInscripcionModelo periodo,
  ) async {
    String metodo = "PATCH";
    String path = '/grupo/periodo';
    String capa = "conexion";
    try {
      final response = await _dio.patch(
        path,
        data: periodo.toJson(
          categoria: categoria,
          curso: curso,
          anio: anio,
          iterable: iterable,
        ),
        options: Options(contentType: 'application/json'),
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      final grupos = response.data as List;
      return RespuestaModelo(
        codigoHttp: 200,
        datos: GrupoModelo.fromJson(grupos.first),
      );
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      //incluye TypeError de un json incompleto: no escapa de la capa
      return RespuestaModelo.fromObjectError(error, metodo, path, capa);
    }
  }

  @override
  Future<RespuestaModelo> cerrarInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) => _cambiarCierreManual(categoria, curso, anio, iterable, true);

  @override
  Future<RespuestaModelo> reabrirInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) => _cambiarCierreManual(categoria, curso, anio, iterable, false);

  //PATCH /grupo/inscripciones: la llave va en queryParameters para que Dio la
  //codifique, los titulos llevan espacios, tildes y hasta "&"
  Future<RespuestaModelo> _cambiarCierreManual(
    String categoria,
    String curso,
    int anio,
    int iterable,
    bool cerradas,
  ) async {
    String metodo = "PATCH";
    String path = '/grupo/inscripciones';
    String capa = "conexion";
    try {
      final response = await _dio.patch(
        path,
        queryParameters: {
          'categoria': categoria,
          'curso': curso,
          'anio': anio,
          'iterable': iterable,
          'cerradas': cerradas,
        },
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(
        codigoHttp: 200,
        datos: GrupoModelo.fromJson(response.data),
      );
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      //incluye TypeError de un json incompleto: no escapa de la capa
      return RespuestaModelo.fromObjectError(error, metodo, path, capa);
    }
  }
}
