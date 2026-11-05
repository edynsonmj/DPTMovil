import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/view/views/grupos/GruposInscripcion.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexiongruposFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/conexioninscripcionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//widget test de la pantalla de inscripcion del alumno (fase 6): se monta con
//los mismos vms que crea la ruta gruposDisponiblesInscripcion, armados con
//dobles. Comprueba la tarjeta (horarios) y el flujo del boton Matricular
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  late ConexiongruposFalsa conexionGrupos;
  late ConexionhorariosFalsa conexionHorarios;
  late ConexioninscripcionFalsa conexionInscripcion;

  setUp(() {
    conexionGrupos = ConexiongruposFalsa()
      ..respuestaInscripcion = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          GrupoModelo(
            cat_titulo: 'Deportes',
            cur_nombre: 'Iniciacion',
            anio: 2026,
            iterable: 1,
            cupos: 20,
            fechaCreacion: '2026-10-23',
          ),
        ],
      );
    conexionHorarios = ConexionhorariosFalsa()
      ..respuestaHorarios = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          HorarioModelo(
            categoria: 'Deportes',
            curso: 'Iniciacion',
            anio: 2026,
            iterable: 1,
            dia: 'Lunes',
            horaInicio: '08:00',
            horaFin: '10:00',
            escenario: 'Coliseo',
          ),
        ],
      );
    conexionInscripcion = ConexioninscripcionFalsa()
      ..respuestaValidar = RespuestaModelo(codigoHttp: 200, datos: false)
      ..respuestaAgregar = RespuestaModelo(codigoHttp: 201);
  });

  //mismo arbol que en la app: la sesion global y los vms de la ruta
  Future<void> montar(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create:
                (_) => AutenticacionViewModel(
                  Servicioautenticacion(
                    Autenticacionrepositorio(
                      conexion: ConexionautenticacionFalsa(),
                    ),
                  ),
                  GoogleSignInFalso(),
                ),
          ),
          ChangeNotifierProvider(
            create:
                (_) => Gruposviewmodel(
                  Serviciogrupo(Gruporepositorio(conexion: conexionGrupos)),
                ),
          ),
          ChangeNotifierProvider(
            create:
                (_) => Horariosviewmodel(
                  Serviciohorario(
                    Horariorepositorio(conexion: conexionHorarios),
                  ),
                ),
          ),
          ChangeNotifierProvider(
            create:
                (_) => Inscripcionviewmodel(
                  Servicioinscripcion(
                    Inscripcionrepositorio(conexion: conexionInscripcion),
                  ),
                ),
          ),
        ],
        child: MaterialApp(home: Gruposinscripcion(alumnoId: 'alu1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('$capa - $tipo - Grupos de inscripcion - pinta la tarjeta con horarios', (
    tester,
  ) async {
    await montar(tester);

    expect(find.text('Iniciacion-2026-1'), findsOneWidget);
    expect(find.textContaining('Lunes: 08:00 - 10:00'), findsOneWidget);
    expect(find.text('Matricular'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Grupos de inscripcion - un error en horarios no rompe la tarjeta', (
    tester,
  ) async {
    //I3: antes el cast sin revisar el codigo lanzaba una excepcion
    conexionHorarios.respuestaHorarios = RespuestaModelo(codigoHttp: 500);

    await montar(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Iniciacion-2026-1'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Grupos de inscripcion - matricular muestra el exito', (
    tester,
  ) async {
    await montar(tester);

    await tester.tap(find.text('Matricular'));
    await tester.pumpAndSettle();

    expect(conexionInscripcion.ultimaAgregada?.alumnoId, 'alu1');
    expect(conexionInscripcion.ultimaAgregada?.iterable, 1);
    expect(find.text('Te has inscrito al grupo'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Grupos de inscripcion - tras matricular el boton cambia', (
    tester,
  ) async {
    await montar(tester);
    //el backend ya responde que esta inscrito cuando se vuelve a validar
    conexionInscripcion.respuestaValidar = RespuestaModelo(
      codigoHttp: 200,
      datos: true,
    );

    await tester.tap(find.text('Matricular'));
    await tester.pumpAndSettle();
    //se cierra el dialogo de exito
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Quitar matrícula'), findsOneWidget);
    expect(find.text('Matricular'), findsNothing);
  });

  //IN-09: sin poder consultar la inscripcion la tarjeta pintaba "Matricular"
  //como si el alumno no estuviera inscrito
  testWidgets('$capa - $tipo - Grupos de inscripcion - si no se puede consultar la inscripcion lo dice y deja reintentar', (
    tester,
  ) async {
    conexionInscripcion.respuestaValidar = RespuestaModelo(
      codigoHttp: 503,
      error: ErrorModelo(codigoHttp: 503, mensaje: 'No hay conexion', url: '/validarInscripcion', metodo: 'GET'),
    );

    await montar(tester);

    expect(find.text('Matricular'), findsNothing);
    expect(find.text('Quitar matrícula'), findsNothing);
    expect(find.textContaining('No se pudo consultar tu inscripción'), findsOneWidget);

    //vuelve la red: reintentar consulta solo ese grupo y pinta el boton
    conexionInscripcion.respuestaValidar = RespuestaModelo(codigoHttp: 200, datos: false);
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.text('Matricular'), findsOneWidget);
    expect(conexionInscripcion.llamadasValidar, 2);
  });

  //IN-10: tras inscribirse, si la revalidacion fallaba el boton volvia a
  //"Matricular" aunque el backend ya tenia la inscripcion
  testWidgets('$capa - $tipo - Grupos de inscripcion - si tras matricular no se puede confirmar no vuelve a Matricular', (
    tester,
  ) async {
    await montar(tester);
    conexionInscripcion.respuestaValidar = RespuestaModelo(
      codigoHttp: 503,
      error: ErrorModelo(codigoHttp: 503, mensaje: 'No hay conexion', url: '/validarInscripcion', metodo: 'GET'),
    );

    await tester.tap(find.text('Matricular'));
    await tester.pumpAndSettle();
    expect(find.text('Te has inscrito al grupo'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text('Matricular'), findsNothing);
    expect(find.textContaining('No se pudo consultar tu inscripción'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Grupos de inscripcion - cada grupo se pide una sola vez', (
    tester,
  ) async {
    //dos grupos: antes cada rebuild repetia horarios y validacion de todos
    conexionGrupos.respuestaInscripcion = RespuestaModelo(
      codigoHttp: 200,
      datos: [
        for (final iterable in [1, 2])
          GrupoModelo(
            cat_titulo: 'Deportes',
            cur_nombre: 'Iniciacion',
            anio: 2026,
            iterable: iterable,
            cupos: 20,
            fechaCreacion: '2026-10-23',
          ),
      ],
    );
    await montar(tester);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(conexionHorarios.llamadasHorarios, 2);
    expect(conexionInscripcion.llamadasValidar, 2);

    //matricular en el primero solo vuelve a validar ese grupo (J3)
    await tester.tap(find.text('Matricular').first);
    await tester.pumpAndSettle();

    expect(conexionHorarios.llamadasHorarios, 2);
    expect(conexionInscripcion.llamadasValidar, 3);
    expect(conexionInscripcion.iterablesValidados.last, 1);
  });
}
