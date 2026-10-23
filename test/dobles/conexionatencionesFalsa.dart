import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de atenciones: cada test fija la respuesta
//que quiere y despues revisa lo que llego a la conexion. Ojo: el backend aun
//no tiene estos endpoints (404), asi que este doble es lo unico que permite
//probar la pantalla de una clase
class ConexionatencionesFalsa implements Conexionatenciones {
  RespuestaModelo respuestaAtenciones = RespuestaModelo(
    codigoHttp: 200,
    datos: <Atencionmodelo>[],
  );
  RespuestaModelo respuestaRegistrar = RespuestaModelo(codigoHttp: 200);

  //clase pedida, como "categoria/curso/anio/iterable/claseid"
  String? ultimaClase;
  List<Atencionmodelo>? ultimasRegistradas;
  int? ultimoIdClaseRegistro;
  int llamadasAtenciones = 0;
  int llamadasRegistrar = 0;

  @override
  Future<RespuestaModelo> obtenerAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int claseid,
  ) async {
    llamadasAtenciones++;
    ultimaClase = '$categoria/$curso/$anio/$iterable/$claseid';
    return respuestaAtenciones;
  }

  @override
  Future<RespuestaModelo> registrarAtencionesClase(
    List<Atencionmodelo> atenciones,
    int idClase,
  ) async {
    llamadasRegistrar++;
    ultimasRegistradas = atenciones;
    ultimoIdClaseRegistro = idClase;
    return respuestaRegistrar;
  }
}
