import 'package:dpt_movil/data/models/imagenModelo.dart';

class GrupoModelo {
  String cat_titulo;
  String cur_nombre;
  int anio;
  int iterable;
  int? imagen;
  String? idInstructor;
  int cupos;
  String? estado;
  String fechaCreacion;
  String? fechaFinalizacion;

  GrupoModelo({
    required this.cat_titulo,
    required this.cur_nombre,
    required this.anio,
    required this.iterable,
    this.imagen,
    required this.cupos,
    this.estado,
    required this.fechaCreacion,
    this.fechaFinalizacion,
    this.idInstructor,
  });

  factory GrupoModelo.fromJson(dynamic json) {
    return GrupoModelo(
      cat_titulo: json['categoria'],
      cur_nombre: json['curso'],
      anio: json['anio'],
      iterable: json['iterable'],
      cupos: json['cupos'],
      estado: json['estado'],
      fechaCreacion: json['fechaCreacion'],
      imagen: json['imagenGrupo'],
      idInstructor: json['idInstructor'],
      fechaFinalizacion:
          (json['fechaFinalizacion'] != null)
              ? json['fechaFinalizacion']
              : null,
    );
  }
}
