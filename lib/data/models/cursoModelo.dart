import 'package:dpt_movil/data/models/imagenModelo.dart';

class CursoModelo {
  final String nombreCurso;
  final String nombreDeporte;
  final String tituloCategoria;
  final String descripcion;
  final int? imagen;

  CursoModelo({
    required this.nombreCurso,
    required this.nombreDeporte,
    required this.tituloCategoria,
    required this.descripcion,
    this.imagen,
  });

  factory CursoModelo.fromJson(dynamic json) {
    return CursoModelo(
      nombreCurso: json['nombre'],
      nombreDeporte: json['deporte'],
      tituloCategoria: json['categoriaCurso'],
      descripcion: json['descripcion'],
      imagen: ((json['imagen'] != null) ? json['imagen'] : (null)),
    );
  }
}
