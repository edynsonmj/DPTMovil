import 'dart:io';

import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmEliminarCategoriaTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Eliminar categoria";

  //la categoria a eliminar se inserta en el mismo test para no depender de
  //datos previos en la bd ni del orden de ejecucion de los demas casos
  void prueba1codigo200(CategoriaViewModel vm) {
    String caso = "exito 200";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = "prueba_eliminar_${_marcaTiempo()}";
      Resultado<CategoriaEntidad> insercion = await vm.insertarCategoria(
        CategoriaEntidad(
          titulo: titulo,
          descripcion: "test unitario",
          imagenFile: _imagenPrueba(),
        ),
      );
      expect(insercion, isA<Exito>());
      expect(
        vm.categorias?.any((categoria) => categoria.titulo == titulo) ?? false,
        isTrue,
      );

      Resultado<void> resultado = await vm.eliminarCategoria(titulo);
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Exito>());

      //tras el 200 el vm dispara listarYNotificarCategorias, se verifica el
      //estado sin refrescar a mano
      expect(vm.cargando, isFalse);
      expect(
        vm.categorias?.any((categoria) => categoria.titulo == titulo) ?? false,
        isFalse,
      );
    });
  }

  void prueba2Inexistente(CategoriaViewModel vm) {
    String caso = "error categoria inexistente";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = "inexistente_${_marcaTiempo()}";
      final categoriasAntes = vm.categorias;
      Resultado<void> resultado = await vm.eliminarCategoria(titulo);
      _imprimirRespuesta(resultado);
      //el backend responde 404 GC-0003 al no encontrar el titulo
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 404);
      expect(resultado.mensaje, contains('No se encuentra registrado'));
      //un fallo no refresca: la lista sigue siendo la misma instancia
      expect(identical(vm.categorias, categoriasAntes), isTrue);
    });
  }

  void prueba3TituloVacio(CategoriaViewModel vm) {
    String caso = "error titulo vacio";
    test('$capa - $tipo - $metodo - $caso', () async {
      final categoriasAntes = vm.categorias;
      Resultado<void> resultado = await vm.eliminarCategoria("");
      _imprimirRespuesta(resultado);
      //backend nuevo (2026-11-05): el DELETE ya valida el titulo vacio y
      //responde 400; antes lo trataba como inexistente (404)
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect(resultado.mensaje, isNotEmpty);
      expect(identical(vm.categorias, categoriasAntes), isTrue);
    });
  }

  //el origen del fallo indica que peticion lo genero
  void _imprimirRespuesta(Resultado resultado) {
    if (resultado is Fallo) {
      print('codigo: ${resultado.codigo}');
      print('error mensaje: ${resultado.mensaje}');
      print('error origen: ${resultado.origen}');
    } else {
      print('exito');
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
