import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:flutter/material.dart';

class Clasesviewmodel with ChangeNotifier {
  final Servicioclase _servicioClase;
  Clasesviewmodel() : _servicioClase = Servicioclase();

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
