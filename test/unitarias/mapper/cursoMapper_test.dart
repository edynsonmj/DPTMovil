import 'dart:io';

import 'package:dpt_movil/data/mappers/cursoMapper.dart';
import 'package:dpt_movil/data/models/cursoModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

//conversion modelo <-> entidad de cursos, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Cursos (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos', () {
      final entidad = CursoMapper.aEntidad(
        CursoModelo(
          nombreCurso: 'Futbol sala',
          nombreDeporte: 'Futbol',
          tituloCategoria: 'Deportes de conjunto',
          descripcion: 'Desc',
          imagen: 5,
        ),
      );

      expect(entidad.nombreCurso, 'Futbol sala');
      expect(entidad.nombreDeporte, 'Futbol');
      expect(entidad.tituloCategoria, 'Deportes de conjunto');
      expect(entidad.descripcion, 'Desc');
      expect(entidad.imagen, 5);
      expect(entidad.imagenFile, isNull);
    });

    test('$capa - $tipo - aModelo - lleva la imagen y el archivo', () {
      final archivo = File('assets/images/1.jpg');

      final modelo = CursoMapper.aModelo(
        CursoEntidad(
          nombreCurso: 'Futbol sala',
          nombreDeporte: 'Futbol',
          tituloCategoria: 'Deportes de conjunto',
          descripcion: 'Desc',
          imagen: 5,
          imagenFile: archivo,
        ),
      );

      expect(modelo.imagenFile, same(archivo));
      expect(modelo.toJson(), {
        'nombre': 'Futbol sala',
        'deporte': 'Futbol',
        'categoriaCurso': 'Deportes de conjunto',
        'descripcion': 'Desc',
        'idImagen': 5,
      });
    });
  });
}
