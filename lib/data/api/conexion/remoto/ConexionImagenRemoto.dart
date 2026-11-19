import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:mime/mime.dart';

class Conexionimagenremoto implements Conexionimagen {
  final Dio _dio;

  //las imagenes tardan mas que el resto: se piden 30 s en cada peticion,
  //tambien cuando el Dio es el compartido de la raiz (20 s)
  static final Options _opcionesImagen = Options(
    sendTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );

  //el Dio compartido llega desde la raiz de composicion
  Conexionimagenremoto(this._dio);

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

      final response = await _dio.post(
        path,
        data: fromData,
        options: _opcionesImagen,
      );
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
      final response = await _dio.get(path, options: _opcionesImagen);
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
    } catch (error) {
      //una imagen con un campo obligatorio nulo hace lanzar un TypeError a
      //fromJson (IM-01)
      return RespuestaModelo.fromObjectError(error, metodo, path, 'conexion');
    }
  }
}
