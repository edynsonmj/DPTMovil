import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmListarFacultadesTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Listar facultades";

  //el desplegable del registro depende de esta carga. Cada caso construye su
  //vm, como lo hara la ruta autenticacionRegistro en la fase 2
  void prueba1codigo200(Facultadesviewmodel Function() crearVm) {
    String caso = "carga la lista sin error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      await vm.listarYNotificarFacultades();

      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      //la bd de pruebas tiene facultades sembradas; solo se comprueba que
      //lleguen nombres, no cuales
      expect(vm.facultades, isNotEmpty);
      expect(vm.facultades.every((f) => f.isNotEmpty), isTrue);
    });
  }
}
