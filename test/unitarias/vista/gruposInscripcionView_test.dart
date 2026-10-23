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
}
