import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
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
      CategoriaEntidad entidad = CategoriaEntidad(titulo: "prueba", descripcion: "test unitario", imagenFile: file);
      expect(entidad.imagenFile, isNotNull);
      RespuestaModelo respuesta = await vm.registrarCategoria(entidad);
      print(respuesta.codigoHttp);
      expect(respuesta.codigoHttp, 201);
    });

  }

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