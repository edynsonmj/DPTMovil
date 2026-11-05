import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionFacultadRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/data/repositories/facultadesRepositorio.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/domain/servicios/servicioFacultades.dart';
import 'package:dpt_movil/domain/servicios/servicioGrupo.dart';
import 'package:dpt_movil/presentation/view/widgets/bar.dart';
import 'package:dpt_movil/presentation/view/widgets/menuLateral.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';
import '../dobles/conexionCategoriaFalsa.dart';
import '../dobles/googleSignInFalso.dart';

//montaje compartido del inicio de sesion y el registro
//(plan-diagnostico-autenticacion.md). No es un test: lo usan
//test/diagnostico/autenticacion y test/integracion/autenticacion_integracion_test.
//
//Rutas reales de route_generator y el menu lateral real. La sesion es el
//AutenticacionViewModel real hasta Conexionautenticacionremoto sobre el
//transporte falso; las facultades del registro y los grupos de inscripciones
//del coordinador tambien van por su cadena real. Las categorias (la pantalla
//a la que lleva cerrar sesion) van con su doble
class MontajeAutenticacion {
  final AdaptadorHttpFalso adaptador = AdaptadorHttpFalso();
  final GoogleSignInFalso google = GoogleSignInFalso();

  final ConexionCategoriaFalsa conexionCategorias =
      ConexionCategoriaFalsa()
        ..respuestaListar = RespuestaModelo(
          codigoHttp: 200,
          datos: [categoriaModelo(titulo: 'Futbol', descripcion: 'Desc')],
        );

  late final AutenticacionViewModel sesion = AutenticacionViewModel(
    Servicioautenticacion(
      Autenticacionrepositorio(
        conexion: Conexionautenticacionremoto(crearDioFalso(adaptador)),
      ),
    ),
    google,
  );

  MontajeAutenticacion() {
    adaptador.responder(
      'GET',
      '/facultades',
      200,
      leerContrato('facultades', 'facultades_200'),
    );
    adaptador.responder(
      'GET',
      '/gruposNoEliminados',
      200,
      leerContrato('inscripciones', 'gruposNoEliminados_200'),
    );
  }

  //app con las rutas reales. Arranca en una pantalla con la barra y el menu
  //lateral de la app; si se pide una ruta, un boton la abre
  Future<void> abrir(WidgetTester tester, {String? ruta}) async {
    //el formulario de registro es largo: pantalla alta para que todo se vea
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ServicioCategoria>(
            create:
                (_) => ServicioCategoria(
                  CategoriaRepositorio(cliente: conexionCategorias),
                ),
          ),
          Provider<Serviciofacultades>(
            create:
                (_) => Serviciofacultades(
                  Facultadesrepositorio(
                    conexion: Conexionfacultadremoto(crearDioFalso(adaptador)),
                  ),
                ),
          ),
          Provider<Serviciogrupo>(
            create:
                (_) => Serviciogrupo(
                  Gruporepositorio(
                    conexion: Conexiongruposremoto(crearDioFalso(adaptador)),
                  ),
                ),
          ),
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: sesion),
        ],
        child: MaterialApp(
          onGenerateRoute: generateRoute,
          home: Builder(
            builder:
                (context) => Scaffold(
                  appBar: Bar(title: 'Inicio prueba'),
                  drawer: Builder(builder: (context) => Menulateral()),
                  body: TextButton(
                    onPressed:
                        ruta == null
                            ? null
                            : () => Navigator.pushNamed(context, ruta),
                    child: const Text('Abrir pantalla'),
                  ),
                ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (ruta != null) {
      await tester.tap(find.text('Abrir pantalla'));
      await tester.pumpAndSettle();
    }
  }

  //el boton de menu de la barra de la pantalla de arriba
  Future<void> abrirMenu(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.menu).last);
    await tester.pumpAndSettle();
  }

  //menu lateral → "Iniciar sesion" → "Continuar con correo" → correo
  Future<void> iniciarSesionConCorreo(WidgetTester tester, String correo) async {
    await abrirMenu(tester);
    await tester.tap(find.text('Iniciar sesion'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar con correo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, correo);
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
  }

  //elige una opcion de un DropdownMenu del registro por su texto de ayuda
  Future<void> elegir(WidgetTester tester, String ayuda, String opcion) async {
    final menu = find.ancestor(
      of: find.text(ayuda),
      matching: find.byWidgetPredicate((w) => w is DropdownMenu),
    );
    await tester.tap(menu);
    await tester.pumpAndSettle();
    await tester.tap(find.text(opcion).last);
    await tester.pumpAndSettle();
  }

  //llena el formulario de registro como lo haria el alumno, en orden
  Future<void> llenarRegistro(
    WidgetTester tester, {
    String nombre = 'Beto Alumno',
    String id = '1061000002',
  }) async {
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre completo'),
      nombre,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Identificacion'),
      id,
    );
    await elegir(tester, 'Selecciona tu tipo de identificacion', 'CC');
    await elegir(tester, 'Selecciona tu sexo', 'M');
    await elegir(tester, 'Estas vinculado a la universidad como:', 'Estudiante');
    await elegir(tester, 'Selecciona tu facultad', 'fiet');
  }
}
