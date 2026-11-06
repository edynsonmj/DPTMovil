import 'dart:io';

import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/config/routes/route_generator.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';
import '../dobles/conexionautenticacionFalsa.dart';
import '../dobles/googleSignInFalso.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//integracion local del modulo 8 (plan-diagnostico-cursos.md): CursosViewModel
//con su cadena real hasta ConexionCursoRemoto y Conexionimagenremoto (el alta
//sube la imagen y despues el curso), con el transporte falso debajo y las
//respuestas del contrato observado
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late CursosViewModel vm;

  final categoria = CategoriaEntidad(titulo: 'Categoria Fase 4', descripcion: 'x');

  CursoEntidad nuevo() => CursoEntidad(
    nombreCurso: 'Curso nuevo',
    nombreDeporte: 'Atletismo',
    tituloCategoria: 'Categoria Fase 4',
    descripcion: 'Curso creado en la prueba',
    //relativa al directorio de trabajo: correr desde la raiz
    imagenFile: File('assets/images/1.jpg'),
  );

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    final dio = crearDioFalso(adaptador);
    vm = CursosViewModel(
      ServicioCurso(
        CursoRepositorio(cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio))),
      ),
    );
  });

  //CursosView por la ruta real (route_generator) con la cadena real del vm
  //sobre el transporte falso. Termina la transicion sin pumpAndSettle: un
  //indicador de carga girando no se asienta nunca
  Future<void> abrirCursos(WidgetTester tester) async {
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
          ChangeNotifierProvider<AutenticacionViewModel>.value(value: sesion),
        ],
        child: MaterialApp(
          onGenerateRoute: generateRoute,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => Navigator.pushNamed(
                context,
                AppRutas.cursos,
                arguments: categoria,
              ),
              child: const Text('Abrir pantalla'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir pantalla'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  group('Cursos (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Listar cursos de - 200 pide la categoria y llena la lista y el desplegable', () async {
      adaptador.responder('GET', '/cursosbycategoria', 200, leerContrato('cursos', 'cursosbycategoria_200'));

      expect(await vm.listarCursosDe(categoria), isA<Exito<void>>());

      expect(
        adaptador.peticionesA('GET', '/cursosbycategoria').single.uri.queryParameters,
        {'prmCategoria': 'Categoria Fase 4'},
      );
      expect(vm.getListaCursos!.map((c) => c.nombreCurso), [
        'Curso Categoria Fase 4',
        'Curso 2 Fase 4',
      ]);
      expect(vm.getListaCursos!.first.imagen, 1197);
      expect(vm.nombresCursos, [
        'Curso Categoria Fase 4',
        'Curso 2 Fase 4',
      ]);
    });

    test('$capa - $tipo - Listar cursos de - 200 [] deja la lista y el desplegable vacios', () async {
      adaptador.responder('GET', '/cursosbycategoria', 200, []);

      await vm.listarCursosDe(categoria);

      expect(vm.getListaCursos, isEmpty);
      expect(vm.nombresCursos, isEmpty);
    });

    test('$capa - $tipo - Agregar curso - sube la imagen, envia el CursoDto con su id y 201 devuelve la entidad', () async {
      adaptador.responder('POST', '/imagenMultipart', 201, leerContrato('cursos', 'imagenMultipart_201'));
      adaptador.responder('POST', '/curso', 201, leerContrato('cursos', 'curso_201'));

      final respuesta = await vm.agregarCurso(nuevo());

      expect(
        adaptador.peticiones.map((p) => '${p.metodo} ${p.ruta}'),
        ['POST /imagenMultipart', 'POST /curso'],
      );
      expect(adaptador.peticionesA('POST', '/curso').single.cuerpo, {
        'nombre': 'Curso nuevo',
        'deporte': 'Atletismo',
        'categoriaCurso': 'Categoria Fase 4',
        'descripcion': 'Curso creado en la prueba',
        'idImagen': 1300,
      });
      expect(respuesta.codigoHttp, 201);
      expect((respuesta.datos as CursoEntidad).imagen, 1300);
    });

    test('$capa - $tipo - Agregar curso - si la imagen falla no se envia el curso', () async {
      adaptador.responder('POST', '/imagenMultipart', 500, 'error al guardar la imagen');

      final respuesta = await vm.agregarCurso(nuevo());

      expect(respuesta.codigoHttp, 500);
      expect(adaptador.peticionesA('POST', '/curso'), isEmpty);
    });

    test('$capa - $tipo - Agregar curso - un 400 del curso llega con su codigo', () async {
      adaptador.responder('POST', '/imagenMultipart', 201, leerContrato('cursos', 'imagenMultipart_201'));
      adaptador.responder('POST', '/curso', 400, {'nombre': 'no debe estar vacio'});

      final respuesta = await vm.agregarCurso(nuevo());

      expect(respuesta.codigoHttp, 400);
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Obtener curso - 200 devuelve la entidad y 404 el error del backend', () async {
      adaptador.responder('GET', '/curso', 200, leerContrato('cursos', 'curso_200'));
      final encontrado = await vm.obtenerCurso('Categoria Fase 4', 'Curso Categoria Fase 4');
      expect((encontrado.datos as CursoEntidad).nombreDeporte, 'Atletismo');

      adaptador.responder('GET', '/curso', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No se encuentra registrado el elemento: null',
      });
      final ausente = await vm.obtenerCurso('Categoria Fase 4', 'No existe');
      expect(ausente.codigoHttp, 404);
      expect(ausente.error?.mensaje, 'No se encuentra registrado el elemento: null');
    });
    //los casos rojos de este montaje (CU-02 a CU-05) estan en
    //test/diagnostico/cursos/integracion_diagnostico_test.dart

    //nacio como diagnostico de CU-05: listarCursosDe(context) no salia tras
    //el primer error y abria dos dialogos ("Sin datos" y "datos
    //inconsistentes"). Ruta real de route_generator y cadena real del vm
    testWidgets('$capa - $tipo - Listar cursos de (CursosView) - un 500 abre un solo dialogo con su codigo', (tester) async {
      adaptador.responder('GET', '/cursosbycategoria', 500, 'error interno');
      await abrirCursos(tester);
      await tester.pumpAndSettle();

      final dialogos = tester.widgetList<DialogError>(find.byType(DialogError));
      expect(
        dialogos.map((d) => d.codigo),
        [500],
        reason: 'titulos: ${dialogos.map((d) => d.titulo).toList()}',
      );
    });

    //mientras la lista no llega la pantalla no debe afirmar que la
    //categoria no tiene cursos
    testWidgets('$capa - $tipo - Listar cursos de (CursosView) - mientras carga muestra el indicador y no "no hay cursos"', (tester) async {
      final retenida = adaptador.retener('GET', '/cursosbycategoria');
      adaptador.responder('GET', '/cursosbycategoria', 200, []);
      await abrirCursos(tester);

      final durante = (
        indicador: find.byType(CircularProgressIndicator).evaluate().length,
        sinCursos: find.text('No hay cursos aun para esta categoria').evaluate().length,
      );

      retenida.complete();
      await tester.pumpAndSettle();

      expect(durante, (indicador: 1, sinCursos: 0));
      //al llegar la lista vacia el indicador se va y el aviso aparece
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No hay cursos aun para esta categoria'), findsOneWidget);
    });

    //nacio como diagnostico de CU-03: el imagenFile! de la conexion lanzaba y
    //la excepcion atravesaba repositorio, servicio y vm (agregarCurso no
    //tenia try). Ahora el vm la devuelve como respuesta
    test('$capa - $tipo - Agregar curso - sin archivo de imagen devuelve un error, sin lanzar', () async {
      Object? lanzado;
      try {
        final respuesta = await vm.agregarCurso(
          CursoEntidad(
            nombreCurso: 'Curso nuevo',
            nombreDeporte: 'Atletismo',
            tituloCategoria: 'Categoria Fase 4',
            descripcion: 'Sin imagen',
            imagen: 1197,
          ),
        );
        expect(respuesta.codigoHttp, isNot(201));
      } catch (e) {
        lanzado = e;
      }
      expect(lanzado, isNull, reason: 'lanzo: $lanzado');
      expect(adaptador.peticiones, isEmpty);
    });
  });
}
