import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';

//conversion modelo <-> entidad del perfil de la sesion (login y registro).
//Vive en la capa de datos para que entidad y modelo no se importen entre si
class PerfilMapper {
  static PerfilEntidad aEntidad(Perfilmodelo modelo) {
    return PerfilEntidad(
      id: modelo.id,
      nombre: modelo.nombre,
      correo: modelo.correo,
      tipoId: modelo.tipoId,
      sexo: modelo.sexo,
      role: modelo.role,
      facultad: modelo.facultad,
      tipoAlumno: modelo.tipoAlumno,
    );
  }

  static Perfilmodelo aModelo(PerfilEntidad entidad) {
    return Perfilmodelo(
      id: entidad.id,
      nombre: entidad.nombre,
      correo: entidad.correo,
      tipoId: entidad.tipoId,
      sexo: entidad.sexo,
      role: entidad.role,
      facultad: entidad.facultad,
      tipoAlumno: entidad.tipoAlumno,
    );
  }
}
