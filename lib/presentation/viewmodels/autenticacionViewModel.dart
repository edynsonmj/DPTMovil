import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AutenticacionViewModel with ChangeNotifier {
  final Servicioautenticacion _servicio = Servicioautenticacion();
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  GoogleSignInAccount? cuenta;
  PerfilEntidad? perfilSesion;
  String? error;

  AutenticacionViewModel() {}
  // Para iniciar sesión:
  Future<bool> loginGoogle() async {
    error = null;
    try {
      cuenta = await _googleSignIn.signIn();
      if (cuenta != null) {
        error = null;
        return true;
      } else {
        error = null;
        return false;
      }
    } catch (e) {
      error =
          "el servicio de google no ha respondido apropiadamente: ${e.toString()}";
      return false;
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    cuenta = null;
    perfilSesion = null;
    notifyListeners();
  }

  Future<RespuestaModelo> login() async {
    try {
      RespuestaModelo respuesta = await _servicio.login(cuenta!.email);
      if (respuesta.codigoHttp == 200 && respuesta.datos != null) {
        perfilSesion = respuesta.datos as PerfilEntidad;
        notifyListeners();
      }
      return respuesta;
    } on Exception catch (exception) {
      return RespuestaModelo.fromException(
        exception,
        "GET",
        "login",
        "viewmodel",
      );
    }
  }

  Future<RespuestaModelo> registroAlumno(PerfilEntidad entidad) async {
    try {
      RespuestaModelo respuesta = await _servicio.registro(entidad);
      if (respuesta.codigoHttp == 201) {
        perfilSesion = respuesta.datos as PerfilEntidad;
        notifyListeners();
      }
      return respuesta;
    } on Exception catch (exception) {
      return RespuestaModelo.fromException(
        exception,
        "POST",
        "Registro alumno",
        "View model",
      );
    }
  }
}
