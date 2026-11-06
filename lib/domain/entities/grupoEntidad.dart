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
  //cierre a mano del coordinador: manda sobre las fechas
  bool inscripcionesCerradasManual;

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
    this.inscripcionesCerradasManual = false,
  });

  //identifica al grupo (su llave en el backend). La usan los vms que guardan
  //estado por grupo, como horarios e inscripcion
  static String claveDe(String categoria, String curso, int anio, int iterable) =>
      '$categoria/$curso/$anio/$iterable';

  String get clave => claveDe(categoria, curso, anio, iterable);

  //estado de las inscripciones en el dia [hoy] (se recibe para poder
  //probarlo sin depender del reloj). Misma regla que el backend
  //(Grupo.estadoInscripcion): el cierre manual manda, sin apertura esta
  //abierta desde siempre y el dia del cierre aun cuenta. Solo un grupo viejo,
  //sin ninguna de las dos fechas, se muestra sin periodo
  EstadoInscripcion estadoInscripcion(DateTime hoy) {
    if (inscripcionesCerradasManual) return EstadoInscripcion.cerrada;
    final apertura = _soloFecha(fechaInscripcionApertura);
    final cierre = _soloFecha(fechaInscripcionCierre);
    if (apertura == null && cierre == null) return EstadoInscripcion.sinPeriodo;
    final dia = DateTime(hoy.year, hoy.month, hoy.day);
    if (apertura != null && apertura.isAfter(dia)) {
      return EstadoInscripcion.programada;
    }
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
}
