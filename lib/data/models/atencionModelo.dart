import 'package:dpt_movil/data/models/alumnoModelo.dart';

//asistencia de un alumno a una clase. El backend (/asistenciasClase) no
//repite la clase en cada elemento: la conexion la pasa al leer
class Atencionmodelo {
  Alumnomodelo alumno;
  int idClase;
  bool estaAtendido;
  Atencionmodelo({
    required this.alumno,
    required this.idClase,
    required this.estaAtendido,
  });

  //lee un AsistenciaAlumnoDto: {alumno, asistio}
  factory Atencionmodelo.fromJson(dynamic json, int idClase) {
    return Atencionmodelo(
      alumno: Alumnomodelo.fromJson(json['alumno']),
      idClase: idClase,
      estaAtendido: json['asistio'],
    );
  }

  //escribe un RegistroAsistenciaDto: el backend solo necesita el perfil del
  //alumno y la marca, la clase va en la url
  Map<String, dynamic> toJson() {
    return {'idPerfil': alumno.id, 'asistio': estaAtendido};
  }
}
