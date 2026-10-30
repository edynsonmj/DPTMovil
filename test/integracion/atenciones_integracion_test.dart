import 'package:dio/dio.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'montajeAtenciones.dart';

//integracion local de la toma de asistencia (fase 5 del diagnostico): rutas
//reales y cadena real de atenciones sobre el transporte falso, sin backend.
//Solo comportamiento que se espera correcto; los recorridos que destapan
//bugs estan en test/diagnostico/atenciones/integracion_diagnostico_test.dart
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late MontajeAtenciones app;

  setUp(() {
    app = MontajeAtenciones();
  });

  List<bool?> marcas(WidgetTester tester) =>
      tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .map((c) => c.value)
          .toList();

  testWidgets('$capa - $tipo - Toma de asistencia - el instructor del grupo registra de punta a punta', (
    tester,
  ) async {
    await app.abrirClase(tester);

    //la ruta clase creo el vm y cargo una vez, con los datos del grupo
    expect(find.byType(Claseview), findsOneWidget);
    final pedida = app.adaptador.peticionesA('GET', '/asistenciasClase').single;
    expect(pedida.uri.queryParameters, {'idClase': '210'});
    expect(marcas(tester), [false, false, true]);

    //marca a Ana y a Luis y desmarca a Marta
    for (final indice in [0, 1, 2]) {
      await tester.tap(find.byType(Checkbox).at(indice));
      await tester.pumpAndSettle();
    }
    expect(marcas(tester), [true, true, false]);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    //una sola peticion de cada tipo, en orden: cargar y despues registrar
    expect(
      app.adaptador.peticiones.map((p) => '${p.metodo} ${p.ruta}'),
      ['GET /asistenciasClase', 'POST /asistenciasClase'],
    );
    final enviada = app.adaptador.peticionesA('POST', '/asistenciasClase').single;
    expect(enviada.uri.queryParameters, {'idClase': '210'});
    expect(enviada.cuerpo, [
      {'idPerfil': '1061001', 'asistio': true},
      {'idPerfil': '1061002', 'asistio': true},
      {'idPerfil': '1061003', 'asistio': false},
    ]);

    //aviso de exito y regreso a la pantalla del grupo
    expect(find.text('Atenciones registradas'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(Claseview), findsNothing);
    expect(find.text(MontajeAtenciones.textoClase), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Toma de asistencia - sin red al guardar se avisa y se conservan las marcas', (
    tester,
  ) async {
    app.adaptador.fallar(
      'POST',
      '/asistenciasClase',
      DioExceptionType.connectionError,
    );
    await app.abrirClase(tester);
    await tester.tap(find.byType(Checkbox).at(0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('Error al registrar atenciones'), findsOneWidget);
    expect(find.text('No hay conexion a internet'), findsOneWidget);
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();

    //sigue en la clase con lo que marco, para reintentar
    expect(find.byType(Claseview), findsOneWidget);
    expect(marcas(tester), [true, false, true]);
  });

  testWidgets('$capa - $tipo - Toma de asistencia - error del backend al cargar se ve en la clase', (
    tester,
  ) async {
    app.adaptador.responder(
      'GET',
      '/asistenciasClase',
      404,
      'No se encontro la clase',
    );

    await app.abrirClase(tester);

    expect(find.byType(Claseview), findsOneWidget);
    expect(find.textContaining('Código: 404'), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });
}
