import 'dart:io';

import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';

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
  factory CursoModelo.fromEntidad(CursoEntidad entidad) {
    return CursoModelo(
      nombreCurso: entidad.nombreCurso,
      nombreDeporte: entidad.nombreDeporte,
      tituloCategoria: entidad.tituloCategoria,
      descripcion: entidad.descripcion,
      imagen: entidad.imagen,
      imagenFile: entidad.imagenFile,
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
