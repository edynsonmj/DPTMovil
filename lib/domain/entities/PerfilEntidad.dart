class PerfilEntidad {
  String id;

  String nombre;

  String correo;

  String tipoId;

  String sexo;

  String? role;

  String? facultad;

  String? tipoAlumno;

  //datos segun el tipo de vinculo (backend 2026-11-02):
  //Estudiante: codigo + facultad + programa; Docente: facultad + programa;
  //Administrativo y Contratista: dependencia
  String? alumnoCodigo;

  String? programa;

  String? dependencia;

  PerfilEntidad({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.tipoId,
    required this.sexo,
    this.role,
    this.facultad,
    this.tipoAlumno,
    this.alumnoCodigo,
    this.programa,
    this.dependencia,
  });
}
