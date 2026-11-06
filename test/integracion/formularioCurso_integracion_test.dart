import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionDeporteRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/data/repositories/deporteRepositorio.dart';
import 'package:dpt_movil/domain/entities/entidadesRutas/formCursoArgumentos.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/domain/servicios/servicioDeporte.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:provider/provider.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';
import '../dobles/conexionautenticacionFalsa.dart';
import '../dobles/googleSignInFalso.dart';
import '../dobles/selectorImagenFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//formulario de alta de curso de punta a punta sin backend: la ruta real
//(AppRutas.formularioCurso) con las cadenas reales de cursos (con imagen) y
//deportes hasta sus Conexion*Remoto, sobre el transporte falso. El selector
//de imagenes es un doble que devuelve assets/images/1.jpg (relativa al
//directorio de trabajo: correr desde la raiz)
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  //lo que devuelve la ruta al cerrarse (pop)
  Object? devuelto;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    devuelto = null;
    adaptador.responder('GET', '/deportes', 200, [
      {'nombre': 'Atletismo'},
      {'nombre': 'Natacion'},
    ]);
    ImagePickerPlatform.instance = SelectorImagenFalso('assets/images/1.jpg');
  });

  Future<void> abrirFormulario(WidgetTester tester) async {
    final dio = crearDioFalso(adaptador);
    final sesion = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(conexion: ConexionautenticacionFalsa(), almacenToken: AlmacenToken()),
      ),
      GoogleSignInFalso(),
    );
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ServicioCurso>(
            create: (_) => ServicioCurso(
              CursoRepositorio(
                cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)),
              ),
            ),
          ),
          Provider<Serviciodeporte>(
            create: (_) => Serviciodeporte(
              Deporterepositorio(cliente: Conexiondeporteremoto(dio)),
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
                  AppRutas.formularioCurso,
                  arguments: Formcursoargumentos(
                    esEdicion: false,
                    categoria: 'Categoria Fase 4',
                  ),
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

  //texto actual del campo con esa etiqueta
  String campo(WidgetTester tester, String etiqueta) => tester
      .widget<EditableText>(
        find.descendant(
          of: find.widgetWithText(TextFormField, etiqueta),
          matching: find.byType(EditableText),
        ),
      )
      .controller
      .text;

  //llena el formulario completo: nombre, descripcion, deporte e imagen
  Future<void> llenar(WidgetTester tester) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Curso nuevo');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripcion'),
      'Descripcion del curso',
    );
    await tester.tap(find.byType(DropdownMenu<dynamic>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Atletismo').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seleccionar Imagen'));
    await tester.pumpAndSettle();
  }

  //la subida lee el archivo de verdad: necesita tiempo real, fuera del reloj
  //falso del test
  Future<void> guardar(WidgetTester tester) async {
    await tester.ensureVisible(find.text('GUARDAR'));
    //el toque dentro de runAsync: el envio arranca en la zona real y la
    //lectura del archivo avanza
    await tester.runAsync(() async {
      await tester.tap(find.text('GUARDAR'));
      await Future.delayed(const Duration(milliseconds: 500));
    });
    await tester.pumpAndSettle();
  }

  group('Formulario de curso (ruta real → conexiones reales → transporte falso):', () {
    testWidgets('$capa - $tipo - Agregar curso - control - el desplegable muestra los deportes del backend', (tester) async {
      await abrirFormulario(tester);
      await tester.tap(find.byType(DropdownMenu<dynamic>));
      await tester.pumpAndSettle();

      expect(find.text('Atletismo'), findsWidgets);
      expect(find.text('Natacion'), findsWidgets);
      expect(adaptador.peticionesA('GET', '/deportes'), hasLength(1));
    });

    //el formulario se limpiaba antes de enviar: si el guardado fallaba, el
    //usuario perdia lo escrito y tenia que empezar de nuevo
    testWidgets('$capa - $tipo - Agregar curso - un fallo al guardar muestra su codigo y conserva lo escrito', (tester) async {
      adaptador.responder('POST', '/imagenMultipart', 500, 'error interno');
      await abrirFormulario(tester);
      await llenar(tester);

      await guardar(tester);

      final dialogos = tester.widgetList<DialogError>(find.byType(DialogError));
      expect(dialogos.map((d) => d.codigo), [500]);
      expect(
        (nombre: campo(tester, 'Nombre'), descripcion: campo(tester, 'Descripcion')),
        (nombre: 'Curso nuevo', descripcion: 'Descripcion del curso'),
      );
      expect(adaptador.peticionesA('POST', '/curso'), isEmpty);
    });

    testWidgets('$capa - $tipo - Agregar curso - 201 sube la imagen, registra el curso y vuelve con true', (tester) async {
      adaptador.responder('POST', '/imagenMultipart', 201, leerContrato('cursos', 'imagenMultipart_201'));
      adaptador.responder('POST', '/curso', 201, leerContrato('cursos', 'curso_201'));
      await abrirFormulario(tester);
      await llenar(tester);

      await guardar(tester);

      expect(find.byType(DialogExito), findsOneWidget);
      final cuerpo = adaptador.peticionesA('POST', '/curso').single.cuerpo as Map;
      expect((cuerpo['nombre'], cuerpo['deporte']), ('Curso nuevo', 'Atletismo'));

      //el envio empezo en la zona real (guardar): su continuacion tras cerrar
      //el dialogo (el pop con true) tambien corre ahi
      await tester.runAsync(() async {
        await tester.tap(find.text('OK'));
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(devuelto, true);
      expect(find.text('Abrir pantalla'), findsOneWidget);
    });

    //las reglas del alta las aplica el vm: sin imagen no se envia nada
    testWidgets('$capa - $tipo - Agregar curso - sin imagen avisa y no envia nada', (tester) async {
      await abrirFormulario(tester);
      await tester.enterText(find.widgetWithText(TextFormField, 'Nombre'), 'Curso nuevo');
      await tester.enterText(find.widgetWithText(TextFormField, 'Descripcion'), 'x');
      await tester.tap(find.byType(DropdownMenu<dynamic>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Atletismo').last);
      await tester.pumpAndSettle();

      await guardar(tester);

      expect(find.text('Carga una imagen por favor'), findsOneWidget);
      expect(adaptador.peticiones.where((p) => p.metodo == 'POST'), isEmpty);
      expect(campo(tester, 'Nombre'), 'Curso nuevo');
    });

    //los deportes los carga la ruta una vez (Deporteviewmodel..cargar()); un
    //error se pinta en lugar del desplegable, con el codigo que llego. Salio
    //rojo con "Código: 0": la conexion de deportes no separaba DioException
    //(DE-01)
    testWidgets('$capa - $tipo - Agregar curso - un error al pedir los deportes se muestra en lugar del desplegable', (tester) async {
      adaptador.responder('GET', '/deportes', 500, 'error interno');
      await abrirFormulario(tester);

      expect(find.byType(DropdownMenu<dynamic>), findsNothing);
      expect(find.textContaining('No se logró obtener los deportes: Código: 500'), findsOneWidget, reason: tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).join(' | '));
    });
  });
}
