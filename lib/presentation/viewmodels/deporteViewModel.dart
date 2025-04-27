import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioDeporte.dart';
import 'package:flutter/material.dart';

class Deporteviewmodel with ChangeNotifier {
  final Serviciodeporte _serviciodeporte = Serviciodeporte();

  Future<RespuestaModelo> obtenerDeportes() async {
    return await _serviciodeporte.obtenerDeportes();
  }
}
