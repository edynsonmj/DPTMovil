//programa academico de GET /programas?facultad= : [{nombre, facultad}]
class Programamodelo {
  String nombre;
  String? facultad;
  Programamodelo({required this.nombre, this.facultad});

  factory Programamodelo.fromJson(dynamic json) {
    return Programamodelo(nombre: json['nombre'], facultad: json['facultad']);
  }
}
