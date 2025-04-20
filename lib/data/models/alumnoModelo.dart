class Alumnomodelo {
  int? eliminadoestado;
  String id;
  String? codigo;
  String tipo;
  String nombre;
  String correo;
  String sexo;
  String tipoid;
  int? imagen;

  Alumnomodelo({
    this.eliminadoestado,
    required this.id,
    this.codigo,
    required this.tipo,
    required this.nombre,
    required this.correo,
    required this.sexo,
    required this.tipoid,
    this.imagen,
  });

  factory Alumnomodelo.fromJson(dynamic json) {
    return Alumnomodelo(
      id: json['id'],
      tipo: json['tipo'],
      nombre: json['nombre'],
      correo: json['correo'],
      sexo: json['sexo'],
      tipoid: json['tipoid'],
      eliminadoestado: json['eliminadoestado'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'eliminadoestado': 0,
      'id': id,
      'codigo': codigo,
      'tipo': tipo,
      'nombre': nombre,
      'correo': correo,
      'sexo': sexo,
      'tipoid': tipoid,
      'imagen': imagen,
    };
  }
}
