class Estadistica {
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

  Estadistica({
    required this.leyenda1,
    this.leyenda2,
    this.leyenda3,
    this.leyenda4,
    required this.clases,
    required this.horas,
    required this.minutos,
    required this.duracion,
  });
}
