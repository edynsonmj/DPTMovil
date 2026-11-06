@Tags(['diagnostico'])
library;

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
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//diagnostico de la pantalla del alumno frente al backend nuevo: la pantalla
//real con su cadena real hasta las conexiones y el transporte falso debajo,
//con las respuestas observadas el 2026-11-05 (test/contratos/inscripciones).
//Afirman el comportamiento CORRECTO y salen rojas mientras el bug exista
void main() {
  const String capa = "vista";
  const String tipo = "diagnostico";
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
          ..responder('GET', '/validarInscripcion', 200, false);
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

  group('Pantalla de inscripcion frente al backend nuevo (diagnostico):', () {
    testWidgets('$capa - $tipo - Matricular - control BK-06 - con estado INSCRITO dice que se inscribio', (
      tester,
    ) async {
      adaptador.responder(
        'POST',
        '/inscripcion',
        201,
        leerContrato(modulo, 'inscripcion_201_inscrito'),
      );
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      expect(find.text('Te has inscrito al grupo'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Matricular - BUG BK-06 - con estado EN_ESPERA avisa de la lista de espera', (
      tester,
    ) async {
      adaptador.responder(
        'POST',
        '/inscripcion',
        201,
        leerContrato(modulo, 'inscripcion_201_en_espera'),
      );
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      expect(find.text('Te has inscrito al grupo'), findsNothing);
      expect(find.textContaining('lista de espera'), findsOneWidget);
    });

    //validarInscripcion solo cuenta INSCRITO: en lista de espera responde
    //false para siempre. /inscripcion/misCursos si trae el estado y
    //desvincular funciona, pero la tarjeta no ofrece salir de la lista
    testWidgets('$capa - $tipo - Tarjeta - BUG IN-15 - un alumno en lista de espera no ve Matricular y puede salir', (
      tester,
    ) async {
      adaptador.responder(
        'GET',
        '/inscripcion/misCursos',
        200,
        leerContrato(modulo, 'misCursos_200_en_espera'),
      );

      await montar(tester);

      expect(find.text('Matricular'), findsNothing);
      expect(find.textContaining('lista de espera'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Matricular - BUG IN-16 - el dialogo de un rechazo da el motivo sin la respuesta cruda', (
      tester,
    ) async {
      adaptador.responder(
        'POST',
        '/inscripcion',
        422,
        leerContrato(modulo, 'inscripcion_422_limite'),
      );
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      expect(find.byType(DialogError), findsOneWidget);
      //hoy DialogError lista cada clave: codigoError, codigoHttp, url y metodo
      expect(find.textContaining('codigoError'), findsNothing);
      expect(find.textContaining('http://'), findsNothing);
    });

    testWidgets('$capa - $tipo - Matricular - BUG IN-17 - un 401 sin cuerpo no abre un dialogo en blanco', (
      tester,
    ) async {
      adaptador.responder('POST', '/inscripcion', 401, '');
      await montar(tester);

      await tester.tap(find.text('Matricular'));
      await tester.pumpAndSettle();

      final dialogo = tester.widget<DialogError>(find.byType(DialogError));
      expect(dialogo.mensaje.trim(), isNotEmpty);
    });
  });
}
