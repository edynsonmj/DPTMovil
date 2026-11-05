@Tags(['diagnostico'])
library;

import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//diagnostico del vm de la sesion con dobles (plan-diagnostico-autenticacion.md).
//Afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista
void main() {
  const String capa = "viewModel";
  const String tipo = "diagnostico";

  late GoogleSignInFalso google;
  late AutenticacionViewModel vm;

  setUp(() {
    google = GoogleSignInFalso();
    vm = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa()),
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

  //logout espera a signOut antes de borrar la sesion y no captura nada: si
  //el plugin falla, la excepcion sale al onTap del menu y la sesion queda
  test('$capa - $tipo - Cerrar sesion - BUG AU-04 - si Google falla al salir la sesion local se borra igual, sin lanzar', () async {
    google.errorAlSalir = PlatformException(code: 'sign_out_failed');

    Object? lanzado;
    try {
      await vm.logout();
    } catch (e) {
      lanzado = e;
    }

    expect([lanzado, vm.perfilSesion], [null, null]);
  });
}
