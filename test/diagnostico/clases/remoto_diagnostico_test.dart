@Tags(['diagnostico'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../../main_test.dart'
    show crearClasesViewModel, crearDetalleGrupoViewModel, prepararVmClaseDiagnostico;
import '../../remoto/viewModel/clase/vmClaseDiagnosticoTest.dart';

//diagnostico de clases contra el BACKEND REAL (plan-diagnostico-clases.md):
//los mismos datos de apoyo que el grupo "Clases remotas (diagnostico)" de
//main_test.dart. Necesita el backend en localhost:8082: sin el, falla en el
//setUpAll y su rojo no demuestra nada
void main() {
  group('Clases remotas (diagnostico, rojas):', () {
    VmClaseDiagnosticoTest test = VmClaseDiagnosticoTest();
    prepararVmClaseDiagnostico(test);
    test.diagnosticoEliminarClase(crearClasesViewModel, crearDetalleGrupoViewModel);
    //CL-06 se corrigio: su caso paso a main_test.dart (prueba3FechaSinCorrimiento)
  });
}
