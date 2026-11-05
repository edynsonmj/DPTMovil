import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';

//conversion modelo -> entidad de horarios. Solo hay este sentido: el
//backend no tiene ruta para crear horarios
class HorarioMapper {
  static Horarioentidad aEntidad(HorarioModelo modelo) {
    return Horarioentidad(
      id: modelo.id,
      categoria: modelo.categoria,
      curso: modelo.curso,
      anio: modelo.anio,
      iterable: modelo.iterable,
      dia: modelo.dia,
      horaInicio: modelo.horaInicio,
      horaFin: modelo.horaFin,
      escenario: modelo.escenario,
    );
  }
}
