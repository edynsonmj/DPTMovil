import 'dart:io';

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
}
