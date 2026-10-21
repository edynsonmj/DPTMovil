import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/facultadesViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexionfacultadesFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//los vms reciben sus dependencias por constructor desde la fase 2: misma
//cadena que la raiz, con dobles en lugar de las conexiones remotas y de
//Google. Solo rutas criticas
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  test('$capa - $tipo - Listar facultades - 200 carga la lista', () async {
    final conexion = ConexionfacultadesFalsa()
      ..respuestaListar = RespuestaModelo(
        codigoHttp: 200,
        datos: [Facultadmodelo(nombre: 'Ingenieria')],
      );
    final vm = Facultadesviewmodel(
      Serviciofacultades(Facultadesrepositorio(conexion: conexion)),
    );

    await vm.listarYNotificarFacultades();

    expect(vm.cargando, isFalse);
    expect(vm.error, isNull);
    expect(vm.facultades, ['Ingenieria']);
  });

  test('$capa - $tipo - Login - 200 guarda el perfil y notifica', () async {
    final conexion = ConexionautenticacionFalsa()
      ..respuestaLogin = RespuestaModelo(
        codigoHttp: 200,
        datos: Perfilmodelo(
          id: '1',
          nombre: 'Ana',
          correo: 'ana@unicauca.edu.co',
          tipoId: 'CC',
          sexo: 'F',
          role: 'Coordinador',
        ),
      );
    final vm = AutenticacionViewModel(
      Servicioautenticacion(Autenticacionrepositorio(conexion: conexion)),
      GoogleSignInFalso(),
    );
    int notificaciones = 0;
    vm.addListener(() => notificaciones++);

    vm.prepararLoginConCorreo('ana@unicauca.edu.co');
    final respuesta = await vm.login();

    expect(respuesta.codigoHttp, 200);
    expect(conexion.ultimoCorreo, 'ana@unicauca.edu.co');
    //el rol es lo que habilita las opciones de coordinador en la UI
    expect(vm.perfilSesion?.role, 'Coordinador');
    //sin la notificacion el menu lateral no se entera de la sesion
    expect(notificaciones, 1);
  });
}
