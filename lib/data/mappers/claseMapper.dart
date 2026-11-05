import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';

//conversion modelo <-> entidad de clases. Vive en la capa de datos para
//que entidad y modelo no se importen entre si
class ClaseMapper {
  static Claseentidad aEntidad(Clasemodelo modelo) {
    return Claseentidad(
      codigo: modelo.codigo,
      idGrupoCategoria: modelo.idGrupoCategoria,
      idGrupoCurso: modelo.idGrupoCurso,
      idGrupoAnio: modelo.idGrupoAnio,
      idGrupoIterable: modelo.idGrupoIterable,
      idInstructor: modelo.idInstructor,
      fecha: modelo.fecha,
      horas: modelo.horas,
      minutos: modelo.minutos,
      observacion: modelo.observacion,
      eliminado: modelo.eliminado,
    );
  }

  //fecha, horas y minutos son opcionales en la entidad pero obligatorios en
  //el modelo: una entidad incompleta lanza aqui (CL-04, abierto)
  static Clasemodelo aModelo(Claseentidad entidad) {
    return Clasemodelo(
      codigo: entidad.codigo,
      idGrupoCategoria: entidad.idGrupoCategoria,
      idGrupoCurso: entidad.idGrupoCurso,
      idGrupoAnio: entidad.idGrupoAnio,
      idGrupoIterable: entidad.idGrupoIterable,
      idInstructor: entidad.idInstructor,
      fecha: entidad.fecha!,
      horas: entidad.horas!,
      minutos: entidad.minutos!,
      observacion: entidad.observacion,
      eliminado: entidad.eliminado,
    );
  }
}
