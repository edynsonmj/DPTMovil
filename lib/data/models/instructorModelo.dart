class Instructormodelo {
  String id;
  String? nombre;
  String? correo;
  String? sexo;
  Instructormodelo({required this.id, this.nombre, this.correo, this.sexo});

  factory Instructormodelo.fromJson(dynamic json) {
    return Instructormodelo(
      id: json['id'],
      nombre: json['nombre'],
      sexo: json['sexo'],
      correo: json['correo'],
    );
  }
}
