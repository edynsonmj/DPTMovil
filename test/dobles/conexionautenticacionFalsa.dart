import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAutenticacion.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de autenticacion: el test fija la
//respuesta de cada metodo y despues revisa lo que llego a la conexion
class ConexionautenticacionFalsa implements Conexionautenticacion {
  //respuesta que devuelve cada metodo; el test la fija antes de actuar
  RespuestaModelo respuestaLogin = RespuestaModelo(codigoHttp: 404);
  RespuestaModelo respuestaRegistro = RespuestaModelo(codigoHttp: 201);
  RespuestaModelo respuestaToken = RespuestaModelo(codigoHttp: 404);

  //lo que recibio, para comprobar que el repositorio armo bien la peticion
  String? ultimoCorreo;
  Perfilmodelo? ultimoRegistro;
  int llamadasLogin = 0;
  int llamadasRegistro = 0;
  String? ultimoIdToken;
  int llamadasToken = 0;


  @override
  Future<RespuestaModelo> login(String email) async {
    llamadasLogin++;
    ultimoCorreo = email;
    return respuestaLogin;
  }

  @override
  Future<RespuestaModelo> registro(Perfilmodelo modelo) async {
    llamadasRegistro++;
    ultimoRegistro = modelo;
    return respuestaRegistro;
  }

  @override
  Future<RespuestaModelo> intercambiarToken(String idTokenGoogle) async {
    llamadasToken++;
    ultimoIdToken = idTokenGoogle;
    return respuestaToken;
  }
}
