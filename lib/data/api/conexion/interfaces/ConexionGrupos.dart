import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexiongrupos {
  Future<RespuestaModelo> obtenerGruposDe(
    String categoriaTitulo,
    String nombreCurso,
  );

  Future<RespuestaModelo> obtenerGruposInscripcionDisponible();

  Future<RespuestaModelo> obtenerGruposInstructor(String idInstructor);

  Future<RespuestaModelo> insertarGrupo(GrupoModelo grupo);

  //la direccion del servidor la conoce la conexion, no la vista
  String urlImagen(int idImagen);
}
