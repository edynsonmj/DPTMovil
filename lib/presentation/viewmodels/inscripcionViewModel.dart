import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:flutter/material.dart';

class Inscripcionviewmodel with ChangeNotifier {
  final Servicioinscripcion _servicio = Servicioinscripcion();

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  int? _codigoInsercion;
  int? get codigoInsercion => _codigoInsercion;

  Future<void> agregarIncripcion(Inscripcionentidad entidad) async {
    try {
      _error = null;
      _cargando = true;
      _codigoInsercion = 0;
      notifyListeners();
      RespuestaModelo respuesta = await _servicio.agregarInscripcion(entidad);
      _cargando = false;
      if (respuesta.codigoHttp == 201) {
        _codigoInsercion = 201;
      } else {
        _codigoInsercion = respuesta.codigoHttp;
        _error = '${respuesta.error?.mensaje}';
      }
    } on Exception catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }

  Future<int> desvincularInscripcion(Inscripcionentidad entidad) async {
    try {
      RespuestaModelo respuesta = await _servicio.desvincularInscripcion(
        entidad,
      );
      notifyListeners();
      return respuesta.codigoHttp;
    } catch (e) {
      notifyListeners();
      return 0;
    }
  }

  Future<bool> validarInscripcion(Inscripcionentidad entidad) async {
    try {
      RespuestaModelo respuesta = await _servicio.validarInscripcion(entidad);
      if (respuesta.codigoHttp == 200) {
        return respuesta.datos as bool;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
