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
}
