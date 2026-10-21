import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';

class Servicioautenticacion {
  Autenticacionrepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  //(lib/config/inyeccion/dependencias.dart)
  Servicioautenticacion(this.repositorio);

  Future<RespuestaModelo> login(String email) async {
    return repositorio.login(email);
  }

  Future<RespuestaModelo> registro(PerfilEntidad entidad) async {
    return repositorio.registro(entidad);
  }
}
