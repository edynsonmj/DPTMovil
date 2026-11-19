import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/view/views/instructores/InstructorView.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexioninstructoresFalsa.dart';
import '../../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//pantalla "Instructores" del menu del coordinador por la ruta real de
//route_generator, con el ServicioInstructor de la raiz sobre su doble y la
//sesion del coordinador. Nacio como diagnostico de IT-03 (antes mostraba 20
//instructores inventados), corregido el 2026-11-19
void main() {
  const String capa = "vista";
  const String tipo = "unitaria";

  late ConexioninstructoresFalsa conexion;

  setUp(() {
    conexion = ConexioninstructoresFalsa()
      ..respuestaInstructores = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Instructormodelo(id: '2', nombre: 'Luis Paz', correo: 'luis@unicauca.edu.co', sexo: 'M'),
        ],
      );
  });

  //como el menu lateral del coordinador: un boton abre la ruta
  Future<void> abrirInstructores(WidgetTester tester) async {
    final sesion = AutenticacionViewModel(
      Servicioautenticacion(Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken())),
      GoogleSignInFalso(),
    )..perfilSesion = PerfilEntidad(
      id: 'coo1',
      nombre: 'Coordinacion',
      correo: 'coordinacion@unicauca.edu.co',
      tipoId: 'CC',
      sexo: 'F',
      role: Roles.coordinador,
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ServicioInstructor>(
            create: (_) => ServicioInstructor(Instructoresrepositorio(conexion: conexion)),
          ),
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: sesion),
        ],
        child: MaterialApp(
          onGenerateRoute: generateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRutas.instructores),
              child: const Text('Abrir pantalla'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir pantalla'));
    await tester.pumpAndSettle();
  }

  group('Pantalla Instructores:', () {
    testWidgets('$capa - $tipo - Pantalla instructores - la ruta abre la pantalla', (tester) async {
      await abrirInstructores(tester);

      expect(find.text('Listado instructores'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Pantalla instructores - muestra los instructores del backend y no otros', (tester) async {
      await abrirInstructores(tester);

      expect(find.text('Instructor 0'), findsNothing, reason: 'tarjeta inventada por la pantalla');
      expect(conexion.llamadasInstructores, 1, reason: 'la pantalla no pidio los instructores');
      expect(find.text('Luis Paz'), findsOneWidget);
      expect(find.text('luis@unicauca.edu.co'), findsOneWidget);
      //ya no estan los controles de la maqueta
      expect(find.text('AGREGAR INSTRUCTOR'), findsNothing);
      expect(find.text('seleccione una categoria'), findsNothing);
    });

    testWidgets('$capa - $tipo - Pantalla instructores - un error muestra el motivo y reintentar vuelve a pedir', (tester) async {
      conexion.respuestaInstructores = RespuestaModelo(
        codigoHttp: 500,
        error: ErrorModelo(codigoHttp: 500, mensaje: 'error interno', url: '/instructores', metodo: 'GET'),
      );
      await abrirInstructores(tester);

      expect(find.text('No se pudieron cargar los instructores'), findsOneWidget);
      expect(find.textContaining('error interno'), findsOneWidget);

      conexion.respuestaInstructores = RespuestaModelo(
        codigoHttp: 200,
        datos: [Instructormodelo(id: '3', nombre: 'Ana Ruiz', correo: 'ana@unicauca.edu.co', sexo: 'F')],
      );
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(conexion.llamadasInstructores, 2);
      expect(find.text('Ana Ruiz'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Pantalla instructores - sin instructores lo dice', (tester) async {
      conexion.respuestaInstructores = RespuestaModelo(codigoHttp: 200, datos: <Instructormodelo>[]);
      await abrirInstructores(tester);

      expect(find.text('No hay instructores registrados'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Pantalla instructores - tocar un instructor abre su pantalla', (tester) async {
      await abrirInstructores(tester);

      await tester.tap(find.text('Luis Paz'));
      await tester.pumpAndSettle();

      expect(find.byType(Instructorview), findsOneWidget);
    });
  });
}
