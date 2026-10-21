import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';

class Serviciofacultades {
  Facultadesrepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  //(lib/config/inyeccion/dependencias.dart)
  Serviciofacultades(this.repositorio);

  Future<RespuestaModelo> listarFacultades() async {
    return await repositorio.listarFacultades();
  }
}
