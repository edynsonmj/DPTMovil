@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionFacultadRemoto.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de la lista de facultades del registro de punta a punta sin
//backend (plan-diagnostico-instructores-facultades.md): el mismo montaje que
//test/integracion/facultades_integracion_test.dart. Afirman el comportamiento
//CORRECTO y se espera que salgan rojas mientras el bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late Facultadesviewmodel vm;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = Facultadesviewmodel(
      Serviciofacultades(
        Facultadesrepositorio(conexion: Conexionfacultadremoto(crearDioFalso(adaptador))),
      ),
    );
  });

  group('Facultades (diagnostico de punta a punta):', () {
    //una facultad sin nombre: fromJson lanza un TypeError que atraviesa la
    //conexion (solo captura Exception) y el repositorio (no tiene try)
    test('$capa - $tipo - Listar facultades - BUG FA-01 - una facultad incompleta llega como error con codigo, no como excepcion', () async {
      adaptador.responder('GET', '/facultades', 200, [
        {'nombre': null},
      ]);

      await vm.listarYNotificarFacultades();

      expect(vm.error, isNotNull);
      expect(vm.error, startsWith('Código: '));
    });

    ///v3/api-docs documenta 404 "No existen facultades registradas"
    test('$capa - $tipo - Listar facultades - BUG FA-03 - el 404 documentado de no hay facultades es lista vacia sin error', () async {
      adaptador.responder('GET', '/facultades', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No existen facultades registradas',
      });

      await vm.listarYNotificarFacultades();

      expect(vm.error, isNull, reason: '${vm.error}');
      expect(vm.facultades, isEmpty);
    });

    //la ruta autenticacionRegistro crea el vm y lo desecha al salir: una
    //carga que llega despues no debe notificar
    test('$capa - $tipo - Listar facultades - BUG FA-04 - una respuesta que llega despues de dispose no lanza', () async {
      adaptador.responder('GET', '/facultades', 200, leerContrato('facultades', 'facultades_200'));
      final retenida = adaptador.retener('GET', '/facultades');
      final carga = vm.listarYNotificarFacultades();
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
