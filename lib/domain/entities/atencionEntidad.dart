import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';

class Atencionentidad {
  String idPerfil;
  Alumnoentidad? alumno;
  int idClase;
  bool estaAtendido;
  Atencionentidad({
    required this.idPerfil,
    this.alumno,
    required this.idClase,
    required this.estaAtendido,
  });

  factory Atencionentidad.fromModelo(Atencionmodelo modelo) {
    return Atencionentidad(
      idPerfil: modelo.idPerfil,
      idClase: modelo.idClase,
      estaAtendido: modelo.estaAtendido,
    );
  }
}
