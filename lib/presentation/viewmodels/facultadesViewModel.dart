import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

class Facultadesviewmodel extends ChangeNotifier with NotificacionSegura {
  //el servicio llega desde la raiz; el vm se crea por ruta
  //(autenticacionRegistro), solo lo usa la pantalla de registro
  final Serviciofacultades _servicio;

  List<String> _facultades = [];
  List<String> get facultades => _facultades;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  //programas de la facultad elegida (Estudiante y Docente los necesitan)
  EstadoSeccion<List<String>> _programas = const EstadoSeccion([]);
  EstadoSeccion<List<String>> get programas => _programas;

  //descarta la respuesta de una facultad que ya no es la elegida
  int _peticionProgramas = 0;

  Facultadesviewmodel(this._servicio);

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

  Future<void> listarProgramas(String facultad) async {
    final peticion = ++_peticionProgramas;
    _programas = const EstadoSeccion([], cargando: true);
    notifyListeners();

    final respuesta = await _servicio.listarProgramas(facultad);
    if (peticion != _peticionProgramas) return;
    if (respuesta.codigoHttp == 200 && respuesta.datos is List<String>) {
      _programas = EstadoSeccion(respuesta.datos as List<String>);
    } else {
      _programas = EstadoSeccion(
        const [],
        error:
            'No se pudieron cargar los programas (${respuesta.codigoHttp})',
      );
    }
    notifyListeners();
  }
}
