import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:mime/mime.dart';

class Conexionimagenremoto implements Conexionimagen {
  final _dio = Dio(
    BaseOptions(
      baseUrl: ConfigServicio().obtenerBaseApi(),
      connectTimeout: Duration(minutes: 10),
      receiveTimeout: Duration(minutes: 10),
      sendTimeout: Duration(minutes: 10),
    ),
  );

  @override
  Future<RespuestaModelo> insertarImagenFile(File file) async {
    String metodo = "POST";
    String path = "/imagenMultipart";
    String tipoMime = lookupMimeType(file.path) ?? 'application/octet-stream';
    String nombreArchivo = file.path.split('/').last;
    try {
      tipoMime = lookupMimeType(file.path)!;
      FormData fromData = FormData.fromMap({
        'nombre': nombreArchivo,
        'tipoArchivo': tipoMime,
        'longitud': (await file.length()).toString(),
        'datosMultipartFile': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
          contentType: DioMediaType.parse(tipoMime),
        ),
      });

      final response = await _dio.post(path, data: fromData);
      if (response.statusCode != 201) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      ImagenModelo imagenModelo = ImagenModelo.fromJson(response.data);
      return RespuestaModelo(codigoHttp: 201, datos: imagenModelo);
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

  @override
  Future<RespuestaModelo> obtenerImagen(int idImagen) async {
    String metodo = "GET";
    //String path = "/imagen?idImagen=$idImagen";
    String path = "/imagen?idImagen=$idImagen";
    try {
      final response = await _dio.get(path);
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      ImagenModelo imagenModelo = ImagenModelo.fromJson(response.data);
      RespuestaModelo respuesta = RespuestaModelo(
        codigoHttp: 200,
        datos: imagenModelo,
      );
      return respuesta;
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
