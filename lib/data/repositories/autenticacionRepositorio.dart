import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAutenticacion.dart';
import 'package:dpt_movil/data/mappers/perfilMapper.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';

class Autenticacionrepositorio {
  Conexionautenticacion conexion;
  Autenticacionrepositorio({required this.conexion});

  Future<RespuestaModelo> login(String mail) async {
    RespuestaModelo respuesta = await conexion.login(mail);
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    respuesta.datos = PerfilMapper.aEntidad(respuesta.datos as Perfilmodelo);
    return respuesta;
  }

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
