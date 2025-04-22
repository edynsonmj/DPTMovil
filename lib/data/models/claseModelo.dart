import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:flutter/material.dart';

class Clasemodelo {
  int? codigo;
  String idGrupoCategoria;
  String idGrupoCurso;
  int idGrupoAnio;
  int idGrupoIterable;
  String idInstructor;
  DateTime fecha;
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
      fecha: DateTime.parse(json['fecha']),
      horas: json['horas'],
      minutos: json['minutos'],
      observacion: json['observacion'],
      eliminado: json['eliminado'],
    );
  }

  factory Clasemodelo.fromEntidad(Claseentidad entidad) {
    return Clasemodelo(
      idGrupoCategoria: entidad.idGrupoCategoria,
      idGrupoCurso: entidad.idGrupoCurso,
      idGrupoAnio: entidad.idGrupoAnio,
      idGrupoIterable: entidad.idGrupoIterable,
      idInstructor: entidad.idInstructor,
      fecha: entidad.fecha!,
      horas: entidad.horas!,
      minutos: entidad.minutos!,
      eliminado: entidad.eliminado,
      codigo: entidad.codigo,
      observacion: entidad.observacion,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'codigo': codigo,
      'idGrupoCategoria': idGrupoCategoria,

      'idGrupoCurso': idGrupoCurso,

      'idGrupoAnio': idGrupoAnio,

      'idGrupoIterable': idGrupoIterable,

      'idInstructor': idInstructor,

      'fecha': fecha.toIso8601String(),

      'horas': horas,

      'minutos': minutos,

      'observacion': observacion,

      'eliminado': eliminado,
    };
  }
}
