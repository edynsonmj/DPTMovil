import 'package:dpt_movil/data/models/categoriaModelo.dart';
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
}
