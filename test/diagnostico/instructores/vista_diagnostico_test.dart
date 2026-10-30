@Tags(['diagnostico'])
library;

import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexioninstructoresFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//diagnostico de la pantalla "Instructores" del menu del coordinador (plan-
//diagnostico-instructores-facultades.md, H-07): la ruta real de
//route_generator, con el ServicioInstructor de la raiz sobre su doble y la
//sesion del coordinador. Afirma el comportamiento CORRECTO
void main() {
  const String capa = "vista";
  const String tipo = "diagnostico";

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
      Servicioautenticacion(Autenticacionrepositorio(conexion: ConexionautenticacionFalsa())),
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

  group('Pantalla Instructores (diagnostico de la vista):', () {
    //el montaje es valido: la ruta abre la pantalla
    testWidgets('$capa - $tipo - Pantalla instructores - control IT-03 - la ruta abre la pantalla', (tester) async {
      await abrirInstructores(tester);

      expect(find.text('Listado instructores'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Pantalla instructores - BUG IT-03 - muestra los instructores del backend y no otros', (tester) async {
      await abrirInstructores(tester);

      expect(find.text('Instructor 0'), findsNothing, reason: 'tarjeta inventada por la pantalla');
      expect(conexion.llamadasInstructores, 1, reason: 'la pantalla no pidio los instructores');
      expect(find.textContaining('Luis Paz'), findsOneWidget);
    });
  });
}
