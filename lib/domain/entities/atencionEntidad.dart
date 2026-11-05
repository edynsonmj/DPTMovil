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
}
