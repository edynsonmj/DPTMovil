import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionDeporte.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexiondeporteremoto implements Conexiondeporte {
  //el Dio compartido llega desde la raiz de composicion, con la baseUrl
  final Dio _dio;

  Conexiondeporteremoto(this._dio);

  @override
  Future<RespuestaModelo> obtenerDeportes() async {
    String metodo = "GET";
    String path = '/deportes';
    String capa = "Conexion";
    try {
      final response = await _dio.get(path);
      if (response.statusCode == 204) {
        return RespuestaModelo(
          codigoHttp: 204,
          error: ErrorModelo(
            codigoHttp: 204,
            mensaje: "no hay deportes registrados",
            url: path,
            metodo: metodo,
          ),
        );
      }
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      List<dynamic> listaResponse = response.data as List<dynamic>;
      List<String> deportes =
          listaResponse.map((item) => item['nombre'] as String).toList();
      return RespuestaModelo(codigoHttp: 200, datos: deportes);
    } on DioException catch (dioError) {
      //un codigo de error del backend llega como DioException (bad response):
      //se conserva su codigo. Antes caia en Exception y llegaba como 0 (DE-01)
      return RespuestaModelo.fromDioException(dioError, metodo);
    } on Exception catch (exception) {
      return RespuestaModelo.fromException(exception, metodo, path, capa);
    } catch (exception) {
      return RespuestaModelo.fromObjectError(exception, metodo, path, capa);
    }
  }
}
