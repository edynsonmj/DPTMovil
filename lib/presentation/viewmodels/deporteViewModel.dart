import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioDeporte.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:flutter/foundation.dart';

//deportes del desplegable del formulario de curso. La ruta formularioCurso
//lo crea y carga una vez (..cargar()); la vista lee solo [deportes] con
//context.select. Antes el formulario guardaba el Future y leia el
//RespuestaModelo en un FutureBuilder (VM-b)
class Deporteviewmodel with ChangeNotifier, NotificacionSegura {
  final Serviciodeporte _serviciodeporte;

  //el servicio sale de la raiz; el vm lo crea la ruta formularioCurso
  Deporteviewmodel(this._serviciodeporte);

  EstadoSeccion<List<String>> _deportes = const EstadoSeccion([]);
  EstadoSeccion<List<String>> get deportes => _deportes;

  Future<void> cargar() async {
    _deportes = const EstadoSeccion([], cargando: true);
    notifyListeners();
    try {
      final respuesta = await obtenerDeportes();
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _deportes = EstadoSeccion((respuesta.datos as List).cast<String>());
      } else if (respuesta.codigoHttp == 204) {
        //sin deportes registrados no es un error: la vista lo dice
        _deportes = const EstadoSeccion([]);
      } else {
        _deportes = EstadoSeccion(
          const [],
          error:
              'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}',
        );
      }
    } catch (e) {
      _deportes = EstadoSeccion(const [], error: e.toString());
    }
    notifyListeners();
  }

  //la usan las pruebas remotas para tomar un deporte existente al sembrar
  //datos; ninguna vista la llama
  Future<RespuestaModelo> obtenerDeportes() async {
    return await _serviciodeporte.obtenerDeportes();
  }
}
