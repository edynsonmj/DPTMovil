import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionDeporte.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Conexiondeporteremoto implements Conexiondeporte {
  final _dio = Dio();
  @override
  Future<RespuestaModelo> obtenerDeportes() async {
    String metodo = "GET";
    String path = 'http://${ConfigServicio.ip}:8082/api/deportes';
    String capa = "Conexion";
    try {
      final response = await _dio.get(path);
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      List<dynamic> listaResponse = response.data as List<dynamic>;
      List<String> deportes =
          listaResponse.map((item) => item['nombre'] as String).toList();
      return RespuestaModelo(codigoHttp: 200, datos: deportes);
    } on Exception catch (exception) {
      return RespuestaModelo.fromException(exception, metodo, path, capa);
    }
  }
}
