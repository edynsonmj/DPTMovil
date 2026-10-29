import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/domain/entities/estadoInscripcion.dart';

export 'package:dpt_movil/domain/entities/estadoInscripcion.dart';

class Grupoentidad {
  String categoria;
  String curso;
  int anio;
  int iterable;
  int? imagen;
  String? idInstructor;
  int cupos;
  String? estado;
  String fechaCreacion;
  String? fechaFinalizacion;
  //periodo de inscripcion (yyyy-MM-dd), null si nunca se abrio
  String? fechaInscripcionApertura;
  String? fechaInscripcionCierre;

  Grupoentidad({
    required this.categoria,
    required this.curso,
    required this.anio,
    required this.iterable,
    this.imagen,
    this.idInstructor,
    required this.cupos,
    this.estado,
    required this.fechaCreacion,
    this.fechaFinalizacion,
    this.fechaInscripcionApertura,
    this.fechaInscripcionCierre,
  });

  //identifica al grupo (su llave en el backend). La usan los vms que guardan
  //estado por grupo, como horarios e inscripcion
  static String claveDe(String categoria, String curso, int anio, int iterable) =>
      '$categoria/$curso/$anio/$iterable';

  String get clave => claveDe(categoria, curso, anio, iterable);

  //estado de las inscripciones en el dia [hoy] (se recibe para poder
  //probarlo sin depender del reloj). Misma regla que el backend en
  //GET /gruposInscripcion; que el dia del cierre aun cuente como abierto se
  //infiere de que "cerrar" deja el cierre en ayer
  EstadoInscripcion estadoInscripcion(DateTime hoy) {
    final apertura = _soloFecha(fechaInscripcionApertura);
    if (apertura == null) return EstadoInscripcion.sinPeriodo;
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    if (apertura.isAfter(dia)) return EstadoInscripcion.programada;
    final cierre = _soloFecha(fechaInscripcionCierre);
    if (cierre != null && cierre.isBefore(dia)) {
      return EstadoInscripcion.cerrada;
    }
    return EstadoInscripcion.abierta;
  }

  //yyyy-MM-dd del backend; una fecha que no se puede leer cuenta como
  //ausente
  static DateTime? _soloFecha(String? texto) {
    final fecha = texto == null ? null : DateTime.tryParse(texto);
    return fecha == null ? null : DateTime(fecha.year, fecha.month, fecha.day);
  }

  factory Grupoentidad.fromModelo(GrupoModelo grupo) {
    return Grupoentidad(
      categoria: grupo.cat_titulo,
      curso: grupo.cur_nombre,
      anio: grupo.anio,
      iterable: grupo.iterable,
      imagen: grupo.imagen,
      cupos: grupo.cupos,
      estado: grupo.estado,
      fechaCreacion: grupo.fechaCreacion,
      fechaFinalizacion: grupo.fechaFinalizacion,
      idInstructor: grupo.idInstructor,
      fechaInscripcionApertura: grupo.fechaInscripcionApertura,
      fechaInscripcionCierre: grupo.fechaInscripcionCierre,
    );
  }
}
