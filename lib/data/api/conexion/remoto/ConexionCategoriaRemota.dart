import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:dpt_movil/data/api/conexion/ConexionCategoria.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/config/configServicio.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class ConexionCategoriaRemota implements ConexionCategoria {
  final _dio = Dio(
    BaseOptions(
      baseUrl: ConfigServicio().obtenerBaseApi(),
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      sendTimeout: Duration(seconds: 10),
    ),
  );

  @override
  Future<RespuestaModelo> encontrarCategorias() async {
    final String metodo = 'GET';
    try {
      final response = await _dio.get('/categorias');
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
    } on Exception catch (exc) {
      return RespuestaModelo(
        codigoHttp: 0,
        datos: null,
        error: ErrorModelo(
          codigoHttp: 0,
          mensaje: 'Error fuera de la conexion: ${exc.toString()}',
          url: '',
          metodo: metodo,
        ),
      );
    }
  }

  @override
  Future<RespuestaModelo> guardarCategoria(categoriaModelo datos) async {
    final String metodo = 'POST';
    late String tipoMime;
    if (datos.imagenFile != null) {
      tipoMime = lookupMimeType(datos.imagenFile!.path)!;
    }
    //Se crea el formData a enviar
    FormData formData = FormData.fromMap({
      'titulo': datos.titulo,
      'descripcion': datos.descripcion,
      'imagen':
          (datos.imagenFile != null)
              ? (await MultipartFile.fromFile(
                datos.imagenFile!.path,
                filename: datos.imagenFile!.path.split('/').last,
                contentType: DioMediaType.parse(tipoMime),
              ))
              : '',
    });
    try {
      //se hace la peticion con el formdata
      final response = await _dio.post('/categoriass', data: formData);
      //Si hay error se retorna una respuesta segun el codigo
      if (response.statusCode != 201) {
        RespuestaModelo.fromResponse(response, metodo);
      }
      //exito en la peticion
      return RespuestaModelo(
        codigoHttp: response.statusCode!,
        error: null,
        datos: categoriaModelo.fromJson(response.data),
      );
    } on DioException catch (dioExc) {
      //Se ha generado un error en la peticion, generar respuesta segun tipo de excepcion
      return RespuestaModelo.fromDioException(dioExc, metodo);
    } on Exception catch (exc) {
      //se ha generado un error desconocido
      return RespuestaModelo(
        codigoHttp: 0,
        datos: null,
        error: ErrorModelo(
          codigoHttp: 0,
          mensaje: 'Error fuera de la conexion: ${exc.toString()}',
          url: '',
          metodo: metodo,
        ),
      );
    }
  }

  @override
  Future<RespuestaModelo> eliminarCategoria(String titulo) {
    // TODO: implement eliminarCategoria
    throw UnimplementedError();
  }

  @override
  Future<RespuestaModelo> actualizarCategoria(categoriaModelo categoria) {
    // TODO: implement actualizarCategoria
    throw UnimplementedError();
  }
}
