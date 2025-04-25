import 'package:dpt_movil/presentation/viewmodels/imagenViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class Vmobtenerimagentest {
  void prueba1codigo200(Imagenviewmodel vm) {
    test('Evaluacion codigo 200', () async {
      await vm.obtenerImagen(3);
      print('cargando: ${vm.cargando}');
      print('error ${vm.error}');
      expect(vm.imagen?.datos, isNotNull);
      expect(vm.imagen?.id, 3);
    });
  }
}
