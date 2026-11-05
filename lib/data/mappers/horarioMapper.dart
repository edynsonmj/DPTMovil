import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';

//conversion modelo -> entidad de horarios. Solo hay este sentido porque la
//app solo lista; el backend ya tiene POST, PUT y DELETE /horario (HO-04)
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
