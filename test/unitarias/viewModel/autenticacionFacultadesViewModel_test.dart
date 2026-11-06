import 'package:dpt_movil/data/models/facultadModelo.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/data/models/tokenModelo.dart';
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
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

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
      Servicioautenticacion(Autenticacionrepositorio(conexion: conexion, almacenToken: AlmacenToken())),
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

  group('Sesion con Google (vm con dobles):', () {
    late ConexionautenticacionFalsa conexion;
    late AlmacenToken almacen;
    late GoogleSignInFalso google;
    late AutenticacionViewModel vm;

    setUp(() {
      conexion = ConexionautenticacionFalsa();
      almacen = AlmacenToken();
      google = GoogleSignInFalso();
      vm = AutenticacionViewModel(
        Servicioautenticacion(
          Autenticacionrepositorio(conexion: conexion, almacenToken: almacen),
        ),
        google,
      );
    });

    test('$capa - $tipo - Login con Google - manda el ID Token a /auth/token, guarda el perfil y el JWT', () async {
      google.cuenta = CuentaGoogleFalsa(email: 'ana@unicauca.edu.co', idToken: 'id-token-de-google');
      conexion.respuestaToken = RespuestaModelo(
        codigoHttp: 200,
        datos: Tokenmodelo(
          token: 'jwt-del-sistema',
          perfil: Perfilmodelo(id: '1', nombre: 'Ana', correo: 'ana@unicauca.edu.co', tipoId: 'CC', sexo: 'F', role: 'Coordinador'),
        ),
      );

      expect(await vm.loginGoogle(), isTrue);
      final respuesta = await vm.login();

      expect(respuesta.codigoHttp, 200);
      expect(conexion.ultimoIdToken, 'id-token-de-google');
      //con cuenta de Google no se usa GET /login
      expect(conexion.llamadasLogin, 0);
      expect(vm.perfilSesion?.role, 'Coordinador');
      expect(almacen.token, 'jwt-del-sistema');
    });

    test('$capa - $tipo - Login con Google - sin ID Token devuelve error y no llama al backend', () async {
      google.cuenta = CuentaGoogleFalsa(email: 'ana@unicauca.edu.co', idToken: null);

      await vm.loginGoogle();
      final respuesta = await vm.login();

      expect(respuesta.error?.mensaje, contains('ID Token'));
      expect(conexion.llamadasToken, 0);
      expect(vm.perfilSesion, isNull);
    });

    test('$capa - $tipo - Registro con Google - despues del 201 pide el JWT', () async {
      google.cuenta = CuentaGoogleFalsa(email: 'beto@unicauca.edu.co');
      final perfilAlumno = Perfilmodelo(id: '2', nombre: 'Beto', correo: 'beto@unicauca.edu.co', tipoId: 'CC', sexo: 'M', role: 'Alumno');
      conexion.respuestaRegistro = RespuestaModelo(codigoHttp: 201, datos: perfilAlumno);
      conexion.respuestaToken = RespuestaModelo(
        codigoHttp: 200,
        datos: Tokenmodelo(token: 'jwt-del-alumno', perfil: perfilAlumno),
      );
      await vm.loginGoogle();

      final respuesta = await vm.registroAlumno(
        PerfilEntidad(id: '2', nombre: 'Beto', correo: 'beto@unicauca.edu.co', tipoId: 'CC', sexo: 'M'),
      );

      expect(respuesta.codigoHttp, 201);
      expect(conexion.llamadasToken, 1);
      expect(almacen.token, 'jwt-del-alumno');
      expect(vm.perfilSesion?.role, 'Alumno');
    });

    test('$capa - $tipo - Cerrar sesion - borra el JWT', () async {
      almacen.token = 'jwt-del-sistema';

      await vm.logout();

      expect(almacen.hayToken, isFalse);
    });
  });
}
