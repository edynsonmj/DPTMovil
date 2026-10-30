@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionInstructoresRemoto.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
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

    //la ruta grupoFormulario crea el vm y lo desecha al salir: una carga que
    //llega despues no debe notificar
    test('$capa - $tipo - Listar instructores - BUG IT-02 - una respuesta que llega despues de dispose no lanza', () async {
      adaptador.responder('GET', '/instructores', 200, leerContrato('instructores', 'instructores_200'));
      final retenida = adaptador.retener('GET', '/instructores');
      final carga = vm.listarYNotificarInstructores();
      await _hastaQue(() => adaptador.peticiones.length == 1);
      vm.dispose();
      retenida.complete();

      Object? lanzado;
      try {
        await carga;
      } catch (e) {
        lanzado = e;
      }
      expect(lanzado, isNull, reason: '$lanzado');
    });
  });
}

Future<void> _hastaQue(bool Function() condicion) async {
  for (var i = 0; i < 200 && !condicion(); i++) {
    await Future.delayed(const Duration(milliseconds: 5));
  }
  expect(condicion(), isTrue, reason: 'la peticion no llego al adaptador');
}
