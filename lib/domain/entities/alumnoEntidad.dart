import 'package:dpt_movil/data/models/alumnoModelo.dart';

class Alumnoentidad {
  String id;
  String? codigo;
  String tipo;
  String nombre;
  String correo;
  String sexo;
  String tipoid;
  int? imagen;

  Alumnoentidad({
    required this.id,
    this.codigo,
    required this.tipo,
    required this.nombre,
    required this.correo,
    required this.sexo,
    required this.tipoid,
    this.imagen,
  });

  factory Alumnoentidad.fromModelo(Alumnomodelo modelo) {
    return Alumnoentidad(
      id: modelo.id,
      tipo: modelo.tipo,
      nombre: modelo.nombre,
      correo: modelo.correo,
      sexo: modelo.sexo,
      tipoid: modelo.tipoid,
      codigo: modelo.codigo,
      imagen: modelo.imagen,
    );
  }
}
