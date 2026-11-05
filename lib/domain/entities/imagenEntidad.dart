import 'dart:typed_data';

class ImagenEntidad {
  final int? id;
  final String nombre;
  final String tipoArchivo;
  final int longitud;
  final Uint8List datos;

  ImagenEntidad({
    this.id,
    required this.nombre,
    required this.tipoArchivo,
    required this.longitud,
    required this.datos,
  });

  factory ImagenEntidad.fromJson(dynamic json) {
    return ImagenEntidad(
      id: json['id'],
      nombre: json['nombre'],
      tipoArchivo: json['tipoArchivo'],
      longitud: json['longitud'],
      datos: json['datos'],
    );
  }
}
