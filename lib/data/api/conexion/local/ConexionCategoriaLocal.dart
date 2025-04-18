import 'dart:convert';
import 'dart:io';

import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:mime/mime.dart';
import 'package:dpt_movil/data/api/conexion/ConexionCategoria.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class ConexionCategoriaLocal implements ConexionCategoria {
  final List<categoriaModelo> _base = [
    categoriaModelo(
      titulo: 'Deporte Recreativo',
      descripcion:
          'El deporte recreativo es la modalidad definida como aquella practicada por placer y diversión, sin ninguna intención de competir o superar a un adversario.',
    ),
    categoriaModelo(
      titulo: 'Semilleros deportivos',
      descripcion:
          'Este espacio tiene la facultad de ayudar a desarrollar destrezas físicas, hacer ejercicios, socializar, divertirse, aprender a jugar formando parte de un grupo o equipo, aprender a jugar limpio y a mejorar su autoestima.',
    ),
    categoriaModelo(
      titulo: 'Seleccionados',
      descripcion:
          'Es un espacio para el entrenamiento y participación en eventos deportivos competitivos de carácter universitario, realizados a nivel local, nacional e internacional, bien sea en la red ASCUN o invitaciones de otras universidades.',
    ),
  ];
  @override
  Future<RespuestaModelo> guardarCategoria(categoriaModelo categoria) async {
    late ImagenModelo imagen;
    for (categoriaModelo element in _base) {
      if (element.titulo == categoria.titulo) {
        return await Future.value(
          RespuestaModelo(
            codigoHttp: 409,
            error: ErrorModelo(
              codigoHttp: 409,
              mensaje: 'Elemento ya existente',
              url: 'local/post/categoria',
              metodo: 'POST',
            ),
          ),
        );
      }
    }
    //si la imagen ha sido cargada para la prueba la adjunto al tipo de retorno, que es en base 64
    if (categoria.imagenFile == null) {
      return await Future.value(
        RespuestaModelo(
          codigoHttp: 404,
          error: ErrorModelo(
            codigoHttp: 404,
            mensaje: 'No se ha adjuntado la imagen',
            url: 'local/post/categoria',
            metodo: 'POST',
          ),
        ),
      );
    }
    //si existe la imagen la convierto y guardo
    File file = categoria.imagenFile!;
    String nombre = file.path.split('/').last;
    String? tipoArchivo = lookupMimeType(file.path);
    int longitud = await file.length();
    List<int> bytes = await file.readAsBytes();
    String datos = base64Encode(bytes);
    imagen = ImagenModelo(
      nombre: nombre,
      tipoArchivo: tipoArchivo ?? '',
      longitud: longitud,
      datos: datos,
    );
    //lleno los datos en un tipo de dato que responde el servicio
    categoriaModelo modelo = categoriaModelo(
      titulo: categoria.titulo,
      descripcion: categoria.descripcion,
      imagen: imagen,
    );
    //la adiciono a la lista para conservar y probar
    _base.add(modelo);
    // respondo
    return await Future.value(
      RespuestaModelo(codigoHttp: 201, datos: modelo, error: null),
    );
  }

  @override
  Future<RespuestaModelo> encontrarCategorias() async {
    if (_base.isEmpty) {
      return await Future.value(
        RespuestaModelo(
          codigoHttp: 204,
          datos: _base,
          error: ErrorModelo(
            codigoHttp: 204,
            mensaje: 'Lastimosamente no hay datos a cargar',
            url: 'Mock/categorias',
            metodo: 'GET',
          ),
        ),
      );
    }
    return await Future.value(
      RespuestaModelo(codigoHttp: 200, datos: _base, error: null),
    );
  }

  @override
  Future<RespuestaModelo> eliminarCategoria(String titulo) {
    String metodo = 'DELETE';
    String url = 'mock/categoria/$titulo';
    categoriaModelo? categoria;

    late RespuestaModelo respuesta;
    for (categoriaModelo item in _base) {
      if (item.titulo == titulo) {
        categoria = item;
        _base.remove(item);
        break;
      }
    }
    if (categoria == null) {
      respuesta = RespuestaModelo(
        codigoHttp: 404,
        datos: null,
        error: ErrorModelo(
          codigoHttp: 404,
          mensaje:
              'No se ha encontrado el elemento a eliminar que se buscaba eliminar',
          url: url,
          metodo: metodo,
        ),
      );
      return Future.value(respuesta);
    }
    respuesta = RespuestaModelo(codigoHttp: 200, datos: categoria, error: null);
    return Future.value(respuesta);
  }

  @override
  Future<RespuestaModelo> actualizarCategoria(categoriaModelo categoria) async {
    late ImagenModelo imagen;
    late int indice;
    for (int i = 0; i < _base.length; i++) {
      categoriaModelo item = _base[i];
      if (item.titulo == categoria.titulo) {
        indice = i;
      }
    }
    if (indice == null) {
      return await Future.value(
        RespuestaModelo(
          codigoHttp: 404,
          error: ErrorModelo(
            codigoHttp: 404,
            mensaje: 'Elemento no existente',
            url: 'local/post/categoria',
            metodo: 'PUT',
          ),
        ),
      );
    }
    if (categoria.imagenFile == null) {
      return await Future.value(
        RespuestaModelo(
          codigoHttp: 400,
          error: ErrorModelo(
            codigoHttp: 400,
            mensaje: 'No se ha adjuntado la imagen',
            url: 'local/post/categoria',
            metodo: 'POST',
          ),
        ),
      );
    }

    File file = categoria.imagenFile!;
    String nombre = file.path.split('/').last;
    String? tipoArchivo = lookupMimeType(file.path);
    int longitud = await file.length();
    List<int> bytes = await file.readAsBytes();
    String datos = base64Encode(bytes);
    imagen = ImagenModelo(
      nombre: nombre,
      tipoArchivo: tipoArchivo ?? '',
      longitud: longitud,
      datos: datos,
    );
    //lleno los datos en un tipo de dato que responde el servicio
    categoriaModelo modelo = categoriaModelo(
      titulo: categoria.titulo,
      descripcion: categoria.descripcion,
      imagen: imagen,
    );

    _base[indice] = modelo;

    return await Future.value(
      RespuestaModelo(codigoHttp: 200, datos: modelo, error: null),
    );
  }
}
