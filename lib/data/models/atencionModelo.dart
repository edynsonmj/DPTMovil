import 'package:dpt_movil/data/models/alumnoModelo.dart';

//asistencia de un alumno a una clase. La conexion arma la lista uniendo los
//alumnos del grupo con las marcas de la clase
class Atencionmodelo {
  Alumnomodelo alumno;
  int idClase;
  bool estaAtendido;
  Atencionmodelo({
    required this.alumno,
    required this.idClase,
    required this.estaAtendido,
  });

  //lee la forma que arma la conexion al unir un alumno del grupo con su marca
  //en la clase: {alumno, asistio}
  factory Atencionmodelo.fromJson(dynamic json, int idClase) {
    return Atencionmodelo(
      alumno: Alumnomodelo.fromJson(json['alumno']),
      idClase: idClase,
      estaAtendido: json['asistio'] == true,
    );
  }

  //escribe un ItemConfirmacionAsistenciaDto: el perfil del alumno y la marca;
  //la clase va en la url
  Map<String, dynamic> toJson() {
    return {'idPerfil': alumno.id, 'estaAtendido': estaAtendido};
  }
}
