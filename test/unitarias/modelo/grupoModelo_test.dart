import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/periodoInscripcionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//modelos del periodo de inscripcion de un grupo (plan de abrir
//inscripciones, fase 2), contra las respuestas observadas del backend en
//test/contratos/inscripciones
void main() {
  const String capa = "modelo";
  const String tipo = "unitaria";

  group('Grupo y periodo de inscripcion (modelos):', () {
    test('$capa - $tipo - GrupoModelo - lee el periodo con la clave real del backend', () {
      final abierto = GrupoModelo.fromJson(
        leerContrato('inscripciones', 'abrir_200'),
      );
      final cerrado = GrupoModelo.fromJson(
        leerContrato('inscripciones', 'cerrar_200'),
      );

      expect(abierto.fechaInscripcionApertura, '2026-10-29');
      //en el json la clave es fechaIncripcionCierre (errata del backend)
      expect(abierto.fechaInscripcionCierre, '2026-11-30');
      expect(cerrado.fechaInscripcionApertura, '2026-10-28');
      expect(cerrado.fechaInscripcionCierre, '2026-10-28');
    });

    test('$capa - $tipo - GrupoModelo - un grupo sin periodo queda con fechas nulas', () {
      final grupos =
          (leerContrato('inscripciones', 'gruposNoEliminados_200') as List)
              .map((json) => GrupoModelo.fromJson(json))
              .toList();

      final sinPeriodo = grupos[1];
      expect(sinPeriodo.iterable, 2);
      expect(sinPeriodo.fechaInscripcionApertura, isNull);
      expect(sinPeriodo.fechaInscripcionCierre, isNull);
    });

    test('$capa - $tipo - GrupoModelo - crear un grupo no envia el periodo', () {
      //POST /grupo no cambia: el periodo se fija aparte con abrir/cerrar
      final json =
          GrupoModelo.fromJson(leerContrato('inscripciones', 'abrir_200')).toJson();

      expect(json.containsKey('fechaInscripcionApertura'), isFalse);
      expect(json.containsKey(GrupoModelo.claveCierreInscripcion), isFalse);
    });

    test('$capa - $tipo - PeriodoInscripcionModelo - envia solo las fechas definidas', () {
      expect(
        PeriodoInscripcionModelo(apertura: '2026-12-01', cierre: '2026-12-20')
            .toJson(),
        {
          'fechaInscripcionApertura': '2026-12-01',
          'fechaIncripcionCierre': '2026-12-20',
        },
      );
      expect(
        PeriodoInscripcionModelo(cierre: '2026-12-20').toJson(),
        {'fechaIncripcionCierre': '2026-12-20'},
      );
      //sin fechas el cuerpo es {}: el backend abre desde hoy y sin limite
      expect(PeriodoInscripcionModelo().toJson(), isEmpty);
    });
  });
}
