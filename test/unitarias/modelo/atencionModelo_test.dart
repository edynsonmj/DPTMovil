import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//lo que la toma de asistencia lee de GET /asistenciasClase y lo que envia
//al POST: se lee {alumno, asistio} y se escribe {idPerfil, asistio}
void main() {
  const String capa = "modelo";
  const String tipo = "unitaria";

  final List contrato = leerContrato('atenciones', 'listar_200') as List;

  group('Atenciones (modelos):', () {
    test('$capa - $tipo - Atencionmodelo - lee la marca y toma la clase pedida', () {
      for (final json in contrato) {
        final modelo = Atencionmodelo.fromJson(json, 210);

        expect(modelo.idClase, 210);
        expect(modelo.estaAtendido, json['asistio']);
        expect(modelo.alumno.id, json['alumno']['id']);
      }
    });

    test('$capa - $tipo - Atencionmodelo - escribe el registro del contrato', () {
      final enviados =
          contrato.map((json) => Atencionmodelo.fromJson(json, 210)).toList();
      enviados[1].estaAtendido = true;

      expect(
        enviados.map((a) => a.toJson()).toList(),
        (leerContrato('atenciones', 'confirmar_peticion') as Map)['asistencias'],
      );
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
