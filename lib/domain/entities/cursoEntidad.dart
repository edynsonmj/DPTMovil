import 'dart:io';

import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

class CursoEntidad {
  String nombreCurso;
  String nombreDeporte;
  String tituloCategoria;
  String descripcion;
  int? imagen;
  File? imagenFile;

  CursoEntidad({
    required this.nombreCurso,
    required this.nombreDeporte,
    required this.tituloCategoria,
    required this.descripcion,
    this.imagen,
    this.imagenFile,
  });

  factory CursoEntidad.fromModelo(CursoModelo modelo) {
    return CursoEntidad(
      nombreCurso: modelo.nombreCurso,
      nombreDeporte: modelo.nombreDeporte,
      tituloCategoria: modelo.tituloCategoria,
      descripcion: modelo.descripcion,
      imagen: modelo.imagen,
      imagenFile: modelo.imagenFile,
    );
  }
}
