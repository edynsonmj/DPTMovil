import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAutenticacion.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/mappers/perfilMapper.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/models/tokenModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';

class Autenticacionrepositorio {
  Conexionautenticacion conexion;
  //el JWT de la sesion; lo envia InterceptorToken en cada peticion del Dio
  //compartido. Ni el dominio ni la vista lo ven
  final AlmacenToken almacenToken;

  Autenticacionrepositorio({required this.conexion, required this.almacenToken});

  Future<RespuestaModelo> login(String mail) async {
    RespuestaModelo respuesta = await conexion.login(mail);
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    respuesta.datos = PerfilMapper.aEntidad(respuesta.datos as Perfilmodelo);
    return respuesta;
  }

  //200 → guarda el JWT y devuelve la PerfilEntidad; cualquier otro codigo
  //pasa sin cambios y no toca el token guardado
  Future<RespuestaModelo> iniciarSesionConGoogle(String idTokenGoogle) async {
    RespuestaModelo respuesta = await conexion.intercambiarToken(idTokenGoogle);
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    final modelo = respuesta.datos as Tokenmodelo;
    almacenToken.token = modelo.token;
    respuesta.datos = PerfilMapper.aEntidad(modelo.perfil);
    return respuesta;
  }

  void cerrarSesion() {
    almacenToken.borrar();
  }

  //JWT de la sesion, para lo que no pasa por el Dio (Image.network)
  String? get tokenSesion => almacenToken.hayToken ? almacenToken.token : null;

  Future<RespuestaModelo> registro(PerfilEntidad entidad) async {
    Perfilmodelo modeloPeticion = PerfilMapper.aModelo(entidad);
    RespuestaModelo respuesta = await conexion.registro(modeloPeticion);
    if (respuesta.codigoHttp != 201) {
      return respuesta;
    }
    respuesta.datos = PerfilMapper.aEntidad(respuesta.datos as Perfilmodelo);
    return respuesta;
  }
}
