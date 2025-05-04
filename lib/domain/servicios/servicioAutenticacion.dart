import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';

class Servicioautenticacion {
  Autenticacionrepositorio repositorio;

  Servicioautenticacion()
    : repositorio = Autenticacionrepositorio(
        conexion: Conexionautenticacionremoto(),
      );

  Future<RespuestaModelo> login(String email) async {
    return repositorio.login(email);
  }

  Future<RespuestaModelo> registro(PerfilEntidad entidad) async {
    return repositorio.registro(entidad);
  }
}
