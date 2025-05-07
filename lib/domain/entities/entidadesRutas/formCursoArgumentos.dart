import 'package:dpt_movil/domain/entities/cursoEntidad.dart';

///Transporta la informacion de un curso, el nombre de la categoria y un bandera para conocer si es edicion o insercion
class Formcursoargumentos {
  ///Curso a editar si es nulo conlleva insercion
  CursoEntidad? curso;

  ///true es edicion false de lo contrario
  bool esEdicion;

  ///si es insercion es necesario conocer el la categoria a la que se adscribe el curso
  String categoria;
  Formcursoargumentos({
    this.curso,
    required this.esEdicion,
    required this.categoria,
  });
}
