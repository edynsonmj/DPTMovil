import 'package:dpt_movil/presentation/view/views/clase/claseView.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'montajeAtenciones.dart';

//errores de la toma de asistencia de punta a punta (AS-02, AS-07): mismo
//montaje que atenciones_integracion_test.dart. Registro:
//auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late MontajeAtenciones app;

  setUp(() {
    app = MontajeAtenciones();
  });

  testWidgets('$capa - $tipo - Toma de asistencia - un POST 201 se muestra como exito', (
    tester,
  ) async {
    app.adaptador.responder('PUT', '/clase/210/asistencia', 201);
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
    expect(app.adaptador.peticionesA('PUT', '/clase/210/asistencia').length, 1);
    expect(
      find.text('Error al registrar atenciones'),
      findsNothing,
      reason: 'el dialogo dice: $dialogo',
    );
    expect(find.text('Atenciones registradas'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Toma de asistencia - el doble toque no duplica el registro', (
    tester,
  ) async {
    final pausa = app.adaptador.retener('PUT', '/clase/210/asistencia');
    await app.abrirClase(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pump();
    //el primer envio sigue en la red y la pantalla no muestra nada
    await tester.tap(find.text('Guardar'), warnIfMissed: false);
    await tester.pump();
    pausa.complete();
    await tester.pumpAndSettle();

    expect(app.adaptador.peticionesA('PUT', '/clase/210/asistencia').length, 1);
    expect(find.byType(Claseview), findsWidgets);
  });
}
