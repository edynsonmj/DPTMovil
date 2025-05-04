import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:flutter/material.dart';

class Perfilmodelo {
  String id;

  String nombre;

  String correo;

  String tipoId;

  String sexo;

  String? role;

  String? facultad;

  String? tipoAlumno;

  Perfilmodelo({
    required this.id,
    required this.nombre,
    required this.correo,
    required this.tipoId,
    required this.sexo,
    this.role,
    this.facultad,
    this.tipoAlumno,
  });

  factory Perfilmodelo.fromEntidad(PerfilEntidad entidad) {
    return Perfilmodelo(
      id: entidad.id,
      nombre: entidad.nombre,
      correo: entidad.correo,
      tipoId: entidad.tipoId,
      sexo: entidad.sexo,
      facultad: entidad.facultad,
      tipoAlumno: entidad.tipoAlumno,
      role: entidad.role,
    );
  }

  factory Perfilmodelo.fromJson(dynamic json) {
    return Perfilmodelo(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      tipoId: json['tipoId'],
      sexo: json['sexo'],
      tipoAlumno: json['tipoAlumno'],
      role: json['role'],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      'id': id,

      'nombre': nombre,

      'correo': correo,

      'tipoId': tipoId,

      'sexo': sexo,

      'facultad': facultad,

      'tipoAlumno': tipoAlumno,

      'role': role,
    };
  }
}
