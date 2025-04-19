import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/ConexionHorarios.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionhorariosremoto extends Conexionhorarios {
  final _dio = Dio(BaseOptions(baseUrl: ConfigServicio().obtenerBaseApi()));
  @override
  Future<RespuestaModelo> obtenerHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    String metodo = "GET";
    try {
      String path =
          '/horarios?categoria=$categoria&curso=$curso&anio=$anio&iterable=$iterable';
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
      List<HorarioModelo> horarios =
          data.map((json) => HorarioModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: horarios);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        'obtenerHorariosGrupo',
        'conexion',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        metodo,
        'obtenerHorariosGrupo',
        'conexion',
      );
    }
  }
}
