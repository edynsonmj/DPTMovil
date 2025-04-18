import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:mime/mime.dart';

class ImagenModelo {
  final int? id;
  final String nombre;
  final String tipoArchivo;
  final int longitud;
  final String datos;

  ImagenModelo({
    this.id,
    required this.nombre,
    required this.tipoArchivo,
    required this.longitud,
    required this.datos,
  });

  factory ImagenModelo.fromJson(dynamic json) {
    return ImagenModelo(
        id: json['id'],
        nombre: json['nombre'],
        tipoArchivo: json['tipoArchivo'],
        longitud: json['longitud'],
        datos: json['datos']);
  }

  //convierte retorna el parametro datos en Uint8List, tipo de dato util para manejo de imagenes
  Uint8List convertirDeBase64() {
    return Base64Decoder().convert(datos);
  }
}
