import 'dart:io';

import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmListarCategoriaTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Listar categorias";

  //listarYNotificarCategorias es la unica carga de la lista: la usan
  //CategoriasView y los dos filtros de inscripciones
  void prueba1codigo200(CategoriaViewModel vm) {
    String caso = "exito 200";
    test('$capa - $tipo - $metodo - $caso', () async {
      //se inserta una categoria antes para garantizar que la lista no llegue
      //vacia: sobre una lista vacia las comprobaciones de tipo pasan solas y
      //no probarian nada
      await _insertarCategoria(vm);

      await vm.listarYNotificarCategorias();
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.categorias, isNotNull);
      expect(vm.categorias, isNotEmpty);
      //el repositorio debe convertir modelo a entidad, el modelo no sale de la
      //capa de datos
      expect(vm.categorias, everyElement(isA<CategoriaEntidad>()));
    });
  }

  void prueba2ReflejaInsercion(CategoriaViewModel vm) {
    String caso = "la lista refleja una insercion";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = await _insertarCategoria(vm);

      await vm.listarYNotificarCategorias();
      CategoriaEntidad? insertada = _buscar(vm, titulo);
      expect(insertada, isNotNull);
      //los datos deben llegar completos, no solo el titulo
      expect(insertada!.descripcion, "test unitario");
      expect(insertada.idImagen, isNotNull);
    });
  }

  void prueba3ListaEntradas(CategoriaViewModel vm) {
    String caso = "entradas del desplegable sincronizadas";
    test('$capa - $tipo - $metodo - $caso', () async {
      await _insertarCategoria(vm);
      await vm.listarYNotificarCategorias();

      //titulos alimenta el filtro de categoria de las vistas de
      //inscripciones, se construye a partir de la misma lista
      expect(vm.titulos, isNotEmpty);
      expect(vm.titulos.length, vm.categorias!.length);
      expect(
        vm.titulos,
        containsAll(vm.categorias!.map((categoria) => categoria.titulo)),
      );
    });
  }

  //inserta una categoria con titulo unico y devuelve el titulo, para que cada
  //caso trabaje sobre su propio dato
  Future<String> _insertarCategoria(CategoriaViewModel vm) async {
    String titulo = "prueba_listar_${_marcaTiempo()}";
    Resultado<CategoriaEntidad> insercion = await vm.insertarCategoria(
      CategoriaEntidad(
        titulo: titulo,
        descripcion: "test unitario",
        imagenFile: _imagenPrueba(),
      ),
    );
    expect(insercion, isA<Exito>());
    return titulo;
  }

  CategoriaEntidad? _buscar(CategoriaViewModel vm, String titulo) {
    try {
      return vm.categorias?.firstWhere(
        (categoria) => categoria.titulo == titulo,
      );
    } on StateError {
      return null;
    }
  }

  //marca de tiempo sin separadores para que el titulo sea unico en cada corrida
  //y seguro en la url
  String _marcaTiempo() =>
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');

  //imagen del proyecto, no hace falta bajar nada de internet
  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
