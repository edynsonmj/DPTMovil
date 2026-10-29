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

  //abre (o programa, con una apertura futura) las inscripciones de un
  //grupo; responde el grupo con su periodo actualizado
  Future<RespuestaModelo> abrirInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
    PeriodoInscripcionModelo periodo,
  );

  //cierra las inscripciones de un grupo desde hoy; responde el grupo
  Future<RespuestaModelo> cerrarInscripciones(
    String categoria,
    String curso,
    int anio,
    int iterable,
  );

  //la direccion del servidor la conoce la conexion, no la vista
  String urlImagen(int idImagen);
}
