import 'dart:io';

import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCategoriaFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 1: estos
//casos deben pasar igual antes y despues de migrar categorias
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionCategoriaFalsa conexion;
  late CategoriaRepositorio repositorio;

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexionCategoriaFalsa();
    repositorio = CategoriaRepositorio(cliente: conexion);
  });

  group('Categorias (repositorio con doble):', () {
    test('$capa - $tipo - Listar categorias - 200 convierte a entidades', () async {
      conexion.respuestaListar = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          categoriaModelo(titulo: 'Futbol', descripcion: 'Desc 1', imagenId: 7),
          categoriaModelo(titulo: 'Natacion', descripcion: 'Desc 2'),
        ],
      );

      final respuesta = await repositorio.encontrarCategorias();

      expect(respuesta.codigoHttp, 200);
      //ningun modelo sale de la capa de datos
      expect(respuesta.datos, isA<List<CategoriaEntidad>>());
      final lista = respuesta.datos as List<CategoriaEntidad>;
      expect(lista.map((c) => c.titulo), ['Futbol', 'Natacion']);
      expect(lista[0].descripcion, 'Desc 1');
      expect(lista[0].idImagen, 7);
      expect(lista[1].idImagen, isNull);
    });

    test('$capa - $tipo - Listar categorias - 204 pasa sin cambios', () async {
      final vacia = RespuestaModelo(codigoHttp: 204);
      conexion.respuestaListar = vacia;

      final respuesta = await repositorio.encontrarCategorias();

      expect(respuesta, same(vacia));
      expect(respuesta.codigoHttp, 204);
    });

    test('$capa - $tipo - Guardar categoria - 201 devuelve entidad', () async {
      conexion.respuestaGuardar = RespuestaModelo(
        codigoHttp: 201,
        datos: categoriaModelo(
          titulo: 'Futbol',
          descripcion: 'Desc',
          imagenId: 9,
        ),
      );

      final respuesta = await repositorio.insertarCategoria(
        CategoriaEntidad(titulo: 'Futbol', descripcion: 'Desc', idImagen: 9),
      );

      expect(respuesta.codigoHttp, 201);
      expect(respuesta.datos, isA<CategoriaEntidad>());
      final entidad = respuesta.datos as CategoriaEntidad;
      expect(entidad.titulo, 'Futbol');
      expect(entidad.idImagen, 9);
      //la peticion llego armada a la conexion
      expect(conexion.llamadasGuardar, 1);
      expect(conexion.ultimaGuardada?.titulo, 'Futbol');
      expect(conexion.ultimaGuardada?.descripcion, 'Desc');
    });

    test('$capa - $tipo - Actualizar categoria - 200 envia el imagenId', () async {
      conexion.respuestaActualizar = RespuestaModelo(
        codigoHttp: 200,
        datos: categoriaModelo(
          titulo: 'Futbol',
          descripcion: 'Nueva',
          imagenId: 4,
        ),
      );

      final respuesta = await repositorio.actualizarCategoria(
        CategoriaEntidad(titulo: 'Futbol', descripcion: 'Nueva', idImagen: 4),
      );

      //el backend responde 400 si el PUT llega sin imagenId
      expect(conexion.ultimaActualizada?.imagenId, 4);
      expect(conexion.ultimaActualizada?.imagenFile, isNull);
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<CategoriaEntidad>());
      expect((respuesta.datos as CategoriaEntidad).descripcion, 'Nueva');
    });
  });

  //diagnostico del modulo 7 (plan-diagnostico-categorias.md, U-Repo)
  group('Categorias (repositorio con doble, errores y peticiones):', () {
    RespuestaModelo error(int codigo, String metodo) => RespuestaModelo(
      codigoHttp: codigo,
      error: ErrorModelo(
        codigoHttp: codigo,
        mensaje: 'fallo $codigo',
        url: '/categoria',
        metodo: metodo,
      ),
    );

    test('$capa - $tipo - Listar categorias - un error pasa sin cambios', () async {
      final e500 = error(500, 'GET');
      conexion.respuestaListar = e500;

      expect(await repositorio.encontrarCategorias(), same(e500));
    });

    test('$capa - $tipo - Guardar categoria - sin archivo ni idImagen es 400 y no llama a la conexion', () async {
      final respuesta = await repositorio.insertarCategoria(
        CategoriaEntidad(titulo: 'Futbol', descripcion: 'Desc'),
      );

      expect(respuesta.codigoHttp, 400);
      expect(conexion.llamadasGuardar, 0);
    });

    test('$capa - $tipo - Guardar categoria - con archivo lo pasa a la conexion y un error pasa sin cambios', () async {
      final e400 = error(400, 'POST');
      conexion.respuestaGuardar = e400;
      final archivo = File('assets/images/1.jpg');

      final respuesta = await repositorio.insertarCategoria(
        CategoriaEntidad(titulo: 'Futbol', descripcion: 'Desc', imagenFile: archivo),
      );

      expect(conexion.ultimaGuardada?.imagenFile, same(archivo));
      expect(respuesta, same(e400));
    });

    test('$capa - $tipo - Actualizar categoria - con imagen nueva pasa el archivo y conserva el id', () async {
      final archivo = File('assets/images/1.jpg');
      conexion.respuestaActualizar = error(404, 'PUT');

      final respuesta = await repositorio.actualizarCategoria(
        CategoriaEntidad(
          titulo: 'Futbol',
          descripcion: 'Desc',
          idImagen: 4,
          imagenFile: archivo,
        ),
      );

      expect(conexion.ultimaActualizada?.imagenFile, same(archivo));
      expect(conexion.ultimaActualizada?.imagenId, 4);
      expect(respuesta.codigoHttp, 404);
    });

    test('$capa - $tipo - Eliminar categoria - pasa el titulo y un error pasa sin cambios', () async {
      final e404 = error(404, 'DELETE');
      conexion.respuestaEliminar = e404;

      final respuesta = await repositorio.eliminarCategoria('Fútbol & Voleibol');

      expect(conexion.ultimoTituloEliminado, 'Fútbol & Voleibol');
      expect(respuesta, same(e404));
    });
    //los casos rojos (CAT-13 y CAT-14) estan en
    //test/diagnostico/categorias/repositorio_diagnostico_test.dart
  });
}
