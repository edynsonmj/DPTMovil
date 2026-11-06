import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:dpt_movil/data/models/inscripcionResumenModelo.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionResumenEntidad.dart';

//conversion de inscripciones: agregar, eliminar y validar envian la inscripcion
//(entidad -> modelo); lo unico que vuelve es el resumen de misCursos
class InscripcionMapper {
  static Inscripcionmodelo aModelo(Inscripcionentidad entidad) {
    return Inscripcionmodelo(
      alumnoId: entidad.alumnoId,
      categoria: entidad.categoria,
      curso: entidad.curso,
      anio: entidad.anio,
      iterable: entidad.iterable,
      fechaInscripcion: entidad.fechaInscripcion,
      fechaDesvinculacion: entidad.fechaDesvinculacion,
    );
  }

  static List<Inscripcionresumenentidad> aResumenes(
    List<Inscripcionresumenmodelo> modelos,
  ) {
    return modelos
        .map(
          (modelo) => Inscripcionresumenentidad(
            categoria: modelo.categoria,
            curso: modelo.curso,
            anio: modelo.anio,
            iterable: modelo.iterable,
            estado: modelo.estado,
          ),
        )
        .toList();
  }
}
