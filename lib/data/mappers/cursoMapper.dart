import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';

//conversion modelo <-> entidad de cursos. Vive en la capa de datos para
//que entidad y modelo no se importen entre si
class CursoMapper {
  static CursoEntidad aEntidad(CursoModelo modelo) {
    return CursoEntidad(
      nombreCurso: modelo.nombreCurso,
      nombreDeporte: modelo.nombreDeporte,
      tituloCategoria: modelo.tituloCategoria,
      descripcion: modelo.descripcion,
      imagen: modelo.imagen,
      imagenFile: modelo.imagenFile,
    );
  }

  static CursoModelo aModelo(CursoEntidad entidad) {
    return CursoModelo(
      nombreCurso: entidad.nombreCurso,
      nombreDeporte: entidad.nombreDeporte,
      tituloCategoria: entidad.tituloCategoria,
      descripcion: entidad.descripcion,
      imagen: entidad.imagen,
      imagenFile: entidad.imagenFile,
    );
  }
}
