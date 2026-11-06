import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionInscripcionRemoto.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/view/views/grupos/GruposInscripcion.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';
import '../dobles/conexionautenticacionFalsa.dart';
import '../dobles/googleSignInFalso.dart';

//la lista de espera en la pantalla del alumno: la pantalla real con su cadena
//real hasta las conexiones y el transporte falso debajo, con las respuestas
//observadas el 2026-11-05. Nacio del diagnostico de BK-06 e IN-15
void main() {
  const String capa = "integracion";
  const String tipo = "local";
  const String modulo = 'inscripciones';

  late AdaptadorHttpFalso adaptador;

  setUp(() {
    adaptador =
        AdaptadorHttpFalso()
          ..responder(
            'GET',
            '/gruposInscripcion',
            200,
            leerContrato(modulo, 'gruposInscripcion_200'),
          )
          ..responder('GET', '/horarios', 200, [])
          ..responder('GET', '/validarInscripcion', 200, false)
          ..responder('GET', '/inscripcion/misCursos', 200, []);
  });

  Future<void> montar(WidgetTester tester) async {
    final dio = crearDioFalso(adaptador);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create:
                (_) => AutenticacionViewModel(
                  Servicioautenticacion(
                    Autenticacionrepositorio(
                      conexion: ConexionautenticacionFalsa(),
                      almacenToken: AlmacenToken(),
                    ),
                  ),
                  GoogleSignInFalso(),
                ),
          ),
          ChangeNotifierProvider(
            create:
                (_) => Gruposviewmodel(
                  Serviciogrupo(
                    Gruporepositorio(conexion: Conexiongruposremoto(dio)),
                  ),
                ),
          ),
          ChangeNotifierProvider(
            create:
                (_) => Horariosviewmodel(
                  Serviciohorario(
                    Horariorepositorio(conexion: Conexionhorariosremoto(dio)),
                  ),
                ),
          ),
          ChangeNotifierProvider(
            create:
                (_) => Inscripcionviewmodel(
                  Servicioinscripcion(
                    Inscripcionrepositorio(
                      conexion: Conexioninscripcionremoto(dio),
                    ),
                  ),
                ),
          ),
        ],
        child: MaterialApp(home: Gruposinscripcion(alumnoId: '136438912')),
      ),
    );
    await tester.pumpAndSettle();
  }

  void estaEnLaLista() => adaptador.responder(
    'GET',
    '/inscripcion/misCursos',
    200,
    leerContrato(modulo, 'misCursos_200_en_espera'),
  );

  group('Lista de espera (pantalla → conexiones reales → transporte falso):', () {
    testWidgets('$capa - $tipo - Matricular - con estado INSCRITO dice que se inscribio', (tester) async {
      adaptador.responder('POST', '/inscripcion', 201, leerContrato(modulo, 'inscripcion_201_inscrito'));
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      expect(find.text('Te has inscrito al grupo'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Matricular - con estado EN_ESPERA avisa de la lista de espera y la tarjeta lo muestra', (tester) async {
      adaptador.responder('POST', '/inscripcion', 201, leerContrato(modulo, 'inscripcion_201_en_espera'));
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      expect(find.text('Te has inscrito al grupo'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(DialogExito),
          matching: find.textContaining('lista de espera'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('En lista de espera'), findsOneWidget);
      expect(find.text('Matricular'), findsNothing);
      //validar responderia false: no se pregunta
      expect(adaptador.peticionesA('GET', '/validarInscripcion'), hasLength(1));
    });

    testWidgets('$capa - $tipo - Tarjeta - un alumno en lista de espera no ve Matricular y puede salir', (tester) async {
      estaEnLaLista();

      await montar(tester);

      expect(find.text('Matricular'), findsNothing);
      expect(find.textContaining('lista de espera'), findsOneWidget);
      expect(find.text('Salir de la lista'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Tarjeta - salir de la lista desvincula y vuelve a Matricular', (tester) async {
      estaEnLaLista();
      adaptador.responder('PUT', '/desvincularInscripcion', 200, leerContrato(modulo, 'inscripcion_201_en_espera'));
      await montar(tester);

      await tester.tap(find.text('Salir de la lista'));
      await tester.pumpAndSettle();

      expect(adaptador.peticionesA('PUT', '/desvincularInscripcion'), hasLength(1));
      expect(find.text('Saliste de la lista de espera'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('En lista de espera'), findsNothing);
      expect(find.text('Matricular'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Tarjeta - si falla la consulta de la lista no ofrece Matricular y reintentar la recupera', (tester) async {
      adaptador.responder('GET', '/inscripcion/misCursos', 500, 'fallo interno');
      await montar(tester);

      expect(find.text('Matricular'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);

      estaEnLaLista();
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();

      expect(find.text('En lista de espera'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Tarjeta - un alumno inscrito no depende de la lista', (tester) async {
      adaptador
        ..responder('GET', '/validarInscripcion', 200, true)
        ..fallar('GET', '/inscripcion/misCursos', DioExceptionType.connectionError);

      await montar(tester);

      expect(find.text('Quitar matrícula'), findsOneWidget);
      expect(find.text('Reintentar'), findsNothing);
    });

    //nacieron del diagnostico de IN-16 e IN-17
    testWidgets('$capa - $tipo - Matricular - el dialogo de un rechazo da el motivo sin la respuesta cruda', (tester) async {
      adaptador.responder('POST', '/inscripcion', 422, leerContrato(modulo, 'inscripcion_422_limite'));
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      expect(find.byType(DialogError), findsOneWidget);
      expect(find.textContaining('maximo de 3 cursos activos'), findsOneWidget);
      expect(find.textContaining('codigoError'), findsNothing);
      expect(find.textContaining('http://'), findsNothing);
    });

    testWidgets('$capa - $tipo - Matricular - un 401 sin cuerpo no abre un dialogo en blanco', (tester) async {
      adaptador.responder('POST', '/inscripcion', 401, '');
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      final dialogo = tester.widget<DialogError>(find.byType(DialogError));
      expect(dialogo.mensaje, contains('sesión'));
    });
  });
}
