import 'package:dpt_movil/data/models/grupoModelo.dart';

//cuerpo de PUT /abrirInscripcionesGrupo. Ambas fechas son opcionales para
//el backend: sin apertura toma hoy y sin cierre deja las inscripciones
//abiertas sin limite. Formato yyyy-MM-dd
class PeriodoInscripcionModelo {
  final String? apertura;
  final String? cierre;

  PeriodoInscripcionModelo({this.apertura, this.cierre});

  //las fechas nulas no se envian: se probo el cuerpo vacio contra el
  //backend, no una clave con null
  Map<String, dynamic> toJson() {
    return {
      if (apertura != null) 'fechaInscripcionApertura': apertura,
      if (cierre != null) GrupoModelo.claveCierreInscripcion: cierre,
    };
  }
}
