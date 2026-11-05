import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

//conversion modelo <-> entidad de grupos. Vive en la capa de datos para
//que entidad y modelo no se importen entre si
class GrupoMapper {
  static Grupoentidad aEntidad(GrupoModelo modelo) {
    return Grupoentidad(
      categoria: modelo.cat_titulo,
      curso: modelo.cur_nombre,
      anio: modelo.anio,
      iterable: modelo.iterable,
      imagen: modelo.imagen,
      cupos: modelo.cupos,
      estado: modelo.estado,
      fechaCreacion: modelo.fechaCreacion,
      fechaFinalizacion: modelo.fechaFinalizacion,
      idInstructor: modelo.idInstructor,
      fechaInscripcionApertura: modelo.fechaInscripcionApertura,
      fechaInscripcionCierre: modelo.fechaInscripcionCierre,
    );
  }

  //copia todos los campos; toJson decide cuales viajan al backend
  static GrupoModelo aModelo(Grupoentidad entidad) {
    return GrupoModelo(
      cat_titulo: entidad.categoria,
      cur_nombre: entidad.curso,
      anio: entidad.anio,
      iterable: entidad.iterable,
      imagen: entidad.imagen,
      cupos: entidad.cupos,
      estado: entidad.estado,
      fechaCreacion: entidad.fechaCreacion,
      fechaFinalizacion: entidad.fechaFinalizacion,
      idInstructor: entidad.idInstructor,
      fechaInscripcionApertura: entidad.fechaInscripcionApertura,
      fechaInscripcionCierre: entidad.fechaInscripcionCierre,
    );
  }

  static List<Grupoentidad> aEntidades(List<GrupoModelo> modelos) =>
      modelos.map(aEntidad).toList();
}
