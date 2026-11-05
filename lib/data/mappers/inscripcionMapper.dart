import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';

//conversion entidad -> modelo de inscripciones. Solo hay este sentido:
//agregar, eliminar y validar envian la inscripcion y ninguna respuesta se
//convierte de vuelta
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
}
