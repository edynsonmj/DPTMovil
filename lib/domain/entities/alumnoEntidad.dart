class Alumnoentidad {
  String id;
  String? codigo;
  String tipo;
  String nombre;
  String correo;
  String sexo;
  String tipoid;
  int? imagen;

  Alumnoentidad({
    required this.id,
    this.codigo,
    required this.tipo,
    required this.nombre,
    required this.correo,
    required this.sexo,
    required this.tipoid,
    this.imagen,
  });
}
