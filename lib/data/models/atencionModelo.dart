import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';

class Atencionmodelo {
  Alumnomodelo alumno;
  int idClase;
  bool estaAtendido;
  Atencionmodelo({
    required this.alumno,
    required this.idClase,
    required this.estaAtendido,
  });

  factory Atencionmodelo.fromJson(dynamic json) {
    return Atencionmodelo(
      alumno: Alumnomodelo.fromJson(json['alumno']),
      idClase: json['idClase'],
      estaAtendido: json['estaAtendido'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'alumno': alumno.toJson(),
      'idClase': idClase,
      'estaAtendido': estaAtendido,
    };
  }
}
