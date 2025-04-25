import 'dart:io';
import 'dart:typed_data';

import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
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

  factory CategoriaEntidad.fromModelo(categoriaModelo modelo) {
    ImagenEntidad? imagen;

    if (modelo.imagen != null) {
      ImagenModelo imagenModelo = modelo.imagen!;
      imagen = ImagenEntidad(
        nombre: imagenModelo.nombre,
        tipoArchivo: imagenModelo.tipoArchivo,
        longitud: imagenModelo.longitud,
        datos: Uint8List(8),
      ); //completar luego
    }

    return CategoriaEntidad(
      titulo: modelo.titulo,
      descripcion: modelo.descripcion,
      imagen: imagen,
      idImagen: modelo.imagenId,
    );
  }
}
