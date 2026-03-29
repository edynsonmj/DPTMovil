class Atencionmodelo {
  String idPerfil;
  int idClase;
  bool estaAtendido;
  Atencionmodelo({
    required this.idPerfil,
    required this.idClase,
    required this.estaAtendido,
  });

  factory Atencionmodelo.fromJson(dynamic json) {
    return Atencionmodelo(
      idPerfil: json['idPerfil'],
      idClase: json['idClase'],
      estaAtendido: json['estaAtendido'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idPerfil': idPerfil,
      'idClase': idClase,
      'estaAtendido': estaAtendido,
    };
  }
}
