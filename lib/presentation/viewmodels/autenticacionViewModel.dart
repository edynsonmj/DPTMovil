import 'dart:convert';

import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AutenticacionViewModel with ChangeNotifier {
  //unico vm global (la sesion la leen el menu lateral y casi todas las
  //pantallas). Ambas dependencias llegan desde la raiz: el servicio y el
  //cliente de Google, que en los tests se reemplaza por un doble
  final Servicioautenticacion _servicio;
  final GoogleSignIn _googleSignIn;

  GoogleSignInAccount? cuenta;
  PerfilEntidad? perfilSesion;
  String? error;
  String? _correoAutenticado;
  String? _nombreAutenticado;

  AutenticacionViewModel(this._servicio, this._googleSignIn);

  String? get correoAutenticado => _correoAutenticado ?? cuenta?.email;
  String? get nombreAutenticado => _nombreAutenticado ?? cuenta?.displayName;
  String? get fotoPerfil => cuenta?.photoUrl;

  //valor de la cabecera Authorization para lo que no pasa por el Dio
  String? get autorizacion {
    final token = _servicio.tokenSesion;
    return token == null ? null : 'Bearer $token';
  }

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
        print("PHOTO URL: ${cuenta!.photoUrl}");
        print(" Login exitoso");
        print("Email: ${cuenta!.email}");
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
    //primero el JWT: sin el, ninguna peticion sale autenticada
    _servicio.cerrarSesion();
    await _googleSignIn.signOut();
    //await _googleSignIn.disconnect();
    cuenta = null;
    perfilSesion = null;
    _correoAutenticado = null;
    _nombreAutenticado = null;
    notifyListeners();
  }

  //con cuenta de Google: el backend exige su ID Token (POST /auth/token) y
  //devuelve el perfil y el JWT de la sesion. Solo con correo: GET /login,
  //que el backend nuevo rechaza con 401 sin JWT (AU-B01)
  Future<RespuestaModelo> login() async {
    final cuentaGoogle = cuenta;
    if (cuentaGoogle != null) {
      return _loginConGoogle(cuentaGoogle);
    }
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

  Future<RespuestaModelo> _loginConGoogle(GoogleSignInAccount cuentaGoogle) async {
    try {
      final idToken = (await cuentaGoogle.authentication).idToken;
      if (idToken == null || idToken.isEmpty) {
        return RespuestaModelo.fromException(
          Exception('Google no entrego el ID Token: revisa el serverClientId'),
          "POST",
          "auth/token",
          "viewmodel",
        );
      }
      RespuestaModelo respuesta = await _servicio.iniciarSesionConGoogle(idToken);
      if (respuesta.codigoHttp == 200 && respuesta.datos != null) {
        perfilSesion = respuesta.datos as PerfilEntidad;
        notifyListeners();
      }
      return respuesta;
    } on Exception catch (exception) {
      return RespuestaModelo.fromException(
        exception,
        "POST",
        "auth/token",
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
        //el registro es publico y no da JWT: con Google se pide ahora, para
        //que las pantallas del alumno no respondan 401
        if (cuenta != null) {
          await login();
        }
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

  //mensaje legible de un registro rechazado. El backend responde 422
  //{codigoError, mensaje} si faltan datos del tipo de vinculo, 400 con un
  //mensaje por campo si falla la validacion, 409 si la identificacion ya existe
  String mensajeErrorRegistro(RespuestaModelo respuesta) {
    final texto = respuesta.error?.mensaje;
    if (texto != null && texto.isNotEmpty) {
      try {
        final cuerpo = jsonDecode(texto);
        if (cuerpo is Map) {
          final mensaje = cuerpo['mensaje'];
          if (mensaje is String && mensaje.isNotEmpty) {
            //"Los datos enviados no son validos, <motivo>": se deja el motivo
            final coma = mensaje.indexOf(', ');
            return coma >= 0 && mensaje.startsWith('Los datos enviados')
                ? mensaje.substring(coma + 2)
                : mensaje;
          }
          final campos = cuerpo.values.whereType<String>().toList();
          if (campos.isNotEmpty) return campos.join('\n');
        }
      } on FormatException {
        //no es JSON: se usa el mensaje por codigo
      }
    }
    switch (respuesta.codigoHttp) {
      case 409:
        return 'Ya existe un perfil con esa identificacion o correo';
      case 503:
        return 'No hay conexion con el servidor';
      case 408:
        return 'El servidor tardo demasiado en responder';
      default:
        return 'No se pudo completar el registro (${respuesta.codigoHttp})';
    }
  }
}
