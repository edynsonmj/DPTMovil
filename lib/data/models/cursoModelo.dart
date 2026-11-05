import 'dart:io';

class CursoModelo {
  String nombreCurso;
  String nombreDeporte;
  String tituloCategoria;
  String descripcion;
  int? imagen;
  File? imagenFile;

  CursoModelo({
    required this.nombreCurso,
    required this.nombreDeporte,
    required this.tituloCategoria,
    required this.descripcion,
    this.imagen,
    this.imagenFile,
  });

  factory CursoModelo.fromJson(dynamic json) {
    return CursoModelo(
      nombreCurso: json['nombre'],
      nombreDeporte: json['deporte'],
      tituloCategoria: json['categoriaCurso'],
      descripcion: json['descripcion'],
      imagen: json['idImagen'],
    );
  }

  dynamic toJson() {
    return {
      "nombre": nombreCurso,
      "deporte": nombreDeporte,
      "categoriaCurso": tituloCategoria,
      "descripcion": descripcion,
      "idImagen": imagen,
    };
  }
}
