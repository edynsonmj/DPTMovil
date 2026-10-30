@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionCursoRemoto.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/cursoRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de cursos de punta a punta sin backend (plan-diagnostico-
//cursos.md): el mismo montaje que test/integracion/cursos_integracion_test.dart.
//Afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late CursoRepositorio repositorio;
  late CursosViewModel vm;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    final dio = crearDioFalso(adaptador);
    repositorio = CursoRepositorio(
      cliente: ConexionCursoRemoto(dio, Conexionimagenremoto(dio)),
    );
    vm = CursosViewModel(ServicioCurso(repositorio));
  });

  group('Cursos (diagnostico de punta a punta):', () {
    //el "&" corta el valor en la query: el backend recibe otra categoria
    test('$capa - $tipo - Listar y obtener curso - BUG CU-02 - categoria y curso llegan completos a la query', () async {
      adaptador.responder('GET', '/cursosbycategoria', 200, []);
      adaptador.responder('GET', '/curso', 200, leerContrato('cursos', 'curso_200'));

      await vm.listarCursosDe(
        null,
        CategoriaEntidad(titulo: 'Fútbol & Voleibol', descripcion: 'x'),
      );
      await vm.obtenerCurso('Fútbol & Voleibol', 'Nivel 1 + 2');

      final lista =
          adaptador.peticionesA('GET', '/cursosbycategoria').single.uri.queryParameters;
      final uno = adaptador.peticionesA('GET', '/curso').single.uri.queryParameters;
      expect(
        [lista['prmCategoria'], uno['prmCategoria'], uno['prmCurso']],
        ['Fútbol & Voleibol', 'Fútbol & Voleibol', 'Nivel 1 + 2'],
      );
    });

    //imagenFile! en la conexion: el TypeError atraviesa conexion,
    //repositorio, servicio y vm (agregarCurso no tiene try)
    test('$capa - $tipo - Agregar curso - BUG CU-03 - sin archivo de imagen devuelve un error, sin lanzar', () async {
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

    //un curso sin "deporte": CursoModelo.fromJson lanza un TypeError y las
    //dos lecturas solo capturan Exception
    test('$capa - $tipo - Listar y obtener curso - BUG CU-04 - un curso incompleto vuelve como error de la conexion, sin lanzar', () async {
      final incompleto = Map<String, dynamic>.from(
        leerContrato('cursos', 'curso_200') as Map,
      )..remove('deporte');
      adaptador.responder('GET', '/cursosbycategoria', 200, [incompleto]);
      adaptador.responder('GET', '/curso', 200, incompleto);

      for (final pedir in <Future<dynamic> Function()>[
        () => repositorio.listarCursosDe(
          CategoriaEntidad(titulo: 'Categoria Fase 4', descripcion: 'x'),
        ),
        () => repositorio.obtenerCurso('Categoria Fase 4', 'Curso Categoria Fase 4'),
      ]) {
        Object? lanzado;
        dynamic respuesta;
        try {
          respuesta = await pedir();
        } catch (e) {
          lanzado = e;
        }
        expect(lanzado, isNull, reason: 'lanzo: $lanzado');
        expect(respuesta.codigoHttp, isNot(200));
      }
    });

    //un error del backend es un solo problema: un solo dialogo
    testWidgets('$capa - $tipo - Listar cursos de - BUG CU-05 - un 500 abre un solo dialogo de error', (tester) async {
      adaptador.responder('GET', '/cursosbycategoria', 500, 'error interno');
      late BuildContext contexto;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (c) {
              contexto = c;
              return const Scaffold();
            },
          ),
        ),
      );

      //Dio corre fuera del reloj falso del test
      await tester.runAsync(
        () => vm.listarCursosDe(
          contexto,
          CategoriaEntidad(titulo: 'Categoria Fase 4', descripcion: 'x'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byType(DialogError),
        findsOneWidget,
        reason: 'titulos: ${tester.widgetList<DialogError>(find.byType(DialogError)).map((d) => d.titulo).toList()}',
      );
    });
  });
}
