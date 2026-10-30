@Tags(['diagnostico'])
library;

import 'package:flutter_test/flutter_test.dart';

import '../../main_test.dart'
    show crearEstadisticasViewModel, prepararVmEstadisticasAsistencia;
import '../../remoto/viewModel/estadisticas/vmEstadisticasAsistenciaTest.dart';

//diagnostico de las estadisticas contra el BACKEND REAL
//(plan-diagnostico-estadisticas.md, 4.3): la misma cadena y los mismos datos
//de apoyo que el grupo "Estadisticas con asistencias remotas" de
//main_test.dart. Necesita el backend en localhost:8082: sin el, falla en el
//setUpAll y su rojo no demuestra nada
void main() {
  group('Estadisticas con asistencias remotas (diagnostico):', () {
    VmEstadisticasAsistenciaTest test = VmEstadisticasAsistenciaTest();
    prepararVmEstadisticasAsistencia(test);
    test.diagnosticoUltimoDiaDelRango(crearEstadisticasViewModel);
  });
}
