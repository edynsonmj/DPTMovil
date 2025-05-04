import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionFacultades.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionfacultadremoto implements Conexionfacultades {
  final _dio = Dio();
  @override
  Future<RespuestaModelo> obtenerFacultades() async {
    String path = "http://${ConfigServicio.ip}:8082/api/facultades";
    String metodo = "GET";
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
      List<Facultadmodelo> facultades =
          data.map((json) => Facultadmodelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: facultades);
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
