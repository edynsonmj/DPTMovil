import 'dart:math';

import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

class Obtenercategoriaslocal {
  void prueba1ObtenerLista(CategoriaRepositorio repositorio) {
    test("se obtienen todas las categorias", () async {
      RespuestaModelo respuesta = await repositorio.encontrarCategorias();
      expect(200, respuesta.codigoHttp);
    });
  }

  void prueba2ListaTipo(CategoriaRepositorio repositorio) {
    test('la lista es del tipo correcto', () async {
      RespuestaModelo respuesta = await repositorio.encontrarCategorias();
      expect(respuesta.datos, everyElement(isA<CategoriaEntidad>()));
    });
  }
}
