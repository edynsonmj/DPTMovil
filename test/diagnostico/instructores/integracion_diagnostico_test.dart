@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionInstructoresRemoto.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de la lista de instructores del formulario de grupo de punta a
//punta sin backend (plan-diagnostico-instructores-facultades.md): el mismo
//montaje que test/integracion/instructores_integracion_test.dart. Afirman el
//comportamiento CORRECTO y se espera que salgan rojas mientras el bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late InstructoresViewModel vm;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = InstructoresViewModel(
      ServicioInstructor(
        Instructoresrepositorio(conexion: Conexioninstructoresremoto(crearDioFalso(adaptador))),
      ),
    );
  });

  group('Instructores (diagnostico de punta a punta):', () {
    ///v3/api-docs documenta 404 "No existen instructores registrados"
    test('$capa - $tipo - Listar instructores - BUG IT-01 - el 404 documentado de no hay instructores es lista vacia sin error', () async {
      adaptador.responder('GET', '/instructores', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No existen instructores registrados',
      });

      await vm.listarYNotificarInstructores();

      expect(vm.error, isNull, reason: '${vm.error}');
      expect(vm.instructores, isEmpty);
    });

    //IT-02 (corregido el 2026-11-19) paso a
    //integracion/instructores_integracion_test.dart
  });
}

