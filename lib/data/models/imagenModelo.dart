import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:mime/mime.dart';

class ImagenModelo {
  int? id;
  String nombre;
  String tipoArchivo;
  int longitud;
  File? datos;
  MultipartFile? datosMultipartFile;
  String? datosBase64;

  ImagenModelo({
    this.id,
    required this.nombre,
    required this.tipoArchivo,
    required this.longitud,
    this.datos,
    this.datosBase64,
    this.datosMultipartFile,
  });

  factory ImagenModelo.fromJson(dynamic json) {
    return ImagenModelo(
      id: json['id'],
      nombre: json['nombre'],
      tipoArchivo: json['tipoArchivo'],
      longitud: json['longitud'],
      datosBase64: json['datosBase64'],
    );
  }

  //convierte retorna el parametro datos en Uint8List, tipo de dato util para manejo de imagenes
  //Uint8List convertirDeBase64() {
  //  return Base64Decoder().convert(datos);
  //}
}
