import 'package:dpt_movil/data/api/conexion/interfaces/ConexionFacultades.dart';
import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/programaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de facultades: el test fija la respuesta
class ConexionfacultadesFalsa implements Conexionfacultades {
  RespuestaModelo respuestaListar = RespuestaModelo(
    codigoHttp: 200,
    datos: <Facultadmodelo>[],
  );
  int llamadasListar = 0;
  //si se fija, la conexion lanza esto en vez de responder: la real solo
  //captura Exception, asi que un TypeError de Facultadmodelo.fromJson sale
  //hacia el repositorio
  Object? lanzar;

  @override
  Future<RespuestaModelo> obtenerFacultades() async {
    llamadasListar++;
    if (lanzar != null) throw lanzar!;
    return respuestaListar;
  }

  RespuestaModelo respuestaProgramas = RespuestaModelo(
    codigoHttp: 200,
    datos: <Programamodelo>[],
  );
  int llamadasProgramas = 0;
  String? ultimaFacultad;

  @override
  Future<RespuestaModelo> obtenerProgramas(String facultad) async {
    llamadasProgramas++;
    ultimaFacultad = facultad;
    //el repositorio escribe sobre datos: copia solo las listas, asi un error
    //sigue llegando como la misma instancia (same)
    final datos = respuestaProgramas.datos;
    if (datos is! List) return respuestaProgramas;
    return RespuestaModelo(
      codigoHttp: respuestaProgramas.codigoHttp,
      datos: List<Programamodelo>.from(datos),
    );
  }
}
