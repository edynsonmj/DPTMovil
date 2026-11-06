@Tags(['diagnostico'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../../main_test.dart'
    show
        crearDetalleGrupoViewModel,
        crearGruposViewModel,
        prepararVmGrupoDiagnostico;
import '../../remoto/viewModel/grupo/vmGrupoDiagnosticoTest.dart';

//diagnostico de grupos contra el BACKEND REAL (plan-diagnostico-grupos.md):
//los mismos datos de apoyo que el grupo "Grupos remotos (diagnostico)" de
//main_test.dart. Necesita el backend en localhost:8082: sin el, falla en el
//setUpAll y su rojo no demuestra nada
void main() {
  group('Grupos remotos (diagnostico, rojas):', () {
    VmGrupoDiagnosticoTest test = VmGrupoDiagnosticoTest();
    prepararVmGrupoDiagnostico(test);
    test.diagnosticoGruposConAmpersand(crearGruposViewModel);
    test.diagnosticoPantallaConAmpersand(crearDetalleGrupoViewModel);
  });
}
