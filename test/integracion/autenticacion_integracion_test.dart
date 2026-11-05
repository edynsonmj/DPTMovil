import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/presentation/view/views/autenticacion/AutenticacionView.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
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
      expect(find.text('Estadisticas'), findsOneWidget);
      expect(find.text('Cerrar sesion'), findsOneWidget);
      expect(find.text('Iniciar sesion'), findsNothing);
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

      await m.abrirMenu(tester);
      await tester.tap(find.text('Cerrar sesion'));
      await tester.pumpAndSettle();

      expect(m.sesion.perfilSesion, isNull);
      expect(m.google.llamadasSalir, 1);
      expect(find.text('Categorias'), findsWidgets);
    });
  });
}
