import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCurso.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class ConexionCursoRemoto implements ConexionCurso {
  //ambas llegan desde la raiz de composicion: el Dio compartido (con la
  //baseUrl y los timeouts) y la conexion de imagenes, compartida con categoria
  final Dio _dio;
  final Conexionimagen _conexionImagen;

  ConexionCursoRemoto(this._dio, this._conexionImagen);

  //misma baseUrl que las peticiones de esta conexion
  @override
  String urlImagen(int idImagen) =>
      '${_dio.options.baseUrl}/imagenStream?idImagen=$idImagen';

  @override
  Future<RespuestaModelo> agregarCurso(CursoModelo curso) async {
    String path = "/curso";
    String metodo = "POST";
    String capa = "Conexion";
    try {
      //se inserta la imagen
      RespuestaModelo responseImagen = await _conexionImagen.insertarImagenFile(
        curso.imagenFile!,
      );
      if (responseImagen.codigoHttp != 201) {
        return responseImagen;
      }
      ImagenModelo imagen = responseImagen.datos as ImagenModelo;
      curso.imagen = imagen.id;
      final response = await _dio.post(
        path,
        data: curso,
        options: Options(contentType: ContentType.json.toString()),
      );
      //Dio ya lanza con 4xx/5xx; esto cubre un 2xx distinto de 201
      if (response.statusCode != 201) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      CursoModelo respuesta = CursoModelo.fromJson(response.data);
      return RespuestaModelo(
        codigoHttp: response.statusCode!,
        datos: respuesta,
      );
    } on DioException catch (dioExc) {
      //Se ha generado un error en la peticion, generar respuesta segun tipo de excepcion
      return RespuestaModelo.fromDioException(dioExc, metodo);
    } on FormatException catch (exception) {
      return RespuestaModelo.fromFormatException(exception, metodo, path, capa);
    } catch (exception) {
      return RespuestaModelo.fromObjectError(exception, metodo, path, capa);
    }
  }

  @override
  Future<RespuestaModelo> eliminarCurso(CursoModelo curso) {
    // TODO: implement eliminarCurso
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> enconcontrarCursosDe(String tituloCategoria) async {
    String metodo = "GET";
    //intentar hacer la peticion
    try {
      //la categoria viaja como parametro: un "&" o un "+" en el titulo no la corta (CU-02)
      final response = await _dio.get(
        '/cursosbycategoria',
        queryParameters: {'prmCategoria': tituloCategoria},
      );

      //se espera codigo 200 para la peticion, si no manejar error
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }

      //validar que el formato sea adecuado
      if (response.data is! List) {
        return RespuestaModelo(
          codigoHttp: 406,
          datos: response.data,
          error: ErrorModelo(
            codigoHttp: 406,
            mensaje: "contenido en formato inadecuado",
            url: "cursosBycategoria",
            metodo: metodo,
          ),
        );
      }

      List<dynamic> data = response.data;
      List<CursoModelo> cursos =
          data.map((json) => CursoModelo.fromJson(json)).toList();
      return RespuestaModelo(codigoHttp: 200, datos: cursos, error: null);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        metodo,
        'cursos',
        'conexion',
      );
    }
  }

  @override
  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) async {
    final String metodo = "GET";
    try {
      String path = '/curso';
      final response = await _dio.get(
        path,
        queryParameters: {'prmCategoria': categoria, 'prmCurso': curso},
      );
      //se espera codigo 200 para la peticion, si no manejar error
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      CursoModelo modelo = CursoModelo.fromJson(response.data);
      return RespuestaModelo(codigoHttp: 200, datos: modelo);
    } on DioException catch (dioError) {
      return RespuestaModelo.fromDioException(dioError, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        metodo,
        'cursos',
        'conexion',
      );
    }
  }
}
