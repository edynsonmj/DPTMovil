import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/deporteRepositorio.dart';

class Serviciodeporte {
  Deporterepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  Serviciodeporte(this.repositorio);

  Future<RespuestaModelo> obtenerDeportes() async {
    return await repositorio.obtenerDeportes();
  }
}
