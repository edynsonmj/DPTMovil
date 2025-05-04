import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:flutter/material.dart';

class Facultadesviewmodel with ChangeNotifier {
  final Serviciofacultades _servicio = Serviciofacultades();

  List<String> _facultades = [];
  List<String> get facultades => _facultades;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  Facultadesviewmodel();

  Future<void> listarYNotificarFacultades() async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final respuesta = await _servicio.listarFacultades();
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _facultades = (respuesta.datos as List<String>);
      } else {
        _error =
            'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
        _facultades = [];
      }
    } catch (e) {
      _error = e.toString();
      _facultades = [];
    }

    _cargando = false;
    notifyListeners();
  }
}
