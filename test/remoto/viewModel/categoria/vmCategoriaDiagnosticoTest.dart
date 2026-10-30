import 'dart:io';

import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/cursosViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/deporteViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

//diagnostico del modulo 7 contra el backend real (plan-diagnostico-
//categorias.md): CategoriaViewModel con su cadena real. Cada caso crea sus
//categorias "prueba_X ..." con un vm nuevo por paso, como cada ruta. El
//setUpAll crea la categoria "prueba_X Fútbol & Voleibol" que usa el
//diagnostico de CAT-03
class VmCategoriaDiagnosticoTest {
  final String capa = "viewModel";
  final String tipo = "remoto";

  late String _marca;
  late CategoriaEntidad _conAmpersand;

  void preparar(CategoriaViewModel Function() crearVm) {
    setUpAll(() async {
      _marca = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');
      final r = await crearVm().guardarCategoria(
        titulo: 'prueba_$_marca Fútbol & Voleibol',
        descripcion: 'categoria para el diagnostico de categorias',
        imagenNueva: _imagenPrueba(),
      );
      expect(r, isA<Exito>(), reason: 'no se creo la categoria con &');
      _conAmpersand = await _buscar(crearVm, 'prueba_$_marca Fútbol & Voleibol');
    });
  }

  //CAT-15
  void prueba1TituloRepetido(CategoriaViewModel Function() crearVm) {
    String metodo = "Guardar categoria";
    String caso = "una segunda categoria con el mismo titulo no se crea";
    test('$capa - $tipo - $metodo - $caso', () async {
      final titulo = 'prueba_$_marca repetida';
      final primera = await _crear(crearVm, titulo);
      expect(primera, isA<Exito>(), reason: _texto(primera));

      final segunda = await _crear(crearVm, titulo);
      expect(segunda, isA<Fallo>(), reason: _texto(segunda));

      final vm = crearVm();
      await vm.listarYNotificarCategorias();
      expect(vm.categorias!.where((c) => c.titulo == titulo), hasLength(1));
    });
  }

  void prueba2EliminarSaleDeLaLista(CategoriaViewModel Function() crearVm) {
    String metodo = "Eliminar categoria";
    String caso = "la categoria eliminada sale de la lista y del desplegable";
    test('$capa - $tipo - $metodo - $caso', () async {
      final titulo = 'prueba_$_marca eliminar';
      expect(await _crear(crearVm, titulo), isA<Exito>());

      final vm = crearVm();
      final r = await vm.eliminarCategoria(titulo);
      expect(r, isA<Exito>(), reason: _texto(r));
      //eliminarCategoria refresca la lista del mismo vm
      expect(vm.categorias!.any((c) => c.titulo == titulo), isFalse);
      expect(vm.getListaEntradas.any((e) => e.value == titulo), isFalse);
    });
  }

  //CAT-16, observacion: no hay una regla definida que afirmar. Se imprime
  //que pasa al recrear una categoria eliminada y con los cursos de una
  //categoria eliminada
  void prueba3ObservacionBorradoLogico(
    CategoriaViewModel Function() crearVm,
    CursosViewModel Function() crearVmCurso,
    Deporteviewmodel Function() crearVmDeporte,
  ) {
    String metodo = "Eliminar categoria";
    String caso = "observacion - recrear el titulo y cursos de una categoria eliminada";
    test('$capa - $tipo - $metodo - $caso', () async {
      final titulo = 'prueba_$_marca con curso';
      expect(await _crear(crearVm, titulo), isA<Exito>());
      final deporte =
          ((await crearVmDeporte().obtenerDeportes()).datos as List<String>).first;
      final curso = await crearVmCurso().agregarCurso(
        CursoEntidad(
          nombreCurso: 'curso_$_marca',
          nombreDeporte: deporte,
          tituloCategoria: titulo,
          descripcion: 'curso de una categoria que se elimina',
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(curso.codigoHttp, 201);

      final eliminar = await crearVm().eliminarCategoria(titulo);
      final vmCursos = crearVmCurso();
      await vmCursos.listarCursosDe(null, CategoriaEntidad(titulo: titulo, descripcion: 'x'));
      final recrear = await _crear(crearVm, titulo);
      final vm = crearVm();
      await vm.listarYNotificarCategorias();

      print(
        'CAT-16 eliminar categoria con curso: ${_texto(eliminar)}; '
        'cursos de la categoria despues: ${vmCursos.getListaCursos?.length}; '
        'recrear el mismo titulo: ${_texto(recrear)}; '
        'en la lista: ${vm.categorias!.where((c) => c.titulo == titulo).length}',
      );
    });
  }

  //sale rojo: solo lo llama
  //test/diagnostico/categorias/remoto_diagnostico_test.dart, no main_test.dart
  void diagnosticoTituloConAmpersand(CategoriaViewModel Function() crearVm) {
    String metodo = "Actualizar y eliminar categoria";
    String caso = "BUG CAT-03 - una categoria con & se edita y se elimina";
    test('$capa - diagnostico - $metodo - $caso', () async {
      final editar = await crearVm().guardarCategoria(
        titulo: _conAmpersand.titulo,
        descripcion: 'descripcion editada',
        original: _conAmpersand,
      );
      final vmEliminar = crearVm();
      final eliminar = await vmEliminar.eliminarCategoria(_conAmpersand.titulo);
      final sigue = vmEliminar.categorias?.any((c) => c.titulo == _conAmpersand.titulo);

      final estado = 'editar: ${_texto(editar)}; eliminar: ${_texto(eliminar)}; sigue en la lista: $sigue';
      expect(editar, isA<Exito>(), reason: estado);
      expect(eliminar, isA<Exito>(), reason: estado);
      expect(sigue, isFalse, reason: estado);
    });
  }

  Future<Resultado<CategoriaEntidad>> _crear(
    CategoriaViewModel Function() crearVm,
    String titulo,
  ) => crearVm().guardarCategoria(
    titulo: titulo,
    descripcion: 'categoria para el diagnostico de categorias',
    imagenNueva: _imagenPrueba(),
  );

  Future<CategoriaEntidad> _buscar(
    CategoriaViewModel Function() crearVm,
    String titulo,
  ) async {
    final vm = crearVm();
    await vm.listarYNotificarCategorias();
    return vm.categorias!.firstWhere((c) => c.titulo == titulo);
  }

  String _texto(Resultado r) => switch (r) {
    Exito() => 'Exito',
    Fallo(:final codigo, :final mensaje) => 'Fallo $codigo $mensaje',
  };

  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
