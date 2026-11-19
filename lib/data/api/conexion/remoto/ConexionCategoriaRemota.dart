import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class ConexionCategoriaRemota implements ConexionCategoria {
  //ambas llegan desde la raiz de composicion: el Dio compartido (con la
  //baseUrl y los timeouts) y la conexion de imagenes, que tambien usa curso
  final Dio _dio;
  final Conexionimagen _conexionImagen;

  ConexionCategoriaRemota(this._dio, this._conexionImagen);

  //misma baseUrl que las peticiones de esta conexion
  @override
  String urlImagen(int idImagen) =>
      '${_dio.options.baseUrl}/imagenStream?idImagen=$idImagen';

  @override
  Future<RespuestaModelo> encontrarCategorias() async {
    final String metodo = 'GET';
    try {
      final response = await _dio.get('/categorias2');
      //si el codigo no es 200, generar respuesta segun el codigo recibido
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      //Si el retorno es ua lista, es el caso de exito, transformar y retornar
      if (response.data is List) {
        List<dynamic> lista = response.data;
        List<categoriaModelo> categorias = [];
        for (var item in lista) {
          categoriaModelo categoria = categoriaModelo.fromJson(item);
          categorias.add(categoria);
        }
        return RespuestaModelo(
          codigoHttp: response.statusCode == null ? 200 : response.statusCode!,
          datos: categorias,
        );
      }

      //Debido a que no se esta retornando el codigo 204 cuando la lista esta vacia
      //entonces se hace la siguiente validacion
      //retirar pieza de codigo si se soluciona en el back
      //esto significa que se ha retornado pero no una lista.
      if (response.statusCode == 200) {
        return RespuestaModelo(
          codigoHttp: 204,
          datos: null,
          error: ErrorModelo(
            codigoHttp: 204,
            mensaje: 'La lista de categorias se encuentra vacia',
            metodo: metodo,
            url: response.realUri.toString(),
          ),
        );
      }

      //la peticion no ha fallado, pero la respuesta no es correcta
      //generar respuesta segun los resultado del response
      return RespuestaModelo.fromResponse(response, metodo);
    } on DioException catch (excepcion) {
      return RespuestaModelo.fromDioException(excepcion, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        metodo,
        'categorias',
        'conexion',
      );
    }
  }

  @override
  Future<RespuestaModelo> actualizarCategoria(categoriaModelo categoria) async {
    //el titulo viaja como parametro: un "&" no lo corta (CAT-03)
    String path = "/categoria";
    String metodo = "PUT";
    String capa = "conexion";
    try {
      //hay cambio en la imagen, insertar imagen antes de continuar
      if (categoria.imagenFile != null) {
        //se inserta la imagen
        RespuestaModelo responseImagen = await _conexionImagen
            .insertarImagenFile(categoria.imagenFile!);
        //si falla retone inmediatamente el error antes de continuar
        if (responseImagen.codigoHttp != 201) {
          return responseImagen;
        }
        ImagenModelo imagenModelo = responseImagen.datos as ImagenModelo;
        categoria.imagenId = imagenModelo.id;
      }
      final response = await _dio.put(
        path,
        queryParameters: {'titulo': categoria.titulo},
        data: categoria,
        options: Options(contentType: ContentType.json.toString()),
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      categoriaModelo respuesta = categoriaModelo.fromJson(response.data);
      return RespuestaModelo(codigoHttp: 200, datos: respuesta);
    } on DioException catch (dioExc) {
      //Se ha generado un error en la peticion, generar respuesta segun tipo de excepcion
      return RespuestaModelo.fromDioException(dioExc, metodo);
    } on FormatException catch (format) {
      return RespuestaModelo.fromFormatException(format, metodo, path, capa);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        metodo,
        'categorias',
        'conexion',
      );
    }
  }

  @override
  Future<RespuestaModelo> guardarCategoria(categoriaModelo datos) async {
    final String metodo = 'POST';
    try {
      //con archivo se sube la imagen; sin archivo se usa la que ya existe
      //(idImagen), no se vuelve a subir (CAT-01)
      int? imagenId = datos.imagenId;
      if (datos.imagenFile != null) {
        RespuestaModelo responseImagen = await _conexionImagen
            .insertarImagenFile(datos.imagenFile!);
        if (responseImagen.codigoHttp != 201) {
          return responseImagen;
        }
        imagenId = (responseImagen.datos as ImagenModelo).id;
      }
      categoriaModelo categoria = categoriaModelo(
        titulo: datos.titulo,
        descripcion: datos.descripcion,
        imagenId: imagenId,
      );
      final response = await _dio.post(
        '/categoria',
        data: categoria,
        options: Options(contentType: ContentType.json.toString()),
      );
      //Si hay error se retorna una respuesta segun el codigo
      if (response.statusCode != 201) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      //un 201 sin cuerpo tambien es exito: la categoria se guardo (CAT-02)
      final cuerpo = response.data;
      final sinCuerpo = cuerpo == null || (cuerpo is String && cuerpo.isEmpty);
      return RespuestaModelo(
        codigoHttp: response.statusCode!,
        error: null,
        datos: sinCuerpo ? null : categoriaModelo.fromJson(cuerpo),
      );
    } on DioException catch (dioExc) {
      //Se ha generado un error en la peticion, generar respuesta segun tipo de excepcion
      return RespuestaModelo.fromDioException(dioExc, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        metodo,
        '/categoria',
        'conexion',
      );
    }
  }

  @override
  Future<RespuestaModelo> eliminarCategoria(String titulo) async {
    String metodo = "DELETE";
    String path = "/categoria";
    String capa = "CONEXION";
    try {
      final response = await _dio.delete(
        path,
        queryParameters: {'titulo': titulo},
      );
      if (response.statusCode != 200) {
        return RespuestaModelo.fromResponse(response, metodo);
      }
      return RespuestaModelo(codigoHttp: 200);
    } on DioException catch (excepcion) {
      return RespuestaModelo.fromDioException(excepcion, metodo);
    } catch (error) {
      return RespuestaModelo.fromObjectError(error, metodo, path, capa);
    }
  }
}
