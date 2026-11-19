import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/deporteRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioDeporte.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexiondeporteFalsa.dart';

//Deporteviewmodel: la lista de deportes del formulario de curso
//(PR-003.2b). Misma cadena que la raiz, con el doble de la conexion abajo
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexiondeporteFalsa conexion;
  late Deporteviewmodel vm;

  setUp(() {
    conexion = ConexiondeporteFalsa();
    vm = Deporteviewmodel(
      Serviciodeporte(Deporterepositorio(cliente: conexion)),
    );
  });

  group('Deportes (vm → servicio → repositorio → doble):', () {
    test('$capa - $tipo - Cargar deportes - 200 carga la lista', () async {
      conexion.respuestaDeportes = RespuestaModelo(
        codigoHttp: 200,
        datos: <String>['Fútbol', 'Natación'],
      );

      await vm.cargar();

      expect(vm.deportes.cargando, isFalse);
      expect(vm.deportes.error, isNull);
      expect(vm.deportes.datos, ['Fútbol', 'Natación']);
      expect(conexion.llamadasDeportes, 1);
    });

    test('$capa - $tipo - Cargar deportes - mientras espera queda cargando y avisa', () async {
      var avisos = 0;
      vm.addListener(() => avisos++);

      final carga = vm.cargar();
      expect(vm.deportes.cargando, isTrue);
      await carga;

      expect(vm.deportes.cargando, isFalse);
      expect(avisos, 2);
    });

    test('$capa - $tipo - Cargar deportes - 204 sin deportes es lista vacia sin error', () async {
      conexion.respuestaDeportes = RespuestaModelo(
        codigoHttp: 204,
        error: ErrorModelo(codigoHttp: 204, mensaje: 'no hay deportes registrados', url: '/deportes', metodo: 'GET'),
      );

      await vm.cargar();

      expect(vm.deportes.error, isNull);
      expect(vm.deportes.datos, isEmpty);
    });

    test('$capa - $tipo - Cargar deportes - 500 y 503 quedan como error con codigo', () async {
      for (final codigo in [500, 503]) {
        conexion.respuestaDeportes = RespuestaModelo(
          codigoHttp: codigo,
          error: ErrorModelo(codigoHttp: codigo, mensaje: 'fallo', url: '/deportes', metodo: 'GET'),
        );

        await vm.cargar();

        expect(vm.deportes.error, 'Código: $codigo - fallo');
        expect(vm.deportes.datos, isEmpty);
      }
    });

    test('$capa - $tipo - Cargar deportes - lo que lance la cadena queda como error, sin escapar', () async {
      conexion.lanzar = StateError('fallo de la conexion');

      await vm.cargar();

      expect(vm.deportes.cargando, isFalse);
      expect(vm.deportes.error, contains('fallo de la conexion'));
    });

    test('$capa - $tipo - Cargar deportes - salir antes de que llegue no revienta', () async {
      //la ruta formularioCurso carga al crearse y provider llama a dispose
      //al salir, aunque la respuesta siga en camino
      final carga = vm.cargar();
      vm.dispose();

      await expectLater(carga, completes);
    });
  });
}
