import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/instructores_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../datosPruebas.dart';

//diagnostico del modulo 9b contra el backend real (plan-diagnostico-
//instructores-facultades.md): InstructoresViewModel con su cadena real, el
//que llena el desplegable del formulario de grupo. El setUpAll registra por
//corrida un alumno con la primera facultad listada
class VmInstructorDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late PerfilEntidad _alumno;

  void preparar({
    required Facultadesviewmodel Function() crearVmFacultades,
    required Servicioautenticacion servicioAutenticacion,
  }) {
    setUpAll(() async {
      final vmFacultades = crearVmFacultades();
      await vmFacultades.listarYNotificarFacultades();
      final digitos = DateTime.now().millisecondsSinceEpoch.toString();
      final id = '${digitos.substring(digitos.length - 8)}9';
      _alumno = PerfilEntidad(
        id: id,
        nombre: 'Alumno prueba $id',
        correo: 'prueba_$id@unicauca.edu.co',
        tipoId: 'CC',
        sexo: 'M',
        facultad: vmFacultades.facultades.first,
        tipoAlumno: 'Estudiante',
      );
      final r = await servicioAutenticacion.registro(await completarRegistro(_alumno));
      expect(r.codigoHttp, 201, reason: 'no se registro $id');
    });
  }

  //H-08
  void prueba1CamposDelDesplegable(InstructoresViewModel Function() crearVm) {
    String metodo = "Listar instructores";
    String caso = "cada instructor trae sus 4 campos y su id no se repite";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.listarYNotificarInstructores();

      expect(vm.error, isNull);
      expect(vm.instructores, isNotEmpty);
      //el desplegable pinta "nombre - id" y envia el id como idInstructor
      for (final i in vm.instructores) {
        expect(
          [i.id, i.nombre, i.correo, i.sexo].every((c) => c != null && c.isNotEmpty),
          isTrue,
          reason: 'instructor ${i.id}: ${[i.nombre, i.correo, i.sexo]}',
        );
      }
      final ids = vm.instructores.map((i) => i.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
    });
  }

  //H-09
  void prueba2AlumnoNoEsInstructor(InstructoresViewModel Function() crearVm) {
    String metodo = "Listar instructores";
    String caso = "un alumno recien registrado no aparece entre los instructores";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.listarYNotificarInstructores();

      expect(vm.error, isNull);
      expect(vm.instructores.map((i) => i.id), isNot(contains(_alumno.id)));
      expect(vm.instructores.map((i) => i.correo), isNot(contains(_alumno.correo)));
    });
  }
}
