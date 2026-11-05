import 'dart:io';

import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

class CategoriaEntidad {
  final String? id;
  final String titulo;
  final String descripcion;
  ImagenEntidad? imagen;
  File? imagenFile;
  int? idImagen;

  CategoriaEntidad({
    this.id,
    required this.titulo,
    required this.descripcion,
    this.imagen,
    this.imagenFile,
    this.idImagen,
  });

  factory CategoriaEntidad.fromJson(dynamic json) {
    return CategoriaEntidad(
      titulo: json['titulo'],
      descripcion: json['descripcion'],
      imagenFile: (json['imagenFile'] != null) ? json['imagenFile'] : null,
      imagen:
          ((json['imagen'] != null)
              ? ImagenEntidad.fromJson(json['imagen'])
              : null),
    );
  }
}
