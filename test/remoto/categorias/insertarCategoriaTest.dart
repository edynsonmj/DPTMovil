import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

class InsertarCategoriaTest {
  void prueba1(Random random, CategoriaRepositorio repositorio) {
    test('Error al guardar sin imagen', () async {
      String titulo = 'nombre ${random.nextInt(1000)}';
      String descripcion = 'descripcion ${random.nextInt(1000)}';

      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: titulo,
        descripcion: descripcion,
      );

      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      imprimirRespuesta(respuesta);
      expect(respuesta.codigoHttp, 400);
      expect(respuesta.error, isA<ErrorModelo>());
    });
  }

  void prueba2Exito(Random random, CategoriaRepositorio repositorio) {
    test('Exito, todos los campos requeridos', () async {
      String titulo = 'nombre ${random.nextInt(1000)}';
      String descripcion = 'descripcion ${random.nextInt(1000)}';
      File imagen = File('assets/images/1.jpg');
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: titulo,
        descripcion: descripcion,
      );
      entidad.imagenFile = imagen;
      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      imprimirRespuesta(respuesta);
      expect(respuesta.codigoHttp, 201);
    });
  }

  void prueba3(Random random, CategoriaRepositorio repositorio) {
    test('Error, sin titulo', () async {
      String titulo = '';
      String descripcion = 'descripcion ${random.nextInt(1000)}';
      File imagen = File('assets/images/1.jpg');
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: titulo,
        descripcion: descripcion,
      );
      entidad.imagenFile = imagen;
      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      imprimirRespuesta(respuesta);
      expect(respuesta.codigoHttp, 400);
    });
  }

  void prueba4(Random random, CategoriaRepositorio repositorio) {
    test('Error, sin descripcion', () async {
      String titulo = 'nombre ${random.nextInt(1000)}';
      String descripcion = '';
      File imagen = File('assets/images/1.jpg');
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: titulo,
        descripcion: descripcion,
      );
      entidad.imagenFile = imagen;
      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      imprimirRespuesta(respuesta);
      expect(respuesta.codigoHttp, 400);
    });
  }

  void prueba5(Random random, CategoriaRepositorio repositorio) {
    test('Error, sin descripcion', () async {
      String titulo = 'nombre ${random.nextInt(1000)}';
      String descripcion = '';
      File imagen = File('assets/images/1.jpg');
      CategoriaEntidad entidad = CategoriaEntidad(
        titulo: titulo,
        descripcion: descripcion,
      );
      entidad.imagenFile = imagen;
      RespuestaModelo respuesta = await repositorio.insertarCategoria(entidad);
      imprimirRespuesta(respuesta);
      expect(respuesta.codigoHttp, 400);
    });
  }

  void imprimirRespuesta(RespuestaModelo respuesta) {
    print('codigo: ${respuesta.codigoHttp}');
    if (respuesta.datos != null) {
      imprimirDatos(respuesta.datos);
    }
    if (respuesta.error != null) {
      imprimirError(respuesta.error!);
    }
  }

  void imprimirDatos(dynamic datos) {
    print('datos tipo: ${datos.runtimeType}');
    CategoriaEntidad entidad = datos as CategoriaEntidad;
    print('datos string: ${entidad.titulo}');
    print('datos string: ${entidad.descripcion}');
    if (datos.imagen != null) {
      imprimirImagen(datos.imagen!);
    }
  }

  void imprimirImagen(ImagenEntidad imagen) {
    print('image id: ${imagen.id}');
    print('imagen nombre: ${imagen.nombre}');
  }

  void imprimirError(ErrorModelo error) {
    print('error codigo: ${error.codigoHttp}');
    print('error mensaje: ${error.mensaje}');
    print('error metodo: ${error.metodo}');
    print('error url: ${error.url}');
  }
}
