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
  //periodo de inscripcion (yyyy-MM-dd); lo fija el coordinador al abrir o
  //cerrar inscripciones. Null = nunca se abrio
  String? fechaInscripcionApertura;
  String? fechaInscripcionCierre;

  //la clave del cierre en el json del backend lleva una errata (falta la
  //"s"): se aisla aqui para que el resto de la app use el nombre correcto
  static const String claveCierreInscripcion = 'fechaIncripcionCierre';

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
    this.fechaInscripcionApertura,
    this.fechaInscripcionCierre,
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
      fechaInscripcionApertura: json['fechaInscripcionApertura'],
      fechaInscripcionCierre: json[claveCierreInscripcion],
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
      'categoria': cat_titulo,
      'curso': cur_nombre,
      'anio': anio,
      'iterable': iterable,
      'imagenGrupo': imagen,
      'idInstructor': idInstructor,
      'cupos': cupos,
      'fechaCreacion': fechaCreacion,
    };
  }
}
