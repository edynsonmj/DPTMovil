@Tags(['diagnostico'])
library;

import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

//diagnostico transversal (fase 4): DialogError lo usan todas las pantallas
//para mostrar un Fallo. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "vista";
  const String tipo = "diagnostico";

  Future<void> mostrar(WidgetTester tester, String mensaje) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DialogError(titulo: 'Error', mensaje: mensaje, codigo: 503),
      ),
    );
  }

  //las dos ramas del dialogo: mensaje de texto y mensaje json desglosado
  testWidgets('$capa - $tipo - DialogError - BUG X-01 - muestra el codigo con mensaje de texto', (
    tester,
  ) async {
    await mostrar(tester, 'No hay conexion a internet');

    expect(find.textContaining('503'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - DialogError - BUG X-01 - muestra el codigo con mensaje json', (
    tester,
  ) async {
    await mostrar(tester, '{"mensaje": "No hay conexion a internet"}');

    expect(find.textContaining('503'), findsOneWidget);
  });
}
