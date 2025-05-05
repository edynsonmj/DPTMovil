import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/presentation/view/views/grupo/grupo.dart';
import 'package:flutter/foundation.dart';

class Grupoentidad {
  String categoria;
  String curso;
  int anio;
  int iterable;
  int? imagen;
  String? idInstructor;
  int cupos;
  String? estado;
  String fechaCreacion;
  String? fechaFinalizacion;

  Grupoentidad({
    required this.categoria,
    required this.curso,
    required this.anio,
    required this.iterable,
    this.imagen,
    this.idInstructor,
    required this.cupos,
    this.estado,
    required this.fechaCreacion,
    this.fechaFinalizacion,
  });

  factory Grupoentidad.fromModelo(GrupoModelo grupo) {
    return Grupoentidad(
      categoria: grupo.cat_titulo,
      curso: grupo.cur_nombre,
      anio: grupo.anio,
      iterable: grupo.iterable,
      imagen: grupo.imagen,
      cupos: grupo.cupos,
      estado: grupo.estado,
      fechaCreacion: grupo.fechaCreacion,
      fechaFinalizacion: grupo.fechaFinalizacion,
      idInstructor: grupo.idInstructor,
    );
  }
}
