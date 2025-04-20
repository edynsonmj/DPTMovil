import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionatenciones {
  Future<RespuestaModelo> obtenerAtencionesClase(
    String categoria,
    String curso,
    int anio,
    int iterable,
    int claseid,
  );

  Future<RespuestaModelo> registrarAtencionesClase(
    List<Atencionmodelo> atenciones,
    int idClase,
  );
}
