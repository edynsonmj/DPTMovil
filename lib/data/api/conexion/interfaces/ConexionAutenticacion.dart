import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionautenticacion {
  Future<RespuestaModelo> login(String email);

  Future<RespuestaModelo> registro(Perfilmodelo modelo);

  //cambia el ID Token de Google por el JWT del backend (POST /auth/token).
  //200 → Tokenmodelo; 404 → el correo no esta registrado; 401 → token invalido
  Future<RespuestaModelo> intercambiarToken(String idTokenGoogle);
}
