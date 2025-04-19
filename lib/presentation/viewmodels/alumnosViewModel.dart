import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:flutter/material.dart';

class Alumnosviewmodel with ChangeNotifier {
  final Servicioalumno _servicioAlumno;
  Alumnosviewmodel() : _servicioAlumno = Servicioalumno();

  Future<RespuestaModelo> listarAlumnosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await _servicioAlumno.listarAlumnosGrupo(
        categoria,
        curso,
        anio,
        iterable,
      );
      return respuesta;
    } on Exception catch (e) {
      return RespuestaModelo.fromException(
        e,
        'GET',
        'ObtenerAlumnosGrupo',
        'ViewModel',
      );
    }
  }
}
