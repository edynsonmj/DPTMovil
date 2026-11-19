import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseFormulario.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//BK-04: sin horario el dia de la clase el backend exige una justificacion de
//10 a 500 caracteres, sin espacios al inicio ni al final; con horario la
//ignora y calcula la duracion. El formulario carga los horarios del grupo
//para saber que dias la piden. Cadena real del vm hasta las conexiones de
//clases y horarios, con el transporte falso debajo
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late Dio dio;

  //lunes, martes y miercoles de una misma semana
  final lunes = DateTime(2026, 10, 26);
  final martes = DateTime(2026, 10, 27);
  final miercoles = DateTime(2026, 10, 28);

  //horarios del grupo con los dias como los nombra el backend
  List<Map<String, dynamic>> horariosEn(List<String> dias) {
    final base = (leerContrato('horarios', 'horarios_200') as List).first as Map;
    return [
      for (var i = 0; i < dias.length; i++)
        {...Map<String, dynamic>.from(base), 'id': 30 + i, 'dia': dias[i]},
    ];
  }

  Clasesviewmodel formulario() =>
      Clasesviewmodel(
        Servicioclase(Claserepositorio(cliente: Conexionclasesremoto(dio))),
        Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
      )..inicializarGrupo('Categoria Fase 4', 'Curso Categoria Fase 4', 2026, 1, '2');

  Future<Clasesviewmodel> formularioConHorarios(List<String> dias) async {
    adaptador.responder('GET', '/horarios', 200, horariosEn(dias));
    final vm = formulario();
    await vm.cargarHorarios();
    return vm;
  }

  Map cuerpoEnviado() =>
      adaptador.peticionesA('POST', '/claseGrupo').single.cuerpo as Map;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    dio = crearDioFalso(adaptador);
  });

  group('Justificacion de la clase (BK-04):', () {
    test('$capa - $tipo - Horarios del grupo - pide la llave del grupo y decide por el dia de la semana', () async {
      final vm = formulario();
      expect(vm.requiereJustificacion(lunes), isNull, reason: 'sin cargar no se sabe');

      adaptador.responder('GET', '/horarios', 200, horariosEn(['Lunes']));
      await vm.cargarHorarios();

      expect(adaptador.peticionesA('GET', '/horarios').single.uri.queryParameters, {
        'categoria': 'Categoria Fase 4',
        'curso': 'Curso Categoria Fase 4',
        'anio': '2026',
        'iterable': '1',
      });
      expect(vm.requiereJustificacion(lunes), isFalse);
      expect(vm.requiereJustificacion(martes), isTrue);
      expect(vm.requiereJustificacion(null), isNull);
    });

    test('$capa - $tipo - Horarios del grupo - sin horarios todos los dias la piden; si fallan no se decide', () async {
      final sinHorarios = await formularioConHorarios([]);
      expect(sinHorarios.requiereJustificacion(lunes), isTrue);

      adaptador.responder('GET', '/horarios', 500, 'error interno');
      final conError = formulario();
      await conError.cargarHorarios();
      expect(conError.requiereJustificacion(lunes), isNull);
      expect(conError.cargandoHorarios, isFalse);
    });

    //el backend compara con equalsIgnoreCase contra 'MIERCOLES', sin tilde:
    //la app sigue su regla para no contradecirlo (bug HO-06)
    test('$capa - $tipo - Horarios del grupo - el dia se compara como el backend: mayusculas da igual, la tilde no', () async {
      final vm = await formularioConHorarios(['MIERCOLES']);
      expect(vm.requiereJustificacion(miercoles), isFalse);

      final conTilde = await formularioConHorarios(['Miércoles']);
      expect(conTilde.requiereJustificacion(miercoles), isTrue);
    });

    test('$capa - $tipo - Registrar clase - sin horario ese dia y sin justificacion no se envia', () async {
      final vm = await formularioConHorarios(['Lunes']);

      final r = await vm.registrarClase(fecha: martes, horasTexto: '2', justificacion: '   ');

      expect(r, isA<Fallo>());
      final fallo = r as Fallo;
      expect(fallo.codigo, 0);
      expect(fallo.mensaje, contains('no tiene horario ese dia'));
      expect(adaptador.peticionesA('POST', '/claseGrupo'), isEmpty);
    });

    test('$capa - $tipo - Registrar clase - una justificacion fuera de 10 a 500 caracteres no se envia', () async {
      final vm = await formularioConHorarios(['Lunes']);

      final corta = await vm.registrarClase(fecha: martes, horasTexto: '2', justificacion: 'Lluvia');
      final larga = await vm.registrarClase(fecha: martes, horasTexto: '2', justificacion: 'x' * 501);

      expect((corta as Fallo).mensaje, 'La justificacion debe tener entre 10 y 500 caracteres');
      expect(larga, isA<Fallo>());
      expect(adaptador.peticionesA('POST', '/claseGrupo'), isEmpty);
    });

    test('$capa - $tipo - Registrar clase - sin horario ese dia envia la justificacion sin espacios sobrantes', () async {
      adaptador.responder('POST', '/claseGrupo', 201);
      final vm = await formularioConHorarios(['Lunes']);

      final r = await vm.registrarClase(
        fecha: martes,
        horasTexto: '2',
        justificacion: '  Clase de reposicion acordada con el grupo \n',
      );

      expect(r, isA<Exito>());
      expect(cuerpoEnviado()['justificacion'], 'Clase de reposicion acordada con el grupo');
      expect(cuerpoEnviado()['fecha'], '2026-10-27');
    });

    test('$capa - $tipo - Registrar clase - con horario ese dia no envia la justificacion', () async {
      adaptador.responder('POST', '/claseGrupo', 201);
      final vm = await formularioConHorarios(['Lunes']);

      await vm.registrarClase(fecha: lunes, horasTexto: '2', justificacion: 'Texto que el backend ignoraria');

      expect(cuerpoEnviado().containsKey('justificacion'), isFalse);
    });

    //sin horarios cargados decide el backend: se envia lo que haya escrito y
    //su 422 llega con el motivo
    test('$capa - $tipo - Registrar clase - sin saber los horarios envia la justificacion si la hay', () async {
      adaptador.responder('GET', '/horarios', 500, 'error interno');
      adaptador.responder('POST', '/claseGrupo', 422, {
        'codigoError': 'GC-0021',
        'mensaje': 'El grupo no tiene horario asignado ese dia -- debe indicar una justificacion',
        'codigoHttp': 422,
      });
      final vm = formulario();
      await vm.cargarHorarios();

      final r = await vm.registrarClase(fecha: martes, horasTexto: '2');

      expect(cuerpoEnviado().containsKey('justificacion'), isFalse);
      final fallo = r as Fallo;
      expect(fallo.codigo, 422);
      expect(fallo.mensaje, contains('debe indicar una justificacion'));
    });
  });

  group('Formulario de clase con justificacion (BK-04):', () {
    //el formulario abre con la fecha de hoy
    final hoy = DateTime.now();
    const nombres = ['Lunes', 'Martes', 'Miercoles', 'Jueves', 'Viernes', 'Sabado', 'Domingo'];
    final diaDeHoy = nombres[hoy.weekday - 1];
    final otroDia = nombres[hoy.weekday % 7];

    Future<void> abrirFormulario(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider(
            //como la ruta: carga los horarios del grupo al abrir
            create: (_) => formulario()..cargarHorarios(),
            child: const Claseformulario(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('$capa - $tipo - Formulario de clase - sin horario hoy pide la justificacion y la envia', (tester) async {
      adaptador.responder('GET', '/horarios', 200, horariosEn([otroDia]));
      adaptador.responder('POST', '/claseGrupo', 201);
      await abrirFormulario(tester);

      expect(find.text('Justificación (el grupo no tiene horario ese día)'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, '2');
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no tiene horario ese dia'), findsOneWidget);
      expect(adaptador.peticionesA('POST', '/claseGrupo'), isEmpty);
      await tester.tap(find.text('Cerrar'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('justificacionClase')), 'Clase de reposicion por el festivo');
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();

      expect(find.text('Clase registrada'), findsOneWidget);
      expect(cuerpoEnviado()['justificacion'], 'Clase de reposicion por el festivo');
    });

    testWidgets('$capa - $tipo - Formulario de clase - con horario hoy no muestra la justificacion', (tester) async {
      adaptador.responder('GET', '/horarios', 200, horariosEn([diaDeHoy]));
      await abrirFormulario(tester);

      expect(find.byKey(const Key('justificacionClase')), findsNothing);
      expect(find.textContaining('la duración se calcula del horario'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Formulario de clase - si los horarios fallan la justificacion queda opcional', (tester) async {
      adaptador.responder('GET', '/horarios', 500, 'error interno');
      await abrirFormulario(tester);

      expect(find.text('Justificación (si el grupo no tiene horario ese día)'), findsOneWidget);
    });
  });
}
