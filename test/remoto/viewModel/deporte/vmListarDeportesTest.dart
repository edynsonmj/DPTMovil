import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmListarDeportesTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Listar deportes";

  //el desplegable del formulario de curso depende de esta carga. Cada caso
  //construye su vm, como lo hara la ruta formularioCurso en la fase 3
  void prueba1codigo200(Deporteviewmodel Function() crearVm) {
    String caso = "200 devuelve nombres";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      final respuesta = await vm.obtenerDeportes();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.error, isNull);
      //FormularioCurso hace cast<String>() sobre esta lista; la bd de
      //pruebas tiene deportes sembrados, solo se comprueba que lleguen
      expect(respuesta.datos, isA<List<String>>());
      final deportes = respuesta.datos as List<String>;
      expect(deportes, isNotEmpty);
      expect(deportes.every((d) => d.isNotEmpty), isTrue);
    });
  }
}
