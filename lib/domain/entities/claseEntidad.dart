import 'package:dpt_movil/data/models/claseModelo.dart';

class Claseentidad {
  int? codigo;
  String idGrupoCategoria;
  String idGrupoCurso;
  int idGrupoAnio;
  int idGrupoIterable;
  String idInstructor;
  DateTime? fecha;
  int? horas;
  int? minutos;
  String? observacion;
  int eliminado;

  Claseentidad({
    this.codigo,
    required this.idGrupoCategoria,
    required this.idGrupoCurso,
    required this.idGrupoAnio,
    required this.idGrupoIterable,
    required this.idInstructor,
    this.fecha,
    this.horas,
    this.minutos,
    this.observacion,
    required this.eliminado,
  });

  factory Claseentidad.fromModelo(Clasemodelo modelo) {
    return Claseentidad(
      codigo: modelo.codigo,
      idGrupoCategoria: modelo.idGrupoCategoria,
      idGrupoCurso: modelo.idGrupoCurso,
      idGrupoAnio: modelo.idGrupoAnio,
      idGrupoIterable: modelo.idGrupoIterable,
      idInstructor: modelo.idInstructor,
      fecha: modelo.fecha,
      horas: modelo.horas,
      minutos: modelo.minutos,
      observacion: modelo.observacion,
      eliminado: modelo.eliminado,
    );
  }
}
