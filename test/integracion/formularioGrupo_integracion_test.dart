import 'package:dpt_movil/config/formatDate.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionInstructoresRemoto.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formGrupoArgumentos.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/domain/servicios/servicio_instructor.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';
import '../dobles/conexionautenticacionFalsa.dart';
import '../dobles/googleSignInFalso.dart';

//formulario de alta de grupo de punta a punta sin backend: la ruta real
//(AppRutas.grupoFormulario) con las cadenas reales de grupos e instructores
//hasta sus Conexion*Remoto, sobre el transporte falso y con las respuestas
//de los contratos observados
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  //lo que devuelve la ruta al cerrarse (pop)
  Object? devuelto;

  final curso = CursoEntidad(
    nombreCurso: 'Curso Categoria Fase 4',
    nombreDeporte: 'Atletismo',
    tituloCategoria: 'Categoria Fase 4',
    descripcion: 'x',
    imagen: 1197,
  );

  List gruposDelContrato() =>
      leerContrato('inscripciones', 'gruposNoEliminados_200') as List;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    devuelto = null;
    adaptador.responder(
      'GET',
      '/instructores',
      200,
      leerContrato('instructores', 'instructores_200'),
    );
  });

  Future<void> abrirFormulario(WidgetTester tester) async {
    final dio = crearDioFalso(adaptador);
    final sesion = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa()),
      ),
      GoogleSignInFalso(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<Serviciogrupo>(
            create: (_) => Serviciogrupo(
              Gruporepositorio(conexion: Conexiongruposremoto(dio)),
            ),
          ),
          Provider<ServicioInstructor>(
            create: (_) => ServicioInstructor(
              Instructoresrepositorio(conexion: Conexioninstructoresremoto(dio)),
            ),
          ),
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: sesion),
        ],
        child: MaterialApp(
          onGenerateRoute: generateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                devuelto = await Navigator.pushNamed(
                  context,
                  AppRutas.grupoFormulario,
                  arguments: Formgrupoargumentos(curso: curso, esEdicion: false),
                );
              },
              child: const Text('Abrir pantalla'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir pantalla'));
    await tester.pumpAndSettle();
  }

  Future<void> elegirInstructor(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownMenu<dynamic>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('edynson muñoz jimenez - 2').last);
    await tester.pumpAndSettle();
  }

  Future<void> guardar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('GUARDAR'));
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();
  }

  group('Formulario de grupo (ruta real → conexiones reales → transporte falso):', () {
    testWidgets('$capa - $tipo - Agregar grupo - control - el desplegable muestra los instructores del backend', (tester) async {
      await abrirFormulario(tester);
      await tester.tap(find.byType(DropdownMenu<dynamic>));
      await tester.pumpAndSettle();

      expect(find.text('edynson muñoz jimenez - 2'), findsWidgets);
      expect(find.text('Categoria Fase 4'), findsOneWidget);
      expect(find.text('Curso Categoria Fase 4'), findsOneWidget);
    });

    testWidgets('$capa - $tipo - Agregar grupo - 201 envia el GrupoDto, avisa que se creo el grupo y vuelve con true', (tester) async {
      adaptador.responder('POST', '/grupo', 201, gruposDelContrato().first);
      await abrirFormulario(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Cupos del grupo'), '25');
      await elegirInstructor(tester);

      await guardar(tester);

      final cuerpo = adaptador.peticionesA('POST', '/grupo').single.cuerpo as Map;
      expect(
        (cuerpo['categoria'], cuerpo['curso'], cuerpo['cupos'], cuerpo['idInstructor'], cuerpo['imagenGrupo']),
        ('Categoria Fase 4', 'Curso Categoria Fase 4', 25, '2', 1197),
      );
      expect(cuerpo['fechaCreacion'], FormatDate.fechaACadena(DateTime.now(), '-'));
      //el dialogo habla del grupo, no del curso (texto copiado de otro formulario)
      expect(tester.widget<DialogExito>(find.byType(DialogExito)).titulo, 'Grupo registrado');

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(devuelto, true);
    });

    testWidgets('$capa - $tipo - Agregar grupo - un error del backend muestra su codigo con un titulo del grupo', (tester) async {
      adaptador.responder('POST', '/grupo', 400, {'cupos': 'must not be null'});
      await abrirFormulario(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Cupos del grupo'), '25');
      await elegirInstructor(tester);

      await guardar(tester);

      final dialogo = tester.widget<DialogError>(find.byType(DialogError));
      expect((dialogo.codigo, dialogo.titulo), (400, 'Error al guardar el grupo'));
      expect(find.byType(DialogError), findsOneWidget);
    });

    //digitsOnly deja escribir cualquier largo; int.parse lanzaba con un numero
    //que no cabe en un int y el boton no hacia nada visible
    testWidgets('$capa - $tipo - Agregar grupo - unos cupos que no caben en un numero avisan y no envian nada', (tester) async {
      await abrirFormulario(tester);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Cupos del grupo'),
        '99999999999999999999999',
      );
      await elegirInstructor(tester);

      await guardar(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(DialogError), findsOneWidget);
      expect(adaptador.peticionesA('POST', '/grupo'), isEmpty);
    });

    testWidgets('$capa - $tipo - Agregar grupo - sin instructor avisa y no envia nada', (tester) async {
      await abrirFormulario(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Cupos del grupo'), '25');

      await guardar(tester);

      expect(find.textContaining('instructor'), findsWidgets);
      expect(adaptador.peticionesA('POST', '/grupo'), isEmpty);
    });
  });
}
