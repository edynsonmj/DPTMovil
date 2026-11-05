import 'dart:io';

import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

//diagnostico del modulo 8 contra el backend real (plan-diagnostico-
//cursos.md): CursosViewModel con su cadena real. El setUpAll crea por
//corrida tres categorias: N "prueba_X" (los casos le agregan cursos), V
//"pruebaV_X" (sin cursos) y E "prueba_X Fútbol & Voleibol" con el curso
//"curso & co X". listarCursosDe devuelve un Resultado: los casos exigen el
//Exito, porque un error tambien deja la lista vacia. Los casos dependen del
//orden
class VmCursoDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late String _marca;
  late String _deporte;
  late CategoriaEntidad _n;
  late CategoriaEntidad _v;
  late CategoriaEntidad _e;
  late CursoEntidad _cursoE;

  void preparar({
    required CategoriaViewModel vmCategoria,
    required Deporteviewmodel Function() crearVmDeporte,
    required CursosViewModel Function() crearVmCurso,
  }) {
    setUpAll(() async {
      _marca = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');
      _deporte =
          ((await crearVmDeporte().obtenerDeportes()).datos as List<String>).first;
      Future<CategoriaEntidad> categoria(String titulo) async {
        final c = CategoriaEntidad(
          titulo: titulo,
          descripcion: 'categoria para el diagnostico de cursos',
          imagenFile: _imagenPrueba(),
        );
        expect(
          await vmCategoria.insertarCategoria(c),
          isA<Exito>(),
          reason: 'no se creo la categoria $titulo',
        );
        return c;
      }

      _n = await categoria('prueba_$_marca');
      _v = await categoria('pruebaV_$_marca');
      _e = await categoria('prueba_$_marca Fútbol & Voleibol');
      final r = await crearVmCurso().agregarCurso(_nuevo(_e, 'curso & co $_marca'));
      expect(r.codigoHttp, 201, reason: 'no se creo el curso con &');
      _cursoE = r.datos as CursoEntidad;
    });
  }

  void prueba1AgregarListarObtener(CursosViewModel Function() crearVm) {
    String metodo = "Agregar, listar y obtener curso";
    String caso = "el curso nuevo aparece en su categoria y se obtiene con sus datos";
    test('$capa - $tipo - $metodo - $caso', () async {
      final alta = await crearVm().agregarCurso(_nuevo(_n, 'curso_$_marca'));
      expect(alta.codigoHttp, 201);
      final creado = alta.datos as CursoEntidad;
      expect(creado.imagen, isNotNull);

      final vm = crearVm();
      expect(await vm.listarCursosDe(_n), isA<Exito<void>>());
      final listado = vm.getListaCursos!.single;
      expect(listado.nombreCurso, 'curso_$_marca');
      expect(listado.nombreDeporte, _deporte);
      expect(listado.imagen, creado.imagen);
      expect(vm.nombresCursos.single, 'curso_$_marca');

      final RespuestaModelo uno = await crearVm().obtenerCurso(_n.titulo, 'curso_$_marca');
      expect(uno.codigoHttp, 200);
      expect((uno.datos as CursoEntidad).descripcion, 'curso para el diagnostico de cursos');
    });
  }

  //H-06
  void prueba2CursoRepetido(CursosViewModel Function() crearVm) {
    String metodo = "Agregar curso";
    String caso = "un curso con el mismo nombre en la misma categoria no se crea";
    test('$capa - $tipo - $metodo - $caso', () async {
      final r = await crearVm().agregarCurso(_nuevo(_n, 'curso_$_marca'));
      expect(r.codigoHttp, isNot(201), reason: 'codigo ${r.codigoHttp}');

      final vm = crearVm();
      expect(await vm.listarCursosDe(_n), isA<Exito<void>>());
      expect(vm.getListaCursos, hasLength(1));
    });
  }

  //H-07
  void prueba3DatosInvalidos(CursosViewModel Function() crearVm) {
    String metodo = "Agregar curso";
    String caso = "categoria inexistente, nombre vacio o descripcion vacia no crean curso";
    test('$capa - $tipo - $metodo - $caso', () async {
      final sinCategoria = await crearVm().agregarCurso(
        _nuevo(CategoriaEntidad(titulo: 'noexiste_$_marca', descripcion: 'x'), 'c1_$_marca'),
      );
      final sinNombre = await crearVm().agregarCurso(_nuevo(_n, ''));
      final sinDescripcion = await crearVm().agregarCurso(
        _nuevo(_n, 'c2_$_marca')..descripcion = '',
      );

      expect(
        [sinCategoria.codigoHttp, sinNombre.codigoHttp, sinDescripcion.codigoHttp]
            .every((c) => c != 201),
        isTrue,
        reason:
            'categoria ${sinCategoria.codigoHttp}, nombre ${sinNombre.codigoHttp}, '
            'descripcion ${sinDescripcion.codigoHttp}',
      );
    });
  }

  //H-08
  void prueba4CategoriaSinCursos(CursosViewModel Function() crearVm) {
    String metodo = "Listar cursos de";
    String caso = "una categoria sin cursos da lista vacia, sin dialogo de error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      expect(await vm.listarCursosDe(_v), isA<Exito<void>>());
      expect(vm.getListaCursos, isEmpty);
      expect(vm.nombresCursos, isEmpty);
    });
  }

  void prueba5CursoInexistente(CursosViewModel Function() crearVm) {
    String metodo = "Obtener curso";
    String caso = "un curso inexistente responde 404 con el error del backend";
    test('$capa - $tipo - $metodo - $caso', () async {
      final r = await crearVm().obtenerCurso(_n.titulo, 'noexiste_$_marca');
      expect(r.codigoHttp, 404);
      expect(r.error?.mensaje, contains('GC-0003'));
    });
  }

  //sale rojo: solo lo llama test/diagnostico/cursos/remoto_diagnostico_test.dart,
  //no main_test.dart. No cambia datos
  void diagnosticoCursosConAmpersand(CursosViewModel Function() crearVm) {
    String metodo = "Listar y obtener curso";
    String caso = "BUG CU-02 - una categoria y un curso con & se listan y se obtienen";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.listarCursosDe(_e);
      final uno = await crearVm().obtenerCurso(_e.titulo, _cursoE.nombreCurso);

      final estado =
          'lista: ${vm.getListaCursos?.map((c) => c.nombreCurso).toList()}; '
          'obtener: ${uno.codigoHttp} ${uno.error?.mensaje}';
      expect(vm.getListaCursos?.map((c) => c.nombreCurso), [_cursoE.nombreCurso], reason: estado);
      expect(uno.codigoHttp, 200, reason: estado);
    });
  }

  CursoEntidad _nuevo(CategoriaEntidad c, String nombre) => CursoEntidad(
    nombreCurso: nombre,
    nombreDeporte: _deporte,
    tituloCategoria: c.titulo,
    descripcion: 'curso para el diagnostico de cursos',
    imagenFile: _imagenPrueba(),
  );

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
