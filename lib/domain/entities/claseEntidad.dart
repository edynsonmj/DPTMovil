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
  //obligatoria para el backend solo si el grupo no tiene horario ese dia (BK-04)
  String? justificacion;
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
    this.justificacion,
    required this.eliminado,
  });
}
