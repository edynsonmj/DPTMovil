import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmAtencionTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Atenciones de clase";

  //los casos 1 a 3 se resuelven en el vm antes de llamar al servicio: no
  //necesitan backend aunque el vm use la conexion remota.
  //Cada caso construye su vm, como hace la ruta AppRutas.clase
  void prueba1RegistrarSinCargar(Atencionviewmodel Function() crearVm) {
    String caso = "error registrar sin cargar";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      Resultado<void> resultado = await vm.registrarAtenciones();
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).origen, 'ViewModel');
    });
  }

  //una clase sin codigo no se puede consultar: el vm deja el error listo
  //para pintar en lugar de reventar con codigo!
  void prueba2ClaseSinCodigo(Atencionviewmodel Function() crearVm) {
    String caso = "error clase sin codigo";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargarAtenciones(_grupo(), _clase(codigo: null));
      expect(vm.cargando, isFalse);
      expect(vm.error, isNotNull);
      expect(vm.atenciones, isNull);
      //y registrar sigue sin tener nada que enviar
      expect(await vm.registrarAtenciones(), isA<Fallo>());
    });
  }

  void prueba3MarcarSinLista(Atencionviewmodel Function() crearVm) {
    String caso = "marcar asistencia sin lista no revienta";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);
      vm.marcarAsistencia(0, true);
      vm.marcarAsistencia(-1, true);
      expect(vm.atenciones, isNull);
      //un indice invalido no cambia nada, asi que tampoco notifica
      expect(notificaciones, 0);
    });
  }

  //fija lo que hace hoy la pantalla de una clase contra el backend real.
  //Visto el 2026-10-23 y otra vez el 2026-10-28: el backend no tiene ningun
  //endpoint de atenciones (ni GET /atencionesporclase ni POST /atenciones;
  //no aparecen en /v3/api-docs) y responde 404 sea cual sea la clase.
  //Su verde NO es un comportamiento aceptado: documenta el bug AS-B01
  //(auditoria-mvvm/registro-bugs.md). Cuando se agreguen los endpoints este
  //caso falla: reemplazarlo por los de listar y registrar
  void prueba4BackendSinEndpoint(Atencionviewmodel Function() crearVm) {
    String caso =
        "BUG AS-B01 - backend sin endpoints (fija el 404, no es lo esperado)";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      await vm.cargarAtenciones(_grupo(), _clase(codigo: 1));

      expect(vm.cargando, isFalse);
      expect(vm.error, contains('404'));
      expect(vm.atenciones, isEmpty);
    });
  }

  Grupoentidad _grupo() => Grupoentidad(
    categoria: 'categoria_test',
    curso: 'curso_test',
    anio: 2026,
    iterable: 1,
    cupos: 10,
    fechaCreacion: '2026-01-01',
  );

  Claseentidad _clase({int? codigo}) => Claseentidad(
    codigo: codigo,
    idGrupoCategoria: 'categoria_test',
    idGrupoCurso: 'curso_test',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'instructor_test',
    eliminado: 0,
  );
}
