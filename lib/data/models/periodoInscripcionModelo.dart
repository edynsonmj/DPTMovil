//cuerpo de PATCH /grupo/periodo (PeriodoInscripcionRequest): el cierre es
//obligatorio y debe ser de hoy en adelante; sin apertura el grupo conserva la
//que tenia. Formato yyyy-MM-dd
class PeriodoInscripcionModelo {
  final String? apertura;
  final String cierre;

  PeriodoInscripcionModelo({this.apertura, required this.cierre});

  //la ruta admite varios grupos a la vez; la app aplica el periodo a uno
  Map<String, dynamic> toJson({
    required String categoria,
    required String curso,
    required int anio,
    required int iterable,
  }) {
    return {
      if (apertura != null) 'fechaApertura': apertura,
      'fechaCierre': cierre,
      'grupos': [
        {
          'categoria': categoria,
          'curso': curso,
          'anio': anio,
          'iterable': iterable,
        },
      ],
    };
  }
}
