import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioImagen.dart';
import 'package:flutter/material.dart';

class Imagenviewmodel with ChangeNotifier {
  Servicioimagen _servicioImagen = Servicioimagen();

  bool _cargando = false;
  bool get cargando => _cargando;

  ImagenEntidad? _imagen;
  ImagenEntidad? get imagen => _imagen;

  String? _error;
  String? get error => _error;

  Imagenviewmodel();

  Future<void> obtenerImagen(int idImagen) async {
    _cargando = true;
    _error = null;
    notifyListeners();

    try {
      final respuesta = await _servicioImagen.obtenerImagen(idImagen);
      if (respuesta.codigoHttp == 200) {
        print(respuesta.datos.runtimeType);
        print(respuesta.datos.toString());
        _imagen = respuesta.datos as ImagenEntidad;
      } else {
        _error =
            'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
        _imagen = null;
      }
    } catch (e) {
      _error = 'capa: viewModel -> ${e.toString()}';
      _imagen = null;
    }
    _cargando = false;
    notifyListeners();
  }
}
