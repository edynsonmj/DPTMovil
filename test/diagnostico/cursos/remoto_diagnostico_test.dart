@Tags(['diagnostico'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../../main_test.dart'
    show crearCursoViewModelRemoto, prepararVmCursoDiagnostico;
import '../../remoto/viewModel/curso/vmCursoDiagnosticoTest.dart';

//diagnostico de cursos contra el BACKEND REAL (plan-diagnostico-cursos.md):
//los mismos datos de apoyo que el grupo "Cursos remotos (diagnostico)" de
//main_test.dart. Necesita el backend en localhost:8082: sin el, falla en el
//setUpAll y su rojo no demuestra nada
void main() {
  group('Cursos remotos (diagnostico, rojas):', () {
    VmCursoDiagnosticoTest test = VmCursoDiagnosticoTest();
    prepararVmCursoDiagnostico(test);
    test.diagnosticoCursosConAmpersand(crearCursoViewModelRemoto);
  });
}
