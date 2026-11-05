import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/domain/entities/instructorEntidad.dart';

//conversion modelo -> entidad de instructores. Solo hay este sentido: la
//app solo lista instructores
class InstructorMapper {
  static Instructorentidad aEntidad(Instructormodelo modelo) {
    return Instructorentidad(
      id: modelo.id,
      nombre: modelo.nombre,
      correo: modelo.correo,
      sexo: modelo.sexo,
    );
  }
}
