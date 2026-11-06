class Perfilmodelo {
  String id;

  String nombre;

  String correo;

  String tipoId;

  String sexo;

  String? role;

  String? facultad;

  String? tipoAlumno;

  String? alumnoCodigo;

  String? programa;

  String? dependencia;

  Perfilmodelo({
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

  factory Perfilmodelo.fromJson(dynamic json) {
    return Perfilmodelo(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      tipoId: json['tipoId'],
      sexo: json['sexo'],
      tipoAlumno: json['tipoAlumno'],
      role: json['role'],
      facultad: json['facultad'],
      alumnoCodigo: json['alumnoCodigo'],
      programa: json['programa'],
      dependencia: json['dependencia'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'nombre': nombre,

      'correo': correo,

      'tipoId': tipoId,

      'sexo': sexo,

      'facultad': facultad,

      'tipoAlumno': tipoAlumno,

      'alumnoCodigo': alumnoCodigo,

      'programa': programa,

      'dependencia': dependencia,

      'role': role,
    };
  }
}
