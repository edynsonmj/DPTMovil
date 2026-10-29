@Tags(['diagnostico'])
library;

import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integracion/montajeAtenciones.dart';

//diagnostico de punta a punta (fase 5): mismo montaje que
//test/integracion/atenciones_integracion_test.dart (rutas reales y cadena
//real de atenciones sobre el transporte falso). Afirman el comportamiento
//CORRECTO; se espera que salgan rojas. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

  late MontajeAtenciones app;

  setUp(() {
    app = MontajeAtenciones();
  });

  testWidgets('$capa - $tipo - Toma de asistencia - BUG AS-07 - un POST 201 se muestra como exito', (
    tester,
  ) async {
    app.adaptador.responder('POST', '/atenciones', 201);
    await app.abrirClase(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    //lo que ve el instructor, para la evidencia del registro
    final dialogo =
        tester
            .widgetList<Text>(
              find.descendant(
                of: find.byType(AlertDialog),
                matching: find.byType(Text),
              ),
            )
            .map((t) => t.data)
            .toList();

    //la asistencia quedo guardada: el instructor debe verlo asi
    expect(app.adaptador.peticionesA('POST', '/atenciones').length, 1);
    expect(
      find.text('Error al registrar atenciones'),
      findsNothing,
      reason: 'el dialogo dice: $dialogo',
    );
    expect(find.text('Atenciones registradas'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Toma de asistencia - BUG AS-02 - el doble toque no duplica el registro', (
    tester,
  ) async {
    final pausa = app.adaptador.retener('POST', '/atenciones');
    await app.abrirClase(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pump();
    //el primer envio sigue en la red y la pantalla no muestra nada
    await tester.tap(find.text('Guardar'), warnIfMissed: false);
    await tester.pump();
    pausa.complete();
    await tester.pumpAndSettle();

    expect(app.adaptador.peticionesA('POST', '/atenciones').length, 1);
    expect(find.byType(Claseview), findsWidgets);
  });
}
