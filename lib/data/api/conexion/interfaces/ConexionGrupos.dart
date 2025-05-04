import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexiongrupos {
  Future<RespuestaModelo> obtenerGruposDe(
    String categoriaTitulo,
    String nombreCurso,
  );

  Future<RespuestaModelo> obtenerGruposInscripcionDisponible();
}
