import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmListarGruposTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Listar grupos de un curso";

  //se prueba el estado mientras la peticion esta en vuelo, que no depende de
  //los datos de la bd: antes cargando nunca pasaba a true (habia un == en vez
  //de =) y la lista se vaciaba con [], asi que la vista pintaba "aun no hay
  //grupos" en lugar del spinner. Cada caso construye su vm, como la ruta
  //AppRutas.curso
  void prueba1EstadoDuranteCarga(Gruposviewmodel Function() crearVm) {
    String caso = "cargando y lista null mientras carga";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      final carga = vm.listarGruposDe('categoria_test', 'curso_test');
      expect(vm.cargando, isTrue);
      expect(vm.getListaGrupos, isNull);
      expect(vm.error, isNull);

      await carga;
      expect(vm.cargando, isFalse);
      //con un curso inexistente el backend puede responder lista vacia o
      //error; en cualquier caso el vm tiene que quedar en un estado pintable
      expect(vm.error != null || vm.getListaGrupos != null, isTrue);
    });
  }
}
