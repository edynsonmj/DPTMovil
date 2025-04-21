import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:flutter/material.dart';

class Clasesviewmodel with ChangeNotifier {
  final Servicioclase _servicioClase;
  Clasesviewmodel() : _servicioClase = Servicioclase();

  Future<RespuestaModelo> eliminarClase(int id) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await _servicioClase.eliminarClase(id);
      return respuesta;
    } on Exception catch (e) {
      //_mostrarError(context, "fallo al registrar", null);
      return RespuestaModelo.fromException(e, "Delete", "/clase", "viewmodel");
    }
  }

  Future<RespuestaModelo> guardarClaseGrupo(Claseentidad entidad) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await _servicioClase.guardarClaseGrupo(entidad);
      return respuesta;
    } on Exception catch (e) {
      //_mostrarError(context, "fallo al registrar", null);
      return RespuestaModelo.fromException(
        e,
        "POST",
        "agregar clase",
        "viewmodel",
      );
    }
  }

  Future<RespuestaModelo> listarClasesGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await _servicioClase.listarClasesGrupo(
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
        'ListarClasesGrupo',
        'ViewModel',
      );
    }
  }
}
