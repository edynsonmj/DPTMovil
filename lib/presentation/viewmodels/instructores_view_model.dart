import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:flutter/material.dart';

class InstructoresViewModel with ChangeNotifier {
  final ServicioInstructor _servicioInstructor = ServicioInstructor();

  List<Instructorentidad> _instructores = [];
  List<Instructorentidad> get instructores => _instructores;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  InstructoresViewModel();

  Future<void> listarYNotificarInstructores() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final respuesta = await _servicioInstructor.listarInstructores();
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _instructores = respuesta.datos as List<Instructorentidad>;
      } else {
        _error =
            'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
        _instructores = [];
      }
    } catch (e) {
      _error = e.toString();
      _instructores = [];
    }
    _cargando = false;
    notifyListeners();
  }
}
