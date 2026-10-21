import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmLoginTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Login";

  //el menu lateral decide con este codigo: 200 = sesion iniciada, 404 = no
  //registrado y abre el registro. Un correo inventado nunca existe en la bd
  void prueba1NoRegistrado404(AutenticacionViewModel Function() crearVm) {
    String caso = "correo no registrado responde 404";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      final correo =
          'prueba_${DateTime.now().millisecondsSinceEpoch}@noexiste.test';

      expect(vm.prepararLoginConCorreo(correo), isTrue);
      final respuesta = await vm.login();

      expect(respuesta.codigoHttp, 404);
      //sin perfil no hay rol: la UI no muestra opciones de coordinador
      expect(vm.perfilSesion, isNull);
      expect(vm.correoAutenticado, correo);
    });
  }

  //falla en el vm, antes de cualquier peticion
  void prueba2SinCorreo(AutenticacionViewModel Function() crearVm) {
    String caso = "sin correo no llega a la red";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();

      expect(vm.prepararLoginConCorreo('   '), isFalse);
      expect(vm.error, isNotNull);
      final respuesta = await vm.login();

      expect(respuesta.codigoHttp, 0);
      expect(respuesta.error?.mensaje, contains('No hay un correo autenticado'));
      expect(vm.perfilSesion, isNull);
    });
  }
}
