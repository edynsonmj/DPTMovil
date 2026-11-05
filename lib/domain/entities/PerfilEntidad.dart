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
}
