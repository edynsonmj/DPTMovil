import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider/path_provider.dart';

class VmGuardarCategoriaTest{
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Guardar categoria";

  void prueba1codigo201(CategoriaViewModel vm) {
    String caso = "exito 201";
    test('$capa - $tipo - $metodo - $caso', () async {
      WidgetsFlutterBinding.ensureInitialized();
      String url = 'https://images.vexels.com/media/users/3/130462/isolated/lists/7db804bcbdc99731a2d432435f99597b-jugador-de-futbol-pateando-silueta.png';
      File file = await descargarImagenConDioSinPathProvider(url);
      expect(file, isNotNull);
      //marca de tiempo sin separadores para que el titulo sea unico en cada corrida y seguro en la url
      String marcaTiempo = DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');
      String titulo = "prueba_$marcaTiempo";
      CategoriaEntidad entidad = CategoriaEntidad(titulo: titulo, descripcion: "test unitario", imagenFile: file);
      expect(entidad.imagenFile, isNotNull);
      Resultado<CategoriaEntidad> resultado = await vm.insertarCategoria(entidad);
      _imprimirError(resultado);
      expect(resultado, isA<Exito>());
      //tras el 201 el vm dispara listarYNotificarCategorias, se verifica el
      //estado que realmente consume la vista, no solo el codigo http
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.categorias, isNotNull);
      expect(
        vm.categorias!.any((categoria) => categoria.titulo == titulo),
        isTrue,
      );
    });

  }

  void prueba2SinImagen(CategoriaViewModel vm) {
    String caso = "error 400 sin imagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = "prueba_${_marcaTiempo()}";
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: titulo,
        descripcion: "test unitario",
      );
      Resultado<CategoriaEntidad> resultado = await vm.insertarCategoria(entidad);
      _imprimirError(resultado);
      //el repositorio corta antes de la red, no se alcanza la conexion
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      //al no ser 201 el vm no refresca la lista, la categoria no debe aparecer
      expect(
        vm.categorias?.any((categoria) => categoria.titulo == titulo) ?? false,
        isFalse,
      );
    });
  }

  void prueba3SinTitulo(CategoriaViewModel vm) {
    String caso = "error 400 sin titulo";
    test('$capa - $tipo - $metodo - $caso', () async {
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: "",
        descripcion: "test unitario",
        imagenFile: _imagenPrueba(),
      );
      Resultado<CategoriaEntidad> resultado = await vm.insertarCategoria(entidad);
      _imprimirError(resultado);
      //con imagen si se llega al backend, la validacion del titulo es suya
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect(
        vm.categorias?.any((categoria) => categoria.titulo == "") ?? false,
        isFalse,
      );
    });
  }

  void prueba4SinDescripcion(CategoriaViewModel vm) {
    String caso = "error 400 sin descripcion";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = "prueba_${_marcaTiempo()}";
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: titulo,
        descripcion: "",
        imagenFile: _imagenPrueba(),
      );
      Resultado<CategoriaEntidad> resultado = await vm.insertarCategoria(entidad);
      _imprimirError(resultado);
      //con imagen si se llega al backend, la validacion de la descripcion es suya
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect(
        vm.categorias?.any((categoria) => categoria.titulo == titulo) ?? false,
        isFalse,
      );
    });
  }

  //la url y el metodo del error indican que peticion lo genero: sirve para
  //distinguir un rechazo del backend de un fallo previo al subir la imagen
  void _imprimirError(Resultado resultado) {
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

  //imagen del proyecto, los casos de error no necesitan bajar nada de internet
  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');

  Future<File> descargarImagenConDio(String url) async {
    final Dio dio = Dio();

    // Obtener directorio temporal
    final Directory tempDir = await getTemporaryDirectory();
    final String fileName = Uri.parse(url).pathSegments.last;
    final String filePath = '${tempDir.path}/$fileName';

    // Descargar la imagen y guardarla directamente como archivo
    await dio.download(url, filePath);

    return File(filePath);
  }

  Future<File> descargarImagenConDioSinPathProvider(String url) async {
    final dio = Dio();

    // Obtener un directorio temporal del sistema operativo
    final Directory tempDir = Directory.systemTemp;
    final String fileName = url.split('/').last;
    final String filePath = '${tempDir.path}/$fileName';

    // Descargar y guardar la imagen
    await dio.download(url, filePath);

    return File(filePath);
  }

}