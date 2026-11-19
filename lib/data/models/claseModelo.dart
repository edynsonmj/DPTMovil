import 'package:dpt_movil/config/formatDate.dart';

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
  String? justificacion;
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
    this.justificacion,
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
      justificacion: json['justificacion'],
      eliminado: json['eliminado'],
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

      //solo el dia elegido: el backend recibe un LocalDate. Con la hora en UTC,
      //desde las 19:00 locales la clase caia en el dia siguiente (CL-07)
      'fecha': FormatDate.fechaACadena(fecha, '-'),

      'horas': horas,

      'minutos': minutos,

      'observacion': observacion,

      'eliminado': eliminado,

      //solo si hay: el backend la exige cuando el grupo no tiene horario ese
      //dia y la ignora cuando lo tiene (BK-04)
      if (justificacion != null) 'justificacion': justificacion,
    };
  }
}
