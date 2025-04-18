import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:flutter/foundation.dart';

class Horariosviewmodel with ChangeNotifier {
  late final Serviciohorario servicioHorario;

  Horariosviewmodel() : servicioHorario = Serviciohorario();

  Future<RespuestaModelo> listarHorariosGrupo(
    String categoria,
    String curso,
    int anio,
    int iterable,
  ) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioHorario.listarHoariosGrupo(
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
        'ObtenerHoariosGrupo',
        'ViewModel',
      );
    }
  }
}
