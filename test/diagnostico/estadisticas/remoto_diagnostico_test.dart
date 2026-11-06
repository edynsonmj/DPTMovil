@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../main_test.dart'
    show
        baseUrlPruebas,
        crearEstadisticasViewModel,
        prepararVmEstadisticasAsistencia;
import '../../remoto/jwtPruebas.dart';
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
    test.diagnosticoMinutosAcumulados(crearEstadisticasViewModel);
    test.diagnosticoSesionVencida(crearEstadisticasViewModel);
    test.diagnosticoRegistroDesdeLaApp(
      () => Conexionatencionesremoto(crearDioPruebas(baseUrlPruebas)),
    );
  });
}
