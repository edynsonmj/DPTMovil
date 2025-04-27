import 'package:dpt_movil/domain/entities/cursoEntidad.dart';

class Formcursoargumentos {
  CursoEntidad? curso;
  bool esEdicion;
  String categoria;
  Formcursoargumentos({
    this.curso,
    required this.esEdicion,
    required this.categoria,
  });
}
