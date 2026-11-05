import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';

//conversion modelo <-> entidad de alumnos. Vive en la capa de datos para
//que las entidades no conozcan los modelos
class AlumnoMapper {
  static Alumnoentidad aEntidad(Alumnomodelo modelo) {
    return Alumnoentidad(
      id: modelo.id,
      tipo: modelo.tipo,
      nombre: modelo.nombre,
      correo: modelo.correo,
      sexo: modelo.sexo,
      tipoid: modelo.tipoid,
      codigo: modelo.codigo,
      imagen: modelo.imagen,
    );
  }

  static Alumnomodelo aModelo(Alumnoentidad entidad) {
    return Alumnomodelo(
      id: entidad.id,
      tipo: entidad.tipo,
      nombre: entidad.nombre,
      correo: entidad.correo,
      sexo: entidad.sexo,
      tipoid: entidad.tipoid,
      codigo: entidad.codigo,
      imagen: entidad.imagen,
    );
  }
}
