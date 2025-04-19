import 'package:flutter/material.dart';

class Clasemodelo {
  int? codigo;
  String idGrupoCategoria;
  String idGrupoCurso;
  int idGrupoAnio;
  int idGrupoIterable;
  String idInstructor;
  String fecha;
  int horas;
  int minutos;
  String? observacion;
  int eliminado;

  Clasemodelo({
    this.codigo,
    required this.idGrupoCategoria,
    required this.idGrupoCurso,
    required this.idGrupoAnio,
    required this.idGrupoIterable,
    required this.idInstructor,
    required this.fecha,
    required this.horas,
    required this.minutos,
    this.observacion,
    required this.eliminado,
  });

  factory Clasemodelo.fromJson(dynamic json) {
    return Clasemodelo(
      codigo: json['codigo'],
      idGrupoCategoria: json['idGrupoCategoria'],
      idGrupoCurso: json['idGrupoCurso'],
      idGrupoAnio: json['idGrupoAnio'],
      idGrupoIterable: json['idGrupoIterable'],
      idInstructor: json['idInstructor'],
      fecha: json['fecha'],
      horas: json['horas'],
      minutos: json['minutos'],
      observacion: json['observacion'],
      eliminado: json['eliminado'],
    );
  }
}
