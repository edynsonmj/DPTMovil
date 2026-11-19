import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/presentation/view/views/autenticacion/AutenticacionView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/googleSignInFalso.dart';
import 'montajeAutenticacion.dart';

//inicio de sesion y registro de punta a punta sin backend
//(plan-diagnostico-autenticacion.md): menu lateral real, rutas reales y la
//cadena real de autenticacion hasta el transporte falso
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late MontajeAutenticacion m;

  setUp(() => m = MontajeAutenticacion());

  group('Autenticacion (de punta a punta sin backend):', () {
    //CAT-12 / T-04: login notifica, asi que el menu cambia sin ayuda
    testWidgets('$capa - $tipo - Login - 200 inicia la sesion y el menu muestra las opciones del rol', (tester) async {
      m.adaptador.responder('GET', '/login', 200, leerContrato('autenticacion', 'login_200'));
      await m.abrir(tester);

      await m.iniciarSesionConCorreo(tester, 'ana@unicauca.edu.co');

      expect(find.text('Email autenticado'), findsOneWidget);
      expect(m.sesion.perfilSesion?.role, Roles.coordinador);
      await m.abrirMenu(tester);
      expect(find.text('Estadísticas'), findsOneWidget);
      //con sesion el pie muestra el perfil y su menu "⋮" (cerrar sesion)
      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(find.text(MontajeAutenticacion.textoIniciarSesion), findsNothing);
    });

    testWidgets('$capa - $tipo - Login - 404 abre el registro con el correo escrito', (tester) async {
      m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
      await m.abrir(tester);

      await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');

      expect(find.byType(Autenticacionview), findsOneWidget);
      expect(find.text('beto@unicauca.edu.co'), findsOneWidget);
      //el desplegable de facultades viene de GET /facultades
      expect(m.adaptador.peticionesA('GET', '/facultades'), hasLength(1));
    });

    testWidgets('$capa - $tipo - Registro - 201 envia el formulario, cierra el registro e inicia la sesion', (tester) async {
      m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
      m.adaptador.responder('POST', '/RegistroPerfilAlumno', 201, leerContrato('autenticacion', 'registro_201'));
      await m.abrir(tester);
      await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');

      await m.llenarRegistro(tester);
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      final peticion = m.adaptador.peticionesA('POST', '/RegistroPerfilAlumno').single;
      expect(peticion.cuerpo, leerContrato('autenticacion', 'registro_peticion'));
      expect(find.byType(Autenticacionview), findsNothing);
      //el aviso va en cola detras de "Valores aceptados", que el registro
      //muestra antes de enviar y dura 4 s
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Te has registrado exitosamente'), findsOneWidget);
      expect(m.sesion.perfilSesion?.role, Roles.alumno);
    });

    testWidgets('$capa - $tipo - Registro - 422 muestra el motivo del backend y se queda en el formulario', (tester) async {
      m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
      m.adaptador.responder('POST', '/RegistroPerfilAlumno', 422, {
        'codigoError': 'GC-0029',
        'mensaje': 'Los datos enviados no son validos, El programa Artes Plásticas no pertenece a la facultad fiet',
        'codigoHttp': 422,
      });
      await m.abrir(tester);
      await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');

      await m.llenarRegistro(tester);
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(find.byType(Autenticacionview), findsOneWidget);
      expect(find.text('El programa Artes Plásticas no pertenece a la facultad fiet'), findsOneWidget);
      expect(m.sesion.perfilSesion, isNull);
    });

    testWidgets('$capa - $tipo - Registro - administrativo envia la dependencia sin facultad, programa ni codigo', (tester) async {
      m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
      m.adaptador.responder('POST', '/RegistroPerfilAlumno', 201, leerContrato('autenticacion', 'registro_201'));
      await m.abrir(tester);
      await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Beto Alumno');
      await tester.enterText(find.widgetWithText(TextFormField, 'Identificacion'), '1061000002');
      await m.elegir(tester, 'Selecciona tu tipo de identificacion', 'CC');
      await m.elegir(tester, 'Selecciona tu sexo', 'M');
      await m.elegir(tester, 'Estas vinculado a la universidad como:', 'Administrativo');
      //no pide facultad ni codigo
      expect(find.text('Selecciona tu facultad'), findsNothing);
      expect(find.widgetWithText(TextFormField, 'Codigo institucional'), findsNothing);
      await tester.enterText(find.widgetWithText(TextFormField, 'Dependencia'), 'Division de Deportes');
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      final cuerpo = m.adaptador.peticionesA('POST', '/RegistroPerfilAlumno').single.cuerpo as Map;
      expect(cuerpo['tipoAlumno'], 'Administrativo');
      expect(cuerpo['dependencia'], 'Division de Deportes');
      expect(cuerpo['facultad'], isNull);
      expect(cuerpo['programa'], isNull);
      expect(cuerpo['alumnoCodigo'], isNull);
      expect(m.adaptador.peticionesA('GET', '/programas'), isEmpty);
      expect(find.byType(Autenticacionview), findsNothing);
    });

    testWidgets('$capa - $tipo - Registro - estudiante sin programa no envia la peticion', (tester) async {
      m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
      await m.abrir(tester);
      await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Beto Alumno');
      await tester.enterText(find.widgetWithText(TextFormField, 'Identificacion'), '1061000002');
      await m.elegir(tester, 'Selecciona tu tipo de identificacion', 'CC');
      await m.elegir(tester, 'Selecciona tu sexo', 'M');
      await m.elegir(tester, 'Estas vinculado a la universidad como:', 'Estudiante');
      await tester.enterText(find.widgetWithText(TextFormField, 'Codigo institucional'), '104619021');
      await m.elegir(tester, 'Selecciona tu facultad', 'fiet');
      //la facultad elegida pide sus programas
      expect(m.adaptador.peticionesA('GET', '/programas').single.uri.queryParameters, {'facultad': 'fiet'});
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(find.text('Selecciona tu programa academico por favor'), findsOneWidget);
      expect(m.adaptador.peticionesA('POST', '/RegistroPerfilAlumno'), isEmpty);
    });

    //antes AU-07: GUARDAR no se deshabilitaba mientras se enviaba
    testWidgets('$capa - $tipo - Registro - dos toques en GUARDAR envian un solo registro', (tester) async {
      final retenida = m.adaptador.retener('POST', '/RegistroPerfilAlumno');
      m.adaptador.responder('POST', '/RegistroPerfilAlumno', 201, leerContrato('autenticacion', 'registro_201'));
      m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
      await m.abrir(tester);
      await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');
      await m.llenarRegistro(tester);

      await tester.tap(find.text('GUARDAR'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('GUARDAR'), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));
      //ambas pasaron por Dio y esperan en el transporte retenido
      await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      final enviadas = m.adaptador.peticionesA('POST', '/RegistroPerfilAlumno').length;
      retenida.complete();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(enviadas, 1);
    });

    testWidgets('$capa - $tipo - Registro - cancelar cierra el registro y no deja sesion', (tester) async {
      m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
      await m.abrir(tester);
      await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');

      await tester.tap(find.text('CANCELAR'));
      await tester.pumpAndSettle();

      expect(find.byType(Autenticacionview), findsNothing);
      expect(m.sesion.perfilSesion, isNull);
      expect(m.sesion.correoAutenticado, isNull);
      expect(m.adaptador.peticionesA('POST', '/RegistroPerfilAlumno'), isEmpty);
    });

    testWidgets('$capa - $tipo - Cerrar sesion - borra la sesion y lleva a categorias', (tester) async {
      m.adaptador.responder('GET', '/login', 200, leerContrato('autenticacion', 'login_200'));
      await m.abrir(tester);
      await m.iniciarSesionConCorreo(tester, 'ana@unicauca.edu.co');

      await m.cerrarSesion(tester);

      expect(m.sesion.perfilSesion, isNull);
      expect(m.google.llamadasSalir, 1);
      expect(find.text('Categorías'), findsWidgets);
    });
  
    //backend nuevo (2026-11-05): ID Token de Google → POST /auth/token → JWT
    //que el Dio compartido envia en cada peticion
    testWidgets('$capa - $tipo - Login con Google - cambia el ID Token por el JWT y las peticiones siguientes lo llevan', (tester) async {
      m.google.cuenta = CuentaGoogleFalsa(email: 'ana@unicauca.edu.co', idToken: 'id-token-de-google');
      m.adaptador.responder('POST', '/auth/token', 200, leerContrato('autenticacion', 'token_200'));
      await m.abrir(tester);

      await m.iniciarSesionConGoogle(tester);

      expect(m.adaptador.peticionesA('POST', '/auth/token').single.autorizacion, 'Bearer id-token-de-google');
      expect(m.adaptador.peticionesA('GET', '/login'), isEmpty);
      expect(find.text('Email autenticado'), findsOneWidget);
      expect(m.sesion.perfilSesion?.role, Roles.coordinador);

      //una pantalla del coordinador pide sus grupos (cadena real) con el JWT
      Navigator.of(tester.element(find.text('Abrir pantalla'))).pushNamed(AppRutas.InscripcionesParticulares);
      await tester.pumpAndSettle();
      expect(m.adaptador.peticionesA('GET', '/gruposNoEliminados').last.autorizacion, 'Bearer jwt-del-sistema');
    });

    testWidgets('$capa - $tipo - Login con Google - 404 abre el registro y al registrarse pide el JWT del alumno', (tester) async {
      m.google.cuenta = CuentaGoogleFalsa(email: 'beto@unicauca.edu.co', displayName: 'Beto Alumno');
      m.adaptador.responder('POST', '/auth/token', 404);
      m.adaptador.responder('POST', '/RegistroPerfilAlumno', 201, leerContrato('autenticacion', 'registro_201'));
      await m.abrir(tester);
      await m.iniciarSesionConGoogle(tester);
      //con Google el nombre ya viene de la cuenta: no se pide
      expect(find.text('Beto Alumno'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Identificacion'), '1061000002');
      await m.elegir(tester, 'Selecciona tu tipo de identificacion', 'CC');
      await m.elegir(tester, 'Selecciona tu sexo', 'M');
      await m.elegir(tester, 'Estas vinculado a la universidad como:', 'Estudiante');
      await tester.enterText(find.widgetWithText(TextFormField, 'Codigo institucional'), '104619021');
      await m.elegir(tester, 'Selecciona tu facultad', 'fiet');
      await m.elegir(tester, 'Selecciona tu programa academico', 'Artes Plásticas');
      //ya registrado, /auth/token responde con su JWT
      m.adaptador.responder('POST', '/auth/token', 200, leerContrato('autenticacion', 'token_200_alumno'));
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      final registro = m.adaptador.peticionesA('POST', '/RegistroPerfilAlumno').single;
      //el registro es publico: sale sin JWT
      expect(registro.autorizacion, isNull);
      expect(m.adaptador.peticionesA('POST', '/auth/token'), hasLength(2));
      expect(m.almacenToken.token, 'jwt-del-alumno');
      expect(m.sesion.perfilSesion?.role, Roles.alumno);
    });

    testWidgets('$capa - $tipo - Cerrar sesion - las peticiones siguientes salen sin JWT', (tester) async {
      m.google.cuenta = CuentaGoogleFalsa(email: 'ana@unicauca.edu.co');
      m.adaptador.responder('POST', '/auth/token', 200, leerContrato('autenticacion', 'token_200'));
      await m.abrir(tester, ruta: AppRutas.InscripcionesGenerales);
      await m.iniciarSesionConGoogle(tester);

      await m.cerrarSesion(tester);

      expect(m.almacenToken.hayToken, isFalse);
      expect(m.google.llamadasSalir, 1);
    });
  });
}
