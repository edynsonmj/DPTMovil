import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

//doble del cliente de Google: en un test no hay plugin nativo, asi que el
//GoogleSignIn real fallaria con MissingPluginException. Este no tiene
//cuenta guardada (signInSilently devuelve null) y registra las llamadas.
//Los metodos no sobrescritos lanzan UnimplementedError (Fake)
class GoogleSignInFalso extends Fake implements GoogleSignIn {
  //cuenta que devuelven signIn y signInSilently; null = sin sesion de Google
  GoogleSignInAccount? cuenta;
  int llamadasSilencioso = 0;
  int llamadasSalir = 0;

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async {
    llamadasSilencioso++;
    return cuenta;
  }

  @override
  Future<GoogleSignInAccount?> signIn() async => cuenta;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    llamadasSalir++;
    return null;
  }
}
