import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';

//conversion modelo -> entidad de estadisticas. Solo hay este sentido: las
//estadisticas solo se consultan
class EstadisticaMapper {
  static Estadistica aEntidad(EstadisticaModelo modelo) {
    return Estadistica(
      leyenda1: modelo.leyenda1,
      leyenda2: modelo.leyenda2,
      leyenda3: modelo.leyenda3,
      leyenda4: modelo.leyenda4,
      clases: modelo.clases,
      horas: modelo.horas,
      minutos: modelo.minutos,
      duracion: modelo.duracion,
    );
  }

  static List<Estadistica> aEntidades(List<EstadisticaModelo> modelos) =>
      modelos.map(aEntidad).toList();
}
