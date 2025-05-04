import 'package:dpt_movil/data/api/conexion/remoto/ConexionFacultadRemoto.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';

class Serviciofacultades {
  Facultadesrepositorio repositorio;
  Serviciofacultades()
    : repositorio = Facultadesrepositorio(conexion: Conexionfacultadremoto());

  Future<RespuestaModelo> listarFacultades() async {
    return await repositorio.listarFacultades();
  }
}
