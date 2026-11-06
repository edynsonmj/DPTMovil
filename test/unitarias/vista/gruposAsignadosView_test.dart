import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/view/views/grupos/GruposAsignados.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/gruposViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/conexiongruposFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//widget test de la pantalla Grupos asignados del instructor (fase 6c): se
//monta con los vms que crea la ruta gruposAsignados, armados con dobles
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  late ConexiongruposFalsa conexionGrupos;
  late ConexionhorariosFalsa conexionHorarios;

  setUp(() {
    conexionGrupos = ConexiongruposFalsa()
      ..respuestaInstructor = RespuestaModelo(
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
              idInstructor: 'ins1',
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
            dia: 'Martes',
            horaInicio: '14:00',
            horaFin: '16:00',
            escenario: 'Piscina',
          ),
        ],
      );
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
                      conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken(),
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
        ],
        child: MaterialApp(home: GruposAsignados(instructorId: 'ins1')),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('$capa - $tipo - Grupos asignados - pinta los grupos del instructor', (
    tester,
  ) async {
    await montar(tester);

    expect(conexionGrupos.ultimoInstructor, 'ins1');
    expect(find.text('Iniciacion-2026-1'), findsOneWidget);
    expect(find.text('Iniciacion-2026-2'), findsOneWidget);
    expect(find.textContaining('Martes: 14:00 - 16:00'), findsNWidgets(2));
  });

  testWidgets('$capa - $tipo - Grupos asignados - horarios una vez por grupo', (
    tester,
  ) async {
    await montar(tester);
    //un rebuild ya no repite las peticiones
    await tester.pump();
    await tester.pumpAndSettle();

    expect(conexionHorarios.llamadasHorarios, 2);
  });
}
