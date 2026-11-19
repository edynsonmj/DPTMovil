import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

//DialogError lo usan todas las pantallas para mostrar un Fallo. X-01
//(corregido el 2026-11-19) salio del diagnostico: el codigo se muestra
void main() {
  const String capa = "vista";
  const String tipo = "unitaria";

  Future<void> mostrar(WidgetTester tester, String mensaje) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DialogError(titulo: 'Error', mensaje: mensaje, codigo: 503),
      ),
    );
  }

  //las dos ramas del dialogo: mensaje de texto y mensaje json desglosado
  testWidgets('$capa - $tipo - DialogError - muestra el codigo con mensaje de texto', (
    tester,
  ) async {
    await mostrar(tester, 'No hay conexion a internet');

    expect(find.textContaining('503'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - DialogError - muestra el codigo con mensaje json', (
    tester,
  ) async {
    await mostrar(tester, '{"mensaje": "No hay conexion a internet"}');

    expect(find.textContaining('503'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - DialogError - un codigo 0 no se muestra', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DialogError(titulo: 'Error', mensaje: 'fallo local', codigo: 0)),
    );

    expect(find.text('fallo local'), findsOneWidget);
    expect(find.textContaining('Código'), findsNothing);
  });
}
