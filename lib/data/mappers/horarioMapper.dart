import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';

//conversion de horarios. La app lista, crea y elimina; editar (PUT) no existe
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

  static HorarioModelo aModelo(Horarioentidad entidad) {
    return HorarioModelo(
      id: entidad.id,
      categoria: entidad.categoria,
      curso: entidad.curso,
      anio: entidad.anio,
      iterable: entidad.iterable,
      dia: entidad.dia,
      horaInicio: entidad.horaInicio,
      horaFin: entidad.horaFin,
      escenario: entidad.escenario,
    );
  }
}
