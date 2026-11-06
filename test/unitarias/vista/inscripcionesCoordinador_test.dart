import 'package:dpt_movil/presentation/view/widgets/mini_tarjeta.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integracion/montajeInscripciones.dart';

//pantallas de inscripciones del coordinador (plan de abrir inscripciones).
//Nacieron como pruebas de diagnostico de IN-01, IN-02 e IN-03 (fase 1, en
//rojo) y pasaron a verde en la fase 4 sin cambiar lo que afirman. Usan las
//rutas reales y la cadena real de grupos sobre el transporte falso, con las
//respuestas observadas del backend (test/contratos/inscripciones)
void main() {
  const String capa = "vista";
  const String tipo = "widget";

  late MontajeInscripciones app;

  setUp(() {
    app = MontajeInscripciones();
  });

  //la primera tarjeta de grupo de la lista (un grupo del backend; antes de la
  //fase 4 era la ficticia "grupo 0")
  Future<void> abrirPrimerGrupo(WidgetTester tester) async {
    final tarjeta = find.byType(MiniTarjeta).first;
    await tester.ensureVisible(tarjeta);
    await tester.pumpAndSettle();
    await tester.tap(tarjeta);
    await tester.pumpAndSettle();
  }

  //la excepcion que haya quedado pendiente, para que el rojo la explique en
  //vez de esconderla detras de un finder que no encuentra nada
  String excepcion(WidgetTester tester) => '${tester.takeException() ?? '-'}';

  group('Inscripciones por grupo (InscripcionesParticulares):', () {
    testWidgets('$capa - $tipo - Particulares - control - la pantalla abre y carga las categorias del filtro', (
      tester,
    ) async {
      //control: si falla, el montaje esta mal y los rojos de abajo no prueban
      //nada
      await app.abrirParticulares(tester);

      expect(find.text('Configuracion especifica'), findsOneWidget);
      expect(app.conexionCategorias.llamadasListar, 1);
    });

    testWidgets('$capa - $tipo - Particulares - la lista muestra los grupos del backend', (
      tester,
    ) async {
      await app.abrirParticulares(tester);

      final faltas = <String>[];
      if (app.adaptador.peticionesA('GET', '/gruposNoEliminados').isEmpty) {
        faltas.add('no pide GET /gruposNoEliminados');
      }
      if (find.textContaining('grupo 0').evaluate().isNotEmpty) {
        faltas.add('muestra grupos ficticios ("grupo 0")');
      }
      if (find.textContaining('Curso Categoria Fase 4').evaluate().isEmpty ||
          find.textContaining('curso prueba').evaluate().isEmpty) {
        faltas.add('no muestra los cursos de los grupos del backend');
      }
      if (find.byType(MiniTarjeta).evaluate().length != 3) {
        faltas.add(
          'muestra ${find.byType(MiniTarjeta).evaluate().length} tarjetas '
          'en vez de los 3 grupos del backend',
        );
      }

      expect(faltas, isEmpty);
    });

    testWidgets('$capa - $tipo - Particulares - confirmar Abrir pide abrir las inscripciones de ese grupo', (
      tester,
    ) async {
      await app.abrirParticulares(tester);
      await abrirPrimerGrupo(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Abrir'));
      await tester.pumpAndSettle();
      //el cierre es obligatorio: se acepta el dia que propone el selector
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      final enviadas = app.adaptador.peticionesA('PATCH', '/grupo/periodo');
      expect(enviadas, hasLength(1), reason: 'excepcion: ${excepcion(tester)}');
      final grupo = (enviadas.single.cuerpo['grupos'] as List).single as Map;
      expect(grupo.keys, containsAll(['categoria', 'curso', 'anio', 'iterable']));
      expect(MontajeInscripciones.categoriasDelContrato, contains(grupo['categoria']));
    });

    testWidgets('$capa - $tipo - Particulares - confirmar Cerrar pide cerrar las inscripciones de ese grupo', (
      tester,
    ) async {
      await app.abrirParticulares(tester);
      await abrirPrimerGrupo(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Cerrar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      expect(
        app.adaptador.peticionesA('PATCH', '/grupo/inscripciones'),
        hasLength(1),
        reason: 'excepcion: ${excepcion(tester)}',
      );
    });

    testWidgets('$capa - $tipo - Particulares - programar envia la fecha elegida como apertura', (
      tester,
    ) async {
      await app.abrirParticulares(tester);
      await abrirPrimerGrupo(tester);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Programar'));
      await tester.pumpAndSettle();
      //el selector abre en hoy: se acepta tal cual
      await tester.tap(find.text('Seleccionar fecha inicial'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      //sin fecha final no se ofrece confirmar: el cierre es obligatorio
      expect(find.text('Confirmar'), findsNothing);
      await tester.tap(find.text('Seleccionar fecha final'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      //confirmar en el dialogo de fechas y luego en el de programacion
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();
      final error = excepcion(tester);
      if (find.text('Confirmar').evaluate().isNotEmpty) {
        await tester.tap(find.text('Confirmar').last);
        await tester.pumpAndSettle();
      }

      final hoy = DateTime.now();
      final hoyTexto =
          '${hoy.year}-${hoy.month.toString().padLeft(2, '0')}-${hoy.day.toString().padLeft(2, '0')}';
      final enviadas = app.adaptador.peticionesA('PATCH', '/grupo/periodo');
      expect(
        enviadas,
        hasLength(1),
        reason: 'excepcion al confirmar: $error / despues: ${excepcion(tester)}',
      );
      expect(enviadas.single.cuerpo['fechaApertura'], hoyTexto);
      expect(enviadas.single.cuerpo['fechaCierre'], hoyTexto);
    });
  });

  group('Inscripciones por categoria (InscripcionesGenerales, decision D1):', () {
    testWidgets('$capa - $tipo - Generales - sin endpoint por categoria las acciones no se ofrecen', (
      tester,
    ) async {
      await app.abrirGenerales(tester);
      //elegir una categoria es lo que hoy hace aparecer los botones
      await tester.tap(find.byType(DropdownMenu).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Categoria Fase 4').last);
      await tester.pumpAndSettle();

      //D1: mientras el backend no tenga un endpoint por categoria, abrir,
      //cerrar y programar no deben estar disponibles (ausentes o
      //deshabilitados), porque hoy confirman sin hacer nada
      final ofrecidas = <String>[];
      for (final accion in ['Abrir', 'Cerrar', 'Programar']) {
        final boton = find.widgetWithText(OutlinedButton, accion);
        if (boton.evaluate().isEmpty) continue;
        if (tester.widget<OutlinedButton>(boton).onPressed != null) {
          ofrecidas.add(accion);
        }
      }

      expect(ofrecidas, isEmpty);
    });

    //nacio como diagnostico de CAT-05 (cargarCategorias(context) mostraba
    //todos los errores con codigo 204). El vm ahora devuelve el Fallo y la
    //pantalla abre el dialogo con el codigo que llego
    testWidgets('$capa - $tipo - Generales - un 500 al cargar las categorias se muestra con su codigo', (
      tester,
    ) async {
      app.conexionCategorias.respuestaListar = RespuestaModelo(
        codigoHttp: 500,
        error: ErrorModelo(
          codigoHttp: 500,
          mensaje: 'error interno',
          url: '/categorias2',
          metodo: 'GET',
        ),
      );

      await app.abrirGenerales(tester);

      final dialogo = tester.widget<DialogError>(find.byType(DialogError));
      expect(dialogo.codigo, 500, reason: '${dialogo.titulo}: ${dialogo.mensaje}');
    });
  });
}
