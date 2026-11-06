@Tags(['diagnostico'])
library;

import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/presentation/view/views/autenticacion/AutenticacionView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integracion/montajeAutenticacion.dart';

//diagnostico del inicio de sesion y el registro con el menu lateral y las
//rutas reales sobre el transporte falso (plan-diagnostico-autenticacion.md).
//Afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista; los control deben quedar en verde
void main() {
  const String capa = "vista";
  const String tipo = "diagnostico";

  late MontajeAutenticacion m;

  setUp(() => m = MontajeAutenticacion());

  PerfilEntidad perfil(String rol) => PerfilEntidad(
    id: 'p1',
    nombre: 'Persona',
    correo: 'persona@unicauca.edu.co',
    tipoId: 'CC',
    sexo: 'F',
    role: rol,
  );

  //menu lateral → login por correo → 404 → pantalla de registro
  Future<void> abrirRegistro(WidgetTester tester) async {
    m.adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});
    await m.abrir(tester);
    await m.iniciarSesionConCorreo(tester, 'beto@unicauca.edu.co');
    expect(find.byType(Autenticacionview), findsOneWidget);
  }

  group('Registro (diagnostico de la pantalla):', () {
    //onChanged guarda _nombre sin setState; el siguiente setState (cualquier
    //desplegable) ve un nombre no vacio y cambia el campo por un Text
    testWidgets('$capa - $tipo - Registro - BUG AU-05 - el nombre sigue editable despues de elegir otro campo', (tester) async {
      await abrirRegistro(tester);

      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre completo'), 'Bet');
      await m.elegir(tester, 'Selecciona tu sexo', 'M');

      expect(find.widgetWithText(TextFormField, 'Nombre completo'), findsOneWidget);
    });

    //un 409 (o 400) cierra la pantalla con pop(false): el menu cierra la
    //sesion y muestra "Ha fallado el registro", sin el motivo y sin el
    //formulario lleno
    testWidgets('$capa - $tipo - Registro - BUG AU-06 - un 409 deja el formulario abierto y muestra el motivo', (tester) async {
      m.adaptador.responder('POST', '/RegistroPerfilAlumno', 409, {'mensaje': 'El perfil ya existe'});
      await abrirRegistro(tester);

      await m.llenarRegistro(tester);
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      expect(
        [find.byType(Autenticacionview).evaluate().length, find.textContaining('ya existe').evaluate().isNotEmpty],
        [1, true],
      );
    });

    //GUARDAR no se deshabilita mientras la peticion esta en curso
  });

  group('Inicio de sesion (diagnostico del menu lateral):', () {
    //el menu muestra 'Error: ${codigoHttp}'. El 401 sin cuerpo es lo que
    //responde hoy el backend local a /login sin JWT (AU-B01)
    testWidgets('$capa - $tipo - Login - BUG AU-08 - un 401 del backend muestra un mensaje legible, no solo el codigo', (tester) async {
      m.adaptador.responder('GET', '/login', 401);
      await m.abrir(tester);

      await m.iniciarSesionConCorreo(tester, 'ana@unicauca.edu.co');

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Error: 401'), findsNothing);
    });

    //cerrar sesion hace pushNamed(categorias) encima de lo que habia: la
    //pantalla del coordinador sigue en la pila y "atras" vuelve a ella
    testWidgets('$capa - $tipo - Cerrar sesion - BUG AU-09 - no quedan pantallas del rol anterior debajo de categorias', (tester) async {
      m.sesion.perfilSesion = perfil(Roles.coordinador);
      await m.abrir(tester, ruta: AppRutas.InscripcionesGenerales);
      expect(find.text('configuracion general'), findsOneWidget);

      await m.abrirMenu(tester);
      await tester.tap(find.text('Cerrar sesion'));
      await tester.pumpAndSettle();

      expect(m.sesion.perfilSesion, isNull);
      expect(find.text('configuracion general', skipOffstage: false), findsNothing);
    });

    testWidgets('$capa - $tipo - Rutas - control AU-10 - el coordinador abre las inscripciones generales', (tester) async {
      m.sesion.perfilSesion = perfil(Roles.coordinador);
      await m.abrir(tester, ruta: AppRutas.InscripcionesGenerales);

      expect(find.text('configuracion general'), findsOneWidget);
    });

    //solo el menu esconde la opcion; la ruta no mira el rol (como AS-01 en
    //la ruta clase)
    for (final rol in [Roles.alumno, Roles.instructor, null]) {
      testWidgets('$capa - $tipo - Rutas - BUG AU-10 - ${rol ?? 'sin sesion'} no abre las inscripciones generales del coordinador', (tester) async {
        if (rol != null) m.sesion.perfilSesion = perfil(rol);
        await m.abrir(tester, ruta: AppRutas.InscripcionesGenerales);

        expect(find.text('configuracion general'), findsNothing);
      });
    }
  });
}
