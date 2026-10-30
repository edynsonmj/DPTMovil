@Tags(['diagnostico'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../../main_test.dart' show crearCategoriaViewModelRemoto;
import '../../remoto/viewModel/categoria/vmCategoriaDiagnosticoTest.dart';

//diagnostico de categorias contra el BACKEND REAL (plan-diagnostico-
//categorias.md): la misma preparacion que el grupo "Categorias remotas
//(diagnostico)" de main_test.dart. Necesita el backend en localhost:8082: sin
//el, falla en el setUpAll y su rojo no demuestra nada
void main() {
  group('Categorias remotas (diagnostico, rojas):', () {
    VmCategoriaDiagnosticoTest test = VmCategoriaDiagnosticoTest();
    test.preparar(crearCategoriaViewModelRemoto);
    test.diagnosticoTituloConAmpersand(crearCategoriaViewModelRemoto);
  });
}
