import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/domain/entities/atencionEntidad.dart';

class Servicioatencion {
  Atencionesrepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  Servicioatencion(this.repositorio);

  Future<RespuestaModelo> listarAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int idClase,
  ) async {
    return await repositorio.listarAtencionesClase(
      categoria,
      curso,
      anio,
      iterable,
      idClase,
    );
  }

  Future<RespuestaModelo> registrarAtenciones(
    List<Atencionentidad> atenciones,
    int idClase,
  ) async {
    return await repositorio.registrarAtencionesClase(atenciones, idClase);
  }
}
