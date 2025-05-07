import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

class Formgrupoargumentos {
  Grupoentidad? grupo;
  CursoEntidad curso;
  bool esEdicion;

  Formgrupoargumentos({
    this.grupo,
    required this.esEdicion,
    required this.curso,
  });
}
