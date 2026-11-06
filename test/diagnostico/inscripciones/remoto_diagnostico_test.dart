@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionInscripcionRemoto.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../main_test.dart'
    show baseUrlPruebas, crearInscripcionViewModel, prepararVmInscripcion;
import '../../remoto/jwtPruebas.dart';
import '../../remoto/viewModel/inscripcion/vmInscripcionTest.dart';

//diagnostico de la inscripcion del alumno contra el BACKEND REAL
//(plan-diagnostico-inscripciones.md, 4.3): la misma cadena y los mismos datos
//de apoyo que el grupo "Inscripcion del alumno remota" de main_test.dart.
//Unica prueba de diagnostico que necesita el backend en localhost:8082: sin
//el, falla en el setUpAll y su rojo no demuestra nada
void main() {
  group('Inscripcion del alumno remota (diagnostico):', () {
    VmInscripcionTest test = VmInscripcionTest();
    prepararVmInscripcion(test);
    test.diagnosticoValidarTrasInscribir(crearInscripcionViewModel);
    test.diagnosticoListaDeEspera(
      crearInscripcionViewModel,
      () => Servicioinscripcion(
        Inscripcionrepositorio(
          conexion: Conexioninscripcionremoto(crearDioPruebas(baseUrlPruebas)),
        ),
      ),
    );
    test.diagnosticoRepetirConGrupoLleno(crearInscripcionViewModel);
    test.diagnosticoRepetirYAlumnoInexistente(crearInscripcionViewModel);
    test.diagnosticoRechazoLegible(crearInscripcionViewModel);
    test.diagnosticoSesionVencida(crearInscripcionViewModel);
  });
}
