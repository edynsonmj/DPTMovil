import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionFacultades.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/programaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexionfacultadremoto implements Conexionfacultades {
  //el Dio compartido llega desde la raiz con la baseUrl: el path es relativo
  final Dio _dio;

  Conexionfacultadremoto(this._dio);

  @override
  Future<RespuestaModelo> obtenerFacultades() async {
    String path = "/facultades";
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

  @override
  Future<RespuestaModelo> obtenerProgramas(String facultad) async {
    String path = "/programas";
    String metodo = "GET";
    String capa = "conexion";
    try {
      final response = await _dio.get(
        path,
        queryParameters: {'facultad': facultad},
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      //una facultad sin programas responde 200 con un objeto GC-0002
      if (response.data is Map && response.data['codigoError'] == 'GC-0002') {
        return RespuestaModelo(codigoHttp: 200, datos: <Programamodelo>[]);
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
      List<Programamodelo> programas =
          data.map((json) => Programamodelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: programas);
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
