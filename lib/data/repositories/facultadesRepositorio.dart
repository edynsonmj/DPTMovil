import 'package:dpt_movil/data/api/conexion/interfaces/ConexionFacultades.dart';
import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Facultadesrepositorio {
  Conexionfacultades conexion;
  Facultadesrepositorio({required this.conexion});

  Future<RespuestaModelo> listarFacultades() async {
    RespuestaModelo respuesta = await conexion.obtenerFacultades();
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    List<Facultadmodelo> listaModelo = respuesta.datos as List<Facultadmodelo>;
    List<String> lista = [];
    for (Facultadmodelo item in listaModelo) {
      lista.add(item.nombre);
    }
    respuesta.datos = lista;
    return respuesta;
  }
}
