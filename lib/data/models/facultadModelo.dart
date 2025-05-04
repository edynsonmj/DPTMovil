class Facultadmodelo {
  String nombre;
  Facultadmodelo({required this.nombre});

  factory Facultadmodelo.fromJson(dynamic json) {
    return Facultadmodelo(nombre: json['nombre']);
  }

  dynamic toJson() {
    return {"nombre": nombre};
  }
}
