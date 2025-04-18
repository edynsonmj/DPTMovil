import 'dart:io';

import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

class Insertarcategorialocal {
  void prueba1InsercionExitosa(CategoriaRepositorio repositorio) {
    test("exito, insercion de una categoria", () async {
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: 'nueva categoria',
        descripcion: 'la categoria',
        imagenFile: File('assets/images/1.jpg'),
      );
      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      print(respuesta.codigoHttp);
      expect(respuesta.codigoHttp, 201);
    });
  }

  void prueba2InsercionRepetida(CategoriaRepositorio repositorio) {
    test("fallo, insercion de una categoria repetida", () async {
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: 'nueva categoria',
        descripcion: 'la categoria',
        imagenFile: File('assets/images/1.jpg'),
      );
      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      respuesta = await repositorio.insertarCategoria(entidad);
      expect(respuesta.codigoHttp, 409);
    });
  }

  void prueba3InsercionIncompleta(CategoriaRepositorio repositorio) {
    test("fallo, insercion de una categoria sin imagen", () async {
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: 'nueva categoria x',
        descripcion: 'la categoria',
      );
      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      expect(respuesta.codigoHttp, 405);
    });
  }
}
