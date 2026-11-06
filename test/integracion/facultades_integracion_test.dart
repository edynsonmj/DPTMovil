import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionFacultadRemoto.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 9b (plan-diagnostico-instructores-facultades
//.md): el vm del desplegable del registro con su cadena real hasta
//Conexionfacultadremoto y el transporte falso debajo, con la respuesta del
//contrato observado
void main() {
  const String capa = "integracion";
  const String tipo = "local";

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

  group('Facultades (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Listar facultades - 200 real llega como lista de nombres', () async {
      adaptador.responder('GET', '/facultades', 200, leerContrato('facultades', 'facultades_200'));

      await vm.listarYNotificarFacultades();

      expect(adaptador.peticionesA('GET', '/facultades'), hasLength(1));
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.facultades, ['fiet']);
    });

    test('$capa - $tipo - Listar facultades - sin red el registro muestra el 503', () async {
      adaptador.fallar('GET', '/facultades', DioExceptionType.connectionError);

      await vm.listarYNotificarFacultades();

      expect(vm.cargando, isFalse);
      expect(vm.error, startsWith('Código: 503'));
      expect(vm.facultades, isEmpty);
    });

    test('$capa - $tipo - Listar facultades - 200 con un objeto es 406', () async {
      adaptador.responder('GET', '/facultades', 200, {'mensaje': 'no es una lista'});

      await vm.listarYNotificarFacultades();

      expect(vm.error, startsWith('Código: 406'));
      expect(vm.facultades, isEmpty);
    });
    //antes FA-04: el vm no usaba NotificacionSegura
    test('$capa - $tipo - Listar facultades - una respuesta que llega despues de dispose no lanza', () async {
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

    test('$capa - $tipo - Listar programas - 200 real llega como lista de nombres y pide la facultad', () async {
      adaptador.responder('GET', '/programas', 200, leerContrato('programas', 'programas_200'));

      await vm.listarProgramas('Facultad de Artes');

      final peticion = adaptador.peticionesA('GET', '/programas').single;
      expect(peticion.uri.queryParameters, {'facultad': 'Facultad de Artes'});
      expect(vm.programas.cargando, isFalse);
      expect(vm.programas.error, isNull);
      expect(vm.programas.datos, hasLength(6));
      expect(vm.programas.datos.first, 'Artes Plásticas');
    });

    test('$capa - $tipo - Listar programas - facultad sin programas (200 GC-0002) es lista vacia', () async {
      adaptador.responder('GET', '/programas', 200, leerContrato('programas', 'programas_200_vacio'));

      await vm.listarProgramas('Facultad de Ingeniería Civil');

      expect(vm.programas.error, isNull);
      expect(vm.programas.datos, isEmpty);
    });

    test('$capa - $tipo - Listar programas - sin red queda el error y la lista vacia', () async {
      adaptador.fallar('GET', '/programas', DioExceptionType.connectionError);

      await vm.listarProgramas('Facultad de Artes');

      expect(vm.programas.cargando, isFalse);
      expect(vm.programas.error, contains('503'));
      expect(vm.programas.datos, isEmpty);
    });

    //los casos rojos de este montaje (FA-01, FA-03, FA-04) estan en
    //test/diagnostico/facultades/integracion_diagnostico_test.dart
  });
}

Future<void> _hastaQue(bool Function() condicion) async {
  for (var i = 0; i < 200 && !condicion(); i++) {
    await Future.delayed(const Duration(milliseconds: 5));
  }
  expect(condicion(), isTrue, reason: 'la peticion no llego al adaptador');
}
