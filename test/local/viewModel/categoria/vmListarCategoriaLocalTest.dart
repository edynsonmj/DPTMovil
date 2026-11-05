import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmListarCategoriaLocalTest {
  final String capa = "viewModel";
  final String tipo = "local";
  final String metodo = "Listar categorias";

  //el 204 solo aparece con la coleccion vacia: contra el backend real habria
  //que borrar todas las categorias de la bd. El fake local arranca con 3
  //sembradas y cada vm construye su propia conexion, asi que vaciarlo no
  //afecta a otros vm ni a otras corridas
  void prueba1ListaVacia204(CategoriaViewModel vm) {
    String caso = "lista vacia 204";
    test('$capa - $tipo - $metodo - $caso', () async {
      await _vaciar(vm);

      await vm.listarYNotificarCategorias();
      //el 204 no es un error: es una lista vacia valida
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.categorias, isNotNull);
      expect(vm.categorias, isEmpty);
    });
  }

  void prueba2EntradasVacias(CategoriaViewModel vm) {
    String caso = "entradas del desplegable vacias";
    test('$capa - $tipo - $metodo - $caso', () async {
      await _vaciar(vm);

      await vm.listarYNotificarCategorias();
      //el filtro de inscripciones no debe quedar con categorias que ya no estan
      expect(vm.titulos, isEmpty);
    });
  }

  //borra lo que quede en el fake usando el propio vm: eliminarCategoria
  //refresca la lista tras cada 200, asi que al borrar la ultima el vm ya
  //recibe el 204
  Future<void> _vaciar(CategoriaViewModel vm) async {
    await vm.listarYNotificarCategorias();
    final titulos = (vm.categorias ?? []).map((c) => c.titulo).toList();
    for (final titulo in titulos) {
      Resultado<void> resultado = await vm.eliminarCategoria(titulo);
      expect(resultado, isA<Exito>());
    }
  }
}
