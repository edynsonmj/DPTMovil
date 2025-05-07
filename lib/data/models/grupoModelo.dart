import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';

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

  factory GrupoModelo.fromEntidad(Grupoentidad entidad) {
    return GrupoModelo(
      cat_titulo: entidad.categoria,
      cur_nombre: entidad.curso,
      anio: entidad.anio,
      iterable: entidad.iterable,
      cupos: entidad.cupos,
      fechaCreacion: entidad.fechaCreacion,
      idInstructor: entidad.idInstructor,
      imagen: entidad.imagen,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cat_titulo': cat_titulo,
      'cur_nombre': cur_nombre,
      'anio': anio,
      'iterable': iterable,
      'imagen': imagen,
      'idInstructor': idInstructor,
      'cupos': cupos,
      'fechaCreacion': fechaCreacion,
    };
  }
}
