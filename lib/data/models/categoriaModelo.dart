import 'dart:io';

import 'package:dpt_movil/data/models/imagenModelo.dart';

class categoriaModelo {
  final String titulo;
  final String descripcion;
  final ImagenModelo? imagen;
  File? imagenFile;

  categoriaModelo(
      {required this.titulo, required this.descripcion, this.imagen});

  factory categoriaModelo.fromJson(dynamic json) {
    return categoriaModelo(
        titulo: json['titulo'],
        descripcion: json['descripcion'],
        imagen: ((json['imagen'] != null)
            ? ImagenModelo.fromJson(json['imagen'])
            : (null)));
  }

  dynamic toJson() {
    return {
      'titulo': titulo,
      'descripcion': descripcion,
      'imagen': imagen,
    };
  }
}
