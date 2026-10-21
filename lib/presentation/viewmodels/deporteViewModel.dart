import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioDeporte.dart';
import 'package:flutter/material.dart';

class Deporteviewmodel with ChangeNotifier {
  final Serviciodeporte _serviciodeporte;

  //el servicio sale de la raiz; el vm lo crea la ruta formularioCurso
  Deporteviewmodel(this._serviciodeporte);

  Future<RespuestaModelo> obtenerDeportes() async {
    return await _serviciodeporte.obtenerDeportes();
  }
}
