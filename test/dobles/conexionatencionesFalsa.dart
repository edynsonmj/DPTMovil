import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

import '../contratos/leerContrato.dart';
import 'copiaRespuesta.dart';

//doble programable de la conexion de atenciones: cada test fija la respuesta
//que quiere y despues revisa lo que llego a la conexion
class ConexionatencionesFalsa implements Conexionatenciones {
  //por defecto la lista del contrato (test/contratos/atenciones),
  //pasada por el mismo fromJson que usa la conexion real: la forma de los
  //datos no la inventa el doble
  RespuestaModelo respuestaAtenciones = RespuestaModelo(
    codigoHttp: 200,
    datos: atencionesDelContrato('listar_200'),
  );
  RespuestaModelo respuestaRegistrar = RespuestaModelo(codigoHttp: 200);

  //se espera antes de responder el registro: para revisar la pantalla a
  //mitad de peticion o tocar guardar dos veces mientras la primera sigue
  Future<void> Function()? antesDeRegistrar;

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
    //el repositorio escribe sobre datos: una copia por peticion
    return copiaRespuesta(respuestaAtenciones);
  }

  @override
  Future<RespuestaModelo> registrarAtencionesClase(
    List<Atencionmodelo> atenciones,
    int idClase,
  ) async {
    llamadasRegistrar++;
    ultimasRegistradas = atenciones;
    ultimoIdClaseRegistro = idClase;
    await antesDeRegistrar?.call();
    return respuestaRegistrar;
  }
}

//modelos de un archivo del contrato, como los entregaria la conexion real
//al pedir la clase 210 (la de los contratos)
List<Atencionmodelo> atencionesDelContrato(String nombre) =>
    (leerContrato('atenciones', nombre) as List)
        .map((json) => Atencionmodelo.fromJson(json, 210))
        .toList();
