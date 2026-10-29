import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import 'montajeInscripciones.dart';

//integracion local de abrir y cerrar inscripciones (plan de abrir
//inscripciones, fase 5): rutas reales, PeriodoInscripcionViewModel y la
//cadena real de grupos sobre el transporte falso, sin backend. El estado se
//pinta con la fecha real (la ruta no fija el reloj), asi que las respuestas
//del backend que deciden el estado se arman con la fecha de hoy
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late MontajeInscripciones app;

  setUp(() {
    app = MontajeInscripciones();
  });

  String hoyTexto() {
    final hoy = DateTime.now();
    return '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
  }

  //el grupo sin periodo del contrato (Categoria Fase 4 / 2), tal como lo
  //devolveria el backend tras abrirlo hoy sin fecha limite
  Map<String, dynamic> grupoAbiertoHoy() => {
    ...(leerContrato('inscripciones', 'gruposNoEliminados_200') as List)[1],
    'fechaInscripcionApertura': hoyTexto(),
    'fechaIncripcionCierre': null,
  };

  const tituloSinPeriodo = 'Curso Categoria Fase 4 2026-2';

  Finder chipDe(String titulo, String estado) => find.descendant(
    of: find.widgetWithText(MiniTarjeta, titulo),
    matching: find.text(estado),
  );

  Future<void> tocar(WidgetTester tester, Finder destino) async {
    await tester.ensureVisible(destino);
    await tester.pumpAndSettle();
    await tester.tap(destino);
    await tester.pumpAndSettle();
  }

  testWidgets('$capa - $tipo - Abrir inscripciones - el coordinador abre un grupo y la lista lo muestra abierto', (
    tester,
  ) async {
    app.adaptador.responder(
      'PUT',
      '/abrirInscripcionesGrupo',
      200,
      grupoAbiertoHoy(),
    );
    await app.abrirParticulares(tester);
    expect(chipDe(tituloSinPeriodo, 'Sin abrir'), findsOneWidget);

    await tocar(tester, find.text(tituloSinPeriodo));
    await tocar(tester, find.widgetWithText(OutlinedButton, 'Abrir'));
    await tocar(tester, find.text('Confirmar'));

    expect(find.text('Operacion exitosa'), findsOneWidget);
    await tocar(tester, find.text('OK'));

    //una carga y una apertura: tras abrir no se recarga la lista
    expect(
      app.adaptador.peticiones.map((p) => '${p.metodo} ${p.ruta}'),
      ['GET /gruposNoEliminados', 'PUT /abrirInscripcionesGrupo'],
    );
    final enviada =
        app.adaptador.peticionesA('PUT', '/abrirInscripcionesGrupo').single;
    expect(enviada.uri.queryParameters, {
      'categoria': 'Categoria Fase 4',
      'curso': 'Curso Categoria Fase 4',
      'anio': '2026',
      'iterable': '2',
    });
    //abrir desde hoy sin limite: no se envian fechas
    expect(enviada.cuerpo, isEmpty);
    expect(chipDe(tituloSinPeriodo, 'Abiertas'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Abrir inscripciones - un rechazo del backend se muestra y el grupo no cambia', (
    tester,
  ) async {
    app.adaptador.responder(
      'PUT',
      '/abrirInscripcionesGrupo',
      400,
      leerContrato('inscripciones', 'abrir_400_cierre'),
    );
    await app.abrirParticulares(tester);

    await tocar(tester, find.text(tituloSinPeriodo));
    await tocar(tester, find.widgetWithText(OutlinedButton, 'Abrir'));
    await tocar(tester, find.text('Confirmar'));

    expect(find.text('Error en las inscripciones del grupo'), findsOneWidget);
    //DialogError desglosa el json del backend: clave y mensaje
    expect(find.textContaining('cierreValido'), findsOneWidget);
    await tocar(tester, find.text('Cerrar').last);
    expect(chipDe(tituloSinPeriodo, 'Sin abrir'), findsOneWidget);
  });

  testWidgets('$capa - $tipo - Filtrar grupos - la categoria elegida deja solo sus grupos', (
    tester,
  ) async {
    await app.abrirParticulares(tester);
    expect(find.byType(MiniTarjeta), findsNWidgets(3));

    await tocar(tester, find.byType(DropdownMenu).first);
    //la opcion del menu, no el subtitulo de la tarjeta, que lleva el mismo
    //texto
    await tocar(
      tester,
      find.descendant(
        of: find.byType(MenuItemButton),
        matching: find.text('prueba_actualizar_20260817183250444203'),
      ),
    );

    expect(find.byType(MiniTarjeta), findsOneWidget);
    expect(find.text('curso prueba 2026-2'), findsOneWidget);
    //filtrar no vuelve a pedir los grupos al backend
    expect(app.adaptador.peticionesA('GET', '/gruposNoEliminados'), hasLength(1));
  });
}
