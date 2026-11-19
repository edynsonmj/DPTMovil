import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAlumnosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionClasesRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/claseRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioAlumno.dart';
import 'package:dpt_movil/domain/servicios/servicioClase.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/view/views/clase/claseFormulario.dart';
import 'package:dpt_movil/presentation/viewmodels/clasesViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/detalleGrupoViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 2 (plan-diagnostico-clases.md): el formulario
//de clase (Clasesviewmodel) y la pantalla del grupo (DetalleGrupoViewModel)
//con sus cadenas reales hasta las conexiones remotas y el transporte falso
//debajo. Solo se programan las rutas de clases: las demas secciones de la
//pantalla del grupo no se miran aqui
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late Dio dio;

  final grupo = Grupoentidad(
    categoria: 'Categoria Fase 4',
    curso: 'Curso Categoria Fase 4',
    anio: 2026,
    iterable: 1,
    cupos: 10,
    idInstructor: '2',
    fechaCreacion: '2026-10-22',
  );

  Servicioclase servicioClase() =>
      Servicioclase(Claserepositorio(cliente: Conexionclasesremoto(dio)));

  DetalleGrupoViewModel pantallaGrupo() => DetalleGrupoViewModel(
    grupo,
    ServicioCurso(CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)))),
    Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
    Servicioalumno(Alumnosrepositorio(cliente: Conexionalumnosremoto(dio))),
    servicioClase(),
  );

  Clasesviewmodel formulario() =>
      Clasesviewmodel(
        servicioClase(),
        Serviciohorario(Horariorepositorio(conexion: Conexionhorariosremoto(dio))),
      )..inicializarGrupo(grupo.categoria, grupo.curso, grupo.anio, grupo.iterable, '2');

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    dio = crearDioFalso(adaptador);
  });

  group('Clases (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Cargar clases - 200 pide la llave del grupo y convierte fecha y horas', () async {
      adaptador.responder('GET', '/clasesGrupo', 200, leerContrato('clases', 'clasesGrupo_200'));
      final vm = pantallaGrupo();

      await vm.cargarClases();

      expect(adaptador.peticionesA('GET', '/clasesGrupo').single.uri.queryParameters, {
        'categoria': 'Categoria Fase 4',
        'curso': 'Curso Categoria Fase 4',
        'anio': '2026',
        'iterable': '1',
      });
      expect(vm.clases.cargando, isFalse);
      expect(vm.clases.error, isNull);
      final primera = vm.clases.datos.first;
      expect(primera.codigo, 207);
      expect(primera.fecha, DateTime(2026, 10, 22));
      expect(primera.horas, 10);
    });

    test('$capa - $tipo - Cargar clases - grupo sin clases (200 [] y el antiguo GC-0002) es lista vacia sin error', () async {
      adaptador.responder('GET', '/clasesGrupo', 200, leerContrato('clases', 'clasesGrupo_vacio'));
      final vm = pantallaGrupo();
      await vm.cargarClases();
      expect(vm.clases.error, isNull);
      expect(vm.clases.datos, isEmpty);

      adaptador.responder('GET', '/clasesGrupo', 200, {
        'codigoError': 'GC-0002',
        'mensaje': 'El listado se encuentra vacio',
      });
      await vm.cargarClases();
      expect(vm.clases.error, isNull);
      expect(vm.clases.datos, isEmpty);
    });

    test('$capa - $tipo - Registrar clase - envia la clase del grupo con la fecha elegida y 201 es Exito', () async {
      adaptador.responder('POST', '/claseGrupo', 201);
      final fecha = DateTime(2026, 10, 28, 9, 15);

      final resultado = await formulario().registrarClase(fecha: fecha, horasTexto: ' 2 ');

      expect(resultado, isA<Exito>());
      expect(adaptador.peticionesA('POST', '/claseGrupo').single.cuerpo, {
        'codigo': null,
        'idGrupoCategoria': 'Categoria Fase 4',
        'idGrupoCurso': 'Curso Categoria Fase 4',
        'idGrupoAnio': 2026,
        'idGrupoIterable': 1,
        'idInstructor': '2',
        //solo el dia elegido, sin hora ni zona: el backend recibe un LocalDate
        'fecha': '2026-10-28',
        'horas': 2,
        'minutos': 0,
        'observacion': null,
        'eliminado': 0,
      });
    });

    //nacio de CL-07: en UTC, desde las 19:00 hora local ya es el dia siguiente
    //y el backend rechaza la clase de hoy como futura
    test('$capa - $tipo - Registrar clase - de noche sale el mismo dia local', () async {
      adaptador.responder('POST', '/claseGrupo', 201);

      await formulario().registrarClase(fecha: DateTime(2026, 10, 28, 23, 30), horasTexto: '2');

      final cuerpo = adaptador.peticionesA('POST', '/claseGrupo').single.cuerpo as Map;
      expect(cuerpo['fecha'], '2026-10-28');
    });

    //nacio como diagnostico de BK-08: el backend reutiliza la clase de esa
    //fecha y responde 200 con ella, sin guardar las horas enviadas
    test('$capa - $tipo - Registrar clase - un 200 con la clase existente es Exito y avisa que no se creo otra', () async {
      adaptador.responder('POST', '/claseGrupo', 200, leerContrato('clases', 'claseGrupo_200_existente'));

      final resultado = await formulario().registrarClase(fecha: DateTime(2026, 10, 22), horasTexto: '2');

      expect(resultado, isA<Exito<bool>>());
      expect((resultado as Exito<bool>).datos, isFalse);
    });

    test('$capa - $tipo - Registrar clase - un 201 dice que la clase es nueva', () async {
      adaptador.responder('POST', '/claseGrupo', 201, leerContrato('clases', 'claseGrupo_200_existente'));

      final resultado = await formulario().registrarClase(fecha: DateTime(2026, 10, 22), horasTexto: '2');

      expect((resultado as Exito<bool>).datos, isTrue);
    });

    test('$capa - $tipo - Registrar clase - un 2xx que no es 200 ni 201 es Fallo con un mensaje legible', () async {
      adaptador.responder('POST', '/claseGrupo', 202, {'codigo': 207});

      final resultado = await formulario().registrarClase(fecha: DateTime(2026, 10, 22), horasTexto: '2');

      expect(resultado, isA<Fallo>());
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 202);
      expect(fallo.mensaje, 'Respuesta inesperada del servidor. Código: 202');
    });

    //nacio como diagnostico de IN-16 en clases
    test('$capa - $tipo - Registrar clase - un rechazo da el motivo, no el JSON de la respuesta', () async {
      adaptador.responder('POST', '/claseGrupo', 422, {
        'codigoError': 'GC-0021',
        'mensaje': 'La clase no tiene horario ese dia',
        'codigoHttp': 422,
      });

      final resultado = await formulario().registrarClase(fecha: DateTime(2026, 10, 28), horasTexto: '2');

      expect((resultado as Fallo).mensaje, 'La clase no tiene horario ese dia');
    });

    test('$capa - $tipo - Registrar clase - un 400 del backend es Fallo con su codigo y sin red es 503', () async {
      adaptador.responder('POST', '/claseGrupo', 400, {'fecha': 'no puede ser futura'});
      final r400 = await formulario().registrarClase(fecha: DateTime(2026, 10, 28), horasTexto: '2');
      expect(r400, isA<Fallo>());
      expect((r400 as Fallo).codigo, 400);

      adaptador.fallar('POST', '/claseGrupo', DioExceptionType.connectionError);
      final r503 = await formulario().registrarClase(fecha: DateTime(2026, 10, 28), horasTexto: '2');
      expect((r503 as Fallo).codigo, 503);
    });

    test('$capa - $tipo - Eliminar clase - envia el id y recarga; un 500 es Fallo y no recarga', () async {
      adaptador.responder('GET', '/clasesGrupo', 200, leerContrato('clases', 'clasesGrupo_200'));
      adaptador.responder('DELETE', '/clase', 200);
      final vm = pantallaGrupo();
      await vm.cargarClases();

      expect(await vm.eliminarClase(207), isA<Exito>());
      expect(adaptador.peticionesA('DELETE', '/clase').single.uri.queryParameters, {'id': '207'});
      expect(adaptador.peticionesA('GET', '/clasesGrupo'), hasLength(2));

      adaptador.responder('DELETE', '/clase', 500, 'error interno');
      final fallo = await vm.eliminarClase(211);
      expect(fallo, isA<Fallo>());
      expect((fallo as Fallo).codigo, 500);
      expect(adaptador.peticionesA('GET', '/clasesGrupo'), hasLength(2));
    });
    //los casos rojos de este montaje estan en
    //test/diagnostico/clases/integracion_diagnostico_test.dart
  });

  group('Formulario de clase (pantalla → conexion real → transporte falso):', () {
    Future<Future<Object?>> abrirFormulario(WidgetTester tester) async {
      final navegador = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navegador, home: const Scaffold()),
      );
      final retorno = navegador.currentState!.push<Object?>(
        MaterialPageRoute(
          builder:
              (_) => ChangeNotifierProvider(
                //como la ruta: carga los horarios del grupo al abrir
                create: (_) => formulario()..cargarHorarios(),
                child: const Claseformulario(),
              ),
        ),
      );
      await tester.pumpAndSettle();
      return retorno;
    }

    Future<void> guardar(WidgetTester tester) async {
      await tester.enterText(find.byType(TextFormField).first, '2');
      await tester.tap(find.text('GUARDAR'));
      await tester.pumpAndSettle();
    }

    testWidgets('$capa - $tipo - Formulario de clase - la clase existente lo dice y vuelve con true para recargar', (tester) async {
      adaptador.responder('POST', '/claseGrupo', 200, leerContrato('clases', 'claseGrupo_200_existente'));
      final retorno = await abrirFormulario(tester);

      await guardar(tester);

      expect(find.text('Ya existía una clase en esa fecha; no se creó otra.'), findsOneWidget);
      expect(find.text('Clase registrada'), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(await retorno, isTrue);
    });

    testWidgets('$capa - $tipo - Formulario de clase - una clase nueva dice que se guardo', (tester) async {
      adaptador.responder('POST', '/claseGrupo', 201, leerContrato('clases', 'claseGrupo_200_existente'));
      await abrirFormulario(tester);

      await guardar(tester);

      expect(find.text('Clase registrada'), findsOneWidget);
    });
  });
}
