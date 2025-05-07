import 'package:dpt_movil/data/models/instructorModelo.dart';

class Instructorentidad {
  String id;
  String? nombre;
  String? correo;
  String? sexo;

  Instructorentidad({required this.id, this.nombre, this.correo, this.sexo});

  factory Instructorentidad.fromModelo(Instructormodelo modelo) {
    return Instructorentidad(
      id: modelo.id,
      nombre: modelo.nombre,
      correo: modelo.correo,
      sexo: modelo.sexo,
    );
  }
}
