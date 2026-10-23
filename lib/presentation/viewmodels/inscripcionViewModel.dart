import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:flutter/material.dart';

//vm de la pantalla de inscripcion del alumno (ruta gruposDisponiblesInscripcion).
//Desde la fase 6 inscribir y desvincular devuelven Resultado: la vista decide
//que dialogo mostrar y ya no lee estado compartido por todas las tarjetas
class Inscripcionviewmodel with ChangeNotifier {
  final Servicioinscripcion _servicio;

  //el servicio sale de la raiz; el vm lo crea la ruta
  Inscripcionviewmodel(this._servicio);

  Future<Resultado<void>> agregarIncripcion(Inscripcionentidad entidad) async {
    try {
      RespuestaModelo respuesta = await _servicio.agregarInscripcion(entidad);
      if (respuesta.codigoHttp == 201) {
        //la tarjeta vuelve a validar y cambia el boton
        notifyListeners();
        return Exito();
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  Future<Resultado<void>> desvincularInscripcion(
    Inscripcionentidad entidad,
  ) async {
    try {
      RespuestaModelo respuesta = await _servicio.desvincularInscripcion(
        entidad,
      );
      if (respuesta.codigoHttp == 200) {
        notifyListeners();
        return Exito();
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
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

  //unico punto donde se lee el ErrorModelo: la vista recibe codigo y mensaje
  //ya resueltos y no necesita conocer la capa de datos
  Fallo<T> _fallo<T>(RespuestaModelo respuesta) {
    final error = respuesta.error;
    return Fallo(
      respuesta.codigoHttp,
      error?.mensaje ?? 'Error desconocido. Código: ${respuesta.codigoHttp}',
      origen: error == null ? null : '${error.metodo} ${error.url}',
    );
  }
}
