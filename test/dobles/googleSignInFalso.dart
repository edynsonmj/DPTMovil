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
  //si se fija, signOut lanza este error (p. ej. un PlatformException del
  //plugin) despues de contar la llamada
  Object? errorAlSalir;

  //como el plugin real: despues de signOut, signInSilently ya no devuelve
  //la cuenta hasta que se vuelva a elegir con signIn
  bool _salio = false;

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async {
    llamadasSilencioso++;
    return _salio ? null : cuenta;
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    _salio = false;
    return cuenta;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    llamadasSalir++;
    if (errorAlSalir != null) throw errorAlSalir!;
    _salio = true;
    return null;
  }
}

//cuenta de Google de prueba. idToken es lo que entregaria Google con el
//serverClientId configurado; null = sin client ID web (Android no lo da)
class CuentaGoogleFalsa extends Fake implements GoogleSignInAccount {
  @override
  final String email;
  @override
  final String? displayName;
  final String? idToken;

  CuentaGoogleFalsa({
    required this.email,
    this.displayName,
    this.idToken = 'id-token-de-google',
  });

  @override
  String? get photoUrl => null;

  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _AutenticacionGoogleFalsa(idToken);
}

class _AutenticacionGoogleFalsa extends Fake
    implements GoogleSignInAuthentication {
  @override
  final String? idToken;

  _AutenticacionGoogleFalsa(this.idToken);
}
