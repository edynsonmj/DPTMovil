import 'package:dpt_movil/data/api/conexion/interfaces/ConexionAtenciones.dart';
import 'package:dpt_movil/data/mappers/atencionMapper.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';

class Atencionesrepositorio {
  Conexionatenciones conexion;
  Atencionesrepositorio({required this.conexion});

  Future<RespuestaModelo> listarAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int idClase,
  ) async {
    String path = "listarAtencionesClase";
    String metodo = "GET";
    String capa = "Repositorio";
    final RespuestaModelo respuesta = await conexion.obtenerAtencionesClase(
      categoria,
      curso,
      anio,
      iterable,
      idClase,
    );
    if (respuesta.codigoHttp != 200) {
      return respuesta;
    }
    try {
      List<Atencionmodelo> listaModelo =
          respuesta.datos as List<Atencionmodelo>;
      respuesta.datos = listaModelo.map(AtencionMapper.aEntidad).toList();
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        metodo,
        path,
        capa,
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(error, metodo, path, capa);
    }
  }

  Future<RespuestaModelo> registrarAtencionesClase(
    List<Atencionentidad> atenciones,
    int idClase,
  ) async {
    //una atencion de otra clase no se envia: se corregiria la asistencia ajena
    if (atenciones.any((a) => a.idClase != idClase)) {
      return RespuestaModelo.fromObjectError(
        'hay atenciones de otra clase que la $idClase',
        'PUT',
        'registrarAtencionesClase',
        'Repositorio',
      );
    }
    try {
      List<Atencionmodelo> lista =
          atenciones.map(AtencionMapper.aModelo).toList();
      return await conexion.registrarAtencionesClase(lista, idClase);
    } catch (error) {
      return RespuestaModelo.fromObjectError(
        error,
        'PUT',
        'registrarAtencionesClase',
        'Repositorio',
      );
    }
  }
}
