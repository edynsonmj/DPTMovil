class EstadisticaModelo {
  ///titulo de la estadistica
  String leyenda1;
  String? leyenda2;
  String? leyenda3;
  String? leyenda4;

  ///cantidad de clases
  double clases;

  ///cantidad de horas
  double horas;

  ///minutos excedentes de horas
  double minutos;

  ///duracion total en minutos
  double duracion;

  EstadisticaModelo({
    required this.leyenda1,
    this.leyenda2,
    this.leyenda3,
    this.leyenda4,
    required this.clases,
    required this.horas,
    required this.minutos,
    required this.duracion,
  });

  factory EstadisticaModelo.fromJson(dynamic json) {
    return EstadisticaModelo(
      leyenda1: json['leyenda1'],
      leyenda2: json['leyenda2'],
      leyenda3: json['leyenda3'],
      leyenda4: json['leyenda4'],
      clases: json['clases'],
      horas: json['horas'],
      minutos: json['minutos'],
      duracion: json['duracion'],
    );
  }
}
