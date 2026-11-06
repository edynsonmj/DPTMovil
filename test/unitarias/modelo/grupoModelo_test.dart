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

    test('$capa - $tipo - GrupoModelo - crear un grupo envia el periodo con la clave real del backend', () {
      //el backend nuevo exige el cierre en POST /grupo (GC-0015)
      final json =
          GrupoModelo.fromJson(leerContrato('inscripciones', 'abrir_200')).toJson();

      expect(json['fechaInscripcionApertura'], '2026-10-29');
      expect(json[GrupoModelo.claveCierreInscripcion], '2026-11-30');
    });

    test('$capa - $tipo - GrupoModelo - sin periodo no envia las fechas', () {
      final datos = Map<String, dynamic>.from(leerContrato('inscripciones', 'abrir_200'))
        ..remove('fechaInscripcionApertura')
        ..remove(GrupoModelo.claveCierreInscripcion);

      final json = GrupoModelo.fromJson(datos).toJson();

      expect(json.containsKey('fechaInscripcionApertura'), isFalse);
      expect(json.containsKey(GrupoModelo.claveCierreInscripcion), isFalse);
    });

    test('$capa - $tipo - PeriodoInscripcionModelo - arma el cuerpo de PATCH /grupo/periodo', () {
      const clave = {'categoria': 'c', 'curso': 'k', 'anio': 2026, 'iterable': 2};
      Map<String, dynamic> cuerpo(PeriodoInscripcionModelo p) =>
          p.toJson(categoria: 'c', curso: 'k', anio: 2026, iterable: 2);

      expect(
        cuerpo(PeriodoInscripcionModelo(apertura: '2026-12-01', cierre: '2026-12-20')),
        {
          'fechaApertura': '2026-12-01',
          'fechaCierre': '2026-12-20',
          'grupos': [clave],
        },
      );
      //sin apertura no se envia: el grupo conserva la suya
      expect(cuerpo(PeriodoInscripcionModelo(cierre: '2026-12-20')), {
        'fechaCierre': '2026-12-20',
        'grupos': [clave],
      });
    });

    test('$capa - $tipo - GrupoModelo - lee el cierre manual y no lo envia', () {
      final modelo = GrupoModelo.fromJson(leerContrato('inscripciones', 'cerrarManual_200'));

      expect(modelo.inscripcionesCerradasManual, isTrue);
      //solo de salida en el backend
      expect(modelo.toJson().containsKey('inscripcionesCerradasManual'), isFalse);
    });
  });
}
