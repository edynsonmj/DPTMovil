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
  String? _correoAutenticado;
  String? _nombreAutenticado;

  AutenticacionViewModel();

  String? get correoAutenticado => _correoAutenticado ?? cuenta?.email;
  String? get nombreAutenticado => _nombreAutenticado ?? cuenta?.displayName;

  Future<void> verificarSesion() async {
    if (cuenta != null) {
      return;
    }
    try {
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        cuenta = account;
        _correoAutenticado = account.email;
        _nombreAutenticado = account.displayName;
        await login();
      }
    } catch (e) {
      error = 'Error al verificr la sesion: $e';
    }
  }

  // Para iniciar sesión:
  Future<bool> loginGoogle() async {
    error = null;
    try {
      cuenta = await _googleSignIn.signIn();
      if (cuenta != null) {
        _correoAutenticado = cuenta!.email;
        _nombreAutenticado = cuenta!.displayName;
        error = null;
        return true;
      } else {
        _correoAutenticado = null;
        _nombreAutenticado = null;
        error = null;
        return false;
      }
    } catch (e) {
      error =
          "el servicio de google no ha respondido apropiadamente: ${e.toString()}";
      return false;
    }
  }

  bool prepararLoginConCorreo(String email) {
    final correo = email.trim();
    if (correo.isEmpty) {
      error = 'Ingresa un correo para continuar';
      return false;
    }

    _correoAutenticado = correo;
    _nombreAutenticado = null;
    error = null;
    return true;
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    cuenta = null;
    perfilSesion = null;
    _correoAutenticado = null;
    _nombreAutenticado = null;
    notifyListeners();
  }

  Future<RespuestaModelo> login() async {
    try {
      final correo = correoAutenticado;
      if (correo == null || correo.isEmpty) {
        return RespuestaModelo.fromException(
          Exception('No hay un correo autenticado para iniciar sesion'),
          "GET",
          "login",
          "viewmodel",
        );
      }

      RespuestaModelo respuesta = await _servicio.login(correo);
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
