import 'package:dpt_movil/data/models/perfilModelo.dart';

//respuesta de POST /auth/token (TokenResponseDto): el JWT propio del
//backend y el perfil del correo del ID Token de Google
class Tokenmodelo {
  String token;
  Perfilmodelo perfil;

  Tokenmodelo({required this.token, required this.perfil});

  factory Tokenmodelo.fromJson(dynamic json) {
    return Tokenmodelo(
      token: json['token'],
      perfil: Perfilmodelo.fromJson(json['perfil']),
    );
  }
}
