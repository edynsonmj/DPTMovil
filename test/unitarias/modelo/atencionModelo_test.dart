import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//ida y vuelta json -> modelo -> json de lo que la toma de asistencia lee y
//vuelve a enviar. Aqui solo los campos que hoy se conservan; codigo, imagen
//y eliminadoestado del alumno son la hipotesis AS-05 (test/diagnostico)
void main() {
  const String capa = "modelo";
  const String tipo = "unitaria";

  final List contrato = leerContrato('atenciones', 'listar_200') as List;

  group('Atenciones (modelos):', () {
    test('$capa - $tipo - Atencionmodelo - ida y vuelta conserva clase y marca', () {
      for (final json in contrato) {
        final vuelta = Atencionmodelo.fromJson(json).toJson();

        expect(vuelta['idClase'], json['idClase']);
        expect(vuelta['estaAtendido'], json['estaAtendido']);
        expect(vuelta['alumno'], isA<Map<String, dynamic>>());
      }
    });

    test('$capa - $tipo - Alumnomodelo - ida y vuelta conserva identidad y contacto', () {
      for (final json in contrato) {
        final alumno = json['alumno'];
        final vuelta = Alumnomodelo.fromJson(alumno).toJson();

        for (final campo in ['id', 'tipo', 'nombre', 'correo', 'sexo', 'tipoid']) {
          expect(vuelta[campo], alumno[campo], reason: '${alumno['id']}.$campo');
        }
      }
    });
  });
}
