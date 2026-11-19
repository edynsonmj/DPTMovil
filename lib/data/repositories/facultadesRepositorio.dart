import 'package:dpt_movil/data/api/conexion/interfaces/ConexionFacultades.dart';
import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/programaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Facultadesrepositorio {
  Conexionfacultades conexion;
  Facultadesrepositorio({required this.conexion});

  //nada que lance la conexion o la conversion atraviesa esta capa (FA-02)
  Future<RespuestaModelo> listarFacultades() async {
    try {
      RespuestaModelo respuesta = await conexion.obtenerFacultades();
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      List<Facultadmodelo> listaModelo =
          respuesta.datos as List<Facultadmodelo>;
      respuesta.datos = listaModelo.map((f) => f.nombre).toList();
      return respuesta;
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'listarFacultades',
        'repositorio',
      );
    }
  }

  //el desplegable solo usa el nombre del programa
  Future<RespuestaModelo> listarProgramas(String facultad) async {
    RespuestaModelo respuesta = await conexion.obtenerProgramas(facultad);
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    List<Programamodelo> listaModelo =
        respuesta.datos as List<Programamodelo>;
    respuesta.datos = listaModelo.map((p) => p.nombre).toList();
    return respuesta;
  }
}
