import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/periodoInscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexiongrupos {
  Future<RespuestaModelo> obtenerGruposDe(
    String categoriaTitulo,
    String nombreCurso,
  );

  Future<RespuestaModelo> obtenerGruposInscripcionDisponible();

  Future<RespuestaModelo> obtenerGruposInstructor(String idInstructor);

  Future<RespuestaModelo> insertarGrupo(GrupoModelo grupo);

  //todos los grupos activos, con su periodo de inscripcion: la lista del
  //coordinador para abrir o cerrar inscripciones
  Future<RespuestaModelo> obtenerGruposNoEliminados();

  //aplica un periodo (con apertura futura queda programado); responde el
  //grupo actualizado. No reabre un grupo cerrado a mano
  Future<RespuestaModelo> abrirInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
    PeriodoInscripcionModelo periodo,
  );

  //cierra a mano las inscripciones de un grupo, sin tocar sus fechas;
  //responde el grupo
  Future<RespuestaModelo> cerrarInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );

  //quita el cierre manual; 422 si la fecha de cierre ya paso
  Future<RespuestaModelo> reabrirInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );

  //la direccion del servidor la conoce la conexion, no la vista
  String urlImagen(int idImagen);
}
