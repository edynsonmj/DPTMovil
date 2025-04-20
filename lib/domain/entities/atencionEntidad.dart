import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';

class Atencionentidad {
  Alumnoentidad alumno;
  int idClase;
  bool estaAtendido;
  Atencionentidad({
    required this.alumno,
    required this.idClase,
    required this.estaAtendido,
  });

  factory Atencionentidad.fromModelo(Atencionmodelo modelo) {
    return Atencionentidad(
      alumno: Alumnoentidad.fromModelo(modelo.alumno),
      idClase: modelo.idClase,
      estaAtendido: modelo.estaAtendido,
    );
  }
}
