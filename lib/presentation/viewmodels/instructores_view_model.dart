import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

class InstructoresViewModel with ChangeNotifier, NotificacionSegura {
  final ServicioInstructor _servicioInstructor;

  List<Instructorentidad> _instructores = [];
  List<Instructorentidad> get instructores => _instructores;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  //el servicio sale de la raiz; el vm lo crean las rutas grupoFormulario e
  //instructores y se desecha al salir: una carga que llega despues no
  //notifica (NotificacionSegura, IT-02)
  InstructoresViewModel(this._servicioInstructor);

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
