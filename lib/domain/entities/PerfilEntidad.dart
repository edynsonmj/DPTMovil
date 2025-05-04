import 'package:dpt_movil/data/models/perfilModelo.dart';

class PerfilEntidad {
  String id;

  String nombre;

  String correo;

  String tipoId;

  String sexo;

  String? role;

  String? facultad;

  String? tipoAlumno;

  PerfilEntidad({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.tipoId,
    required this.sexo,
    this.role,
    this.facultad,
    this.tipoAlumno,
  });

  factory PerfilEntidad.fromModelo(Perfilmodelo modelo) {
    return PerfilEntidad(
      id: modelo.id,
      nombre: modelo.nombre,
      correo: modelo.correo,
      tipoId: modelo.tipoId,
      sexo: modelo.sexo,
      role: modelo.role,
      facultad: modelo.facultad,
      tipoAlumno: modelo.tipoAlumno,
    );
  }
}
