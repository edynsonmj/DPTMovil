import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/ConexionClases.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionclasesremoto implements Conexionclases {
  final _dio = Dio(BaseOptions(baseUrl: ConfigServicio().obtenerBaseApi()));

  @override
  Future<RespuestaModelo> obtenerClasesGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    String metodo = "GET";
    String path =
        '/clasesGrupo?categoria=$categoria&curso=$curso&anio=$anio&iterable=$iterable';
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
    } on Exception catch (error) {
      return RespuestaModelo.fromException(error, metodo, path, 'conexion');
    }
  }
}
