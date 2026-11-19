import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//cerrar sesion en el vm de la sesion, con dobles. Nacio como diagnostico de
//AU-04 (plan-diagnostico-autenticacion.md), corregido el 2026-11-19
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late GoogleSignInFalso google;
  late AutenticacionViewModel vm;

  setUp(() {
    google = GoogleSignInFalso();
    vm = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken()),
      ),
      google,
    )..perfilSesion = PerfilEntidad(
      id: 'coo1',
      nombre: 'Coordinacion',
      correo: 'coordinacion@unicauca.edu.co',
      tipoId: 'CC',
      sexo: 'F',
      role: Roles.coordinador,
    );
  });

  //antes logout esperaba a signOut sin capturar nada: si el plugin fallaba,
  //la excepcion salia al menu y la sesion quedaba (AU-04)
  test('$capa - $tipo - Cerrar sesion - si Google falla al salir la sesion local se borra igual, sin lanzar', () async {
    google.errorAlSalir = PlatformException(code: 'sign_out_failed');

    Object? lanzado;
    try {
      await vm.logout();
    } catch (e) {
      lanzado = e;
    }

    expect([lanzado, vm.perfilSesion], [null, null]);
  });

  test('$capa - $tipo - Cerrar sesion - borra el JWT, la cuenta y el perfil y avisa a la vista', () async {
    var avisos = 0;
    vm.addListener(() => avisos++);

    await vm.logout();

    expect(vm.perfilSesion, isNull);
    expect(vm.cuenta, isNull);
    expect(vm.autorizacion, isNull);
    expect(avisos, 1);
  });
}
