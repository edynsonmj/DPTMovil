import 'dart:io';

import 'package:dpt_movil/data/mappers/categoriaMapper.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

//conversion modelo <-> entidad de categorias, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Categorias (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos y la imagen con su id', () {
      final entidad = CategoriaMapper.aEntidad(
        categoriaModelo(
          titulo: 'Futbol',
          descripcion: 'Desc',
          imagenId: 7,
          imagen: ImagenModelo(
            id: 7,
            nombre: 'futbol.jpg',
            tipoArchivo: 'image/jpeg',
            longitud: 1024,
          ),
        ),
      );

      expect(entidad.titulo, 'Futbol');
      expect(entidad.descripcion, 'Desc');
      expect(entidad.idImagen, 7);
      expect(entidad.imagen?.id, 7);
      expect(entidad.imagen?.nombre, 'futbol.jpg');
      expect(entidad.imagen?.tipoArchivo, 'image/jpeg');
      expect(entidad.imagen?.longitud, 1024);
    });

    test('$capa - $tipo - aEntidad - sin imagen queda en null', () {
      final entidad = CategoriaMapper.aEntidad(
        categoriaModelo(titulo: 'Natacion', descripcion: 'Desc'),
      );

      expect(entidad.imagen, isNull);
      expect(entidad.idImagen, isNull);
    });

    test('$capa - $tipo - aModelo - lleva el imagenId y el archivo', () {
      final archivo = File('assets/images/1.jpg');

      final modelo = CategoriaMapper.aModelo(
        CategoriaEntidad(
          titulo: 'Futbol',
          descripcion: 'Desc',
          idImagen: 4,
          imagenFile: archivo,
        ),
      );

      expect(modelo.titulo, 'Futbol');
      expect(modelo.descripcion, 'Desc');
      expect(modelo.imagenId, 4);
      expect(modelo.imagenFile, same(archivo));
      expect(modelo.toJson(), {
        'titulo': 'Futbol',
        'descripcion': 'Desc',
        'imagenId': 4,
      });
    });
  });
}
