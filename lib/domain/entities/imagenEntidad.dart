import 'dart:typed_data';

import 'package:dpt_movil/data/models/imagenModelo.dart';

class ImagenEntidad {
  final int? id;
  final String nombre;
  final String tipoArchivo;
  final int longitud;
  final Uint8List datos;

  ImagenEntidad(
      {this.id,
      required this.nombre,
      required this.tipoArchivo,
      required this.longitud,
      required this.datos});

  factory ImagenEntidad.fromJson(dynamic json) {
    return ImagenEntidad(
        id: json['id'],
        nombre: json['nombre'],
        tipoArchivo: json['tipoArchivo'],
        longitud: json['longitud'],
        datos: json['datos']);
  }

  factory ImagenEntidad.fromModelo(ImagenModelo modelo) {
    return ImagenEntidad(
        nombre: modelo.nombre,
        tipoArchivo: modelo.tipoArchivo,
        longitud: modelo.longitud,
        datos: modelo.convertirDeBase64());
  }
}
