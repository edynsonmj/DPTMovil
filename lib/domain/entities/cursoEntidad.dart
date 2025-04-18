import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

class CursoEntidad {
  final String nombreCurso;
  final String nombreDeporte;
  final String tituloCategoria;
  final String descripcion;
  final int? imagen;

  CursoEntidad({
    required this.nombreCurso,
    required this.nombreDeporte,
    required this.tituloCategoria,
    required this.descripcion,
    this.imagen,
  });

  factory CursoEntidad.fromModelo(CursoModelo modelo) {
    return CursoEntidad(
      nombreCurso: modelo.nombreCurso,
      nombreDeporte: modelo.nombreDeporte,
      tituloCategoria: modelo.tituloCategoria,
      descripcion: modelo.descripcion,
      imagen: modelo.imagen,
    );
  }
}
