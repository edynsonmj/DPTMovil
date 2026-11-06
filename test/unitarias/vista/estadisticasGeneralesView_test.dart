import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/presentation/view/views/estadisticas/estadisticasGeneralesView.dart';
import 'package:dpt_movil/presentation/view/widgets/graficoBarrasAgrupado.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionEstadisticasFalsa.dart';
import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//widget test de la pantalla de estadisticas (fase 7c): se monta con el vm
//que crea la ruta estadisticasGenerales y el doble de la conexion. El rango
//se fija llamando al vm, como lo hace el dialogo de fechas al confirmar
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  late ConexionEstadisticasFalsa conexion;
  late EstadisticasViewModel vm;

  EstadisticaModelo modelo(String leyenda) => EstadisticaModelo(
    leyenda1: leyenda,
    leyenda2: 'Iniciacion',
    leyenda3: '2026',
    leyenda4: '1',
    clases: 2,
    horas: 4,
    minutos: 0,
    duracion: 240,
  );

  setUp(() {
    conexion =
        ConexionEstadisticasFalsa()
          ..respuestaCategorias = RespuestaModelo(
            codigoHttp: 200,
            datos: [modelo('Deportes')],
          )
          ..respuestaCursos = RespuestaModelo(
            codigoHttp: 200,
            datos: [modelo('Deportes')],
          )
          ..respuestaGrupos = RespuestaModelo(
            codigoHttp: 200,
            datos: [modelo('Deportes')],
          );
    vm = EstadisticasViewModel(
      ServicioEstadisticas(EstadisticasRespositorio(conexion: conexion)),
    );
  });

  //mismo arbol que en la app: la sesion global y el vm de la ruta
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
          ChangeNotifierProvider.value(value: vm),
        ],
        child: const MaterialApp(home: EstadisticasGeneralesView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('$capa - $tipo - Estadisticas - sin rango no pide nada', (
    tester,
  ) async {
    await montar(tester);

    expect(
      find.text('Seleccione un rango de tiempo antes de continuar'),
      findsOneWidget,
    );
    expect(find.byType(GraficoBarrasAgrupado), findsNothing);
    expect(conexion.llamadasCategorias, 0);
  });

  testWidgets('$capa - $tipo - Estadisticas - con rango pinta las tres graficas', (
    tester,
  ) async {
    await montar(tester);

    await vm.cargar('2026-01-01', '2026-12-31');
    await tester.pumpAndSettle();

    expect(find.text('2026-01-01'), findsOneWidget);
    expect(find.text('2026-12-31'), findsOneWidget);
    expect(find.byType(GraficoBarrasAgrupado), findsNWidgets(3));
    //leyendas de cada seccion, con el formato de la vista
    expect(find.text('Deportes'), findsOneWidget);
    expect(find.text('Iniciacion - Deportes'), findsOneWidget);
    expect(find.text('2026.1:Iniciacion - Deportes'), findsOneWidget);
    //una sola carga por rango aunque la pantalla se reconstruya
    await tester.pump();
    expect(conexion.llamadasCategorias, 1);
    expect(conexion.llamadasGrupos, 1);
  });

  testWidgets('$capa - $tipo - Estadisticas - un error en una seccion no tumba las otras', (
    tester,
  ) async {
    conexion.respuestaCursos = RespuestaModelo(
      codigoHttp: 500,
      error: ErrorModelo(
        codigoHttp: 500,
        mensaje: 'error del servidor',
        url: '/estadisticas/cursos',
        metodo: 'GET',
      ),
    );
    await montar(tester);

    await vm.cargar('2026-01-01', '2026-12-31');
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Código: 500 - error del servidor'), findsOneWidget);
    expect(find.byType(GraficoBarrasAgrupado), findsNWidgets(2));
  });
}
