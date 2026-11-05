import 'package:dpt_movil/data/mappers/grupoMapper.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//conversion modelo <-> entidad de grupos, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Grupos (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos y el periodo de inscripcion', () {
      final entidad = GrupoMapper.aEntidad(
        GrupoModelo.fromJson(leerContrato('inscripciones', 'abrir_200')),
      );

      expect(entidad.categoria, 'prueba_actualizar_20260817183250444203');
      expect(entidad.curso, 'curso prueba');
      expect(entidad.anio, 2026);
      expect(entidad.iterable, 2);
      expect(entidad.imagen, 388);
      expect(entidad.cupos, 15);
      expect(entidad.idInstructor, '2');
      expect(entidad.fechaCreacion, '2026-09-03');
      expect(entidad.fechaFinalizacion, isNull);
      expect(entidad.fechaInscripcionApertura, '2026-10-29');
      expect(entidad.fechaInscripcionCierre, '2026-11-30');
    });

    test('$capa - $tipo - aModelo - el json enviado lleva los campos del alta', () {
      final modelo = GrupoMapper.aModelo(
        Grupoentidad(
          categoria: 'Futbol',
          curso: 'Futbol sala',
          anio: 2026,
          iterable: 1,
          imagen: 7,
          idInstructor: '3',
          cupos: 20,
          fechaCreacion: '2026-11-04',
        ),
      );

      expect(modelo.toJson(), {
        'categoria': 'Futbol',
        'curso': 'Futbol sala',
        'anio': 2026,
        'iterable': 1,
        'imagenGrupo': 7,
        'idInstructor': '3',
        'cupos': 20,
        'fechaCreacion': '2026-11-04',
      });
    });

    test('$capa - $tipo - aEntidades - convierte la lista en orden', () {
      final entidades = GrupoMapper.aEntidades([
        GrupoModelo(cat_titulo: 'A', cur_nombre: 'a', anio: 2026, iterable: 1, cupos: 1, fechaCreacion: '2026-01-01'),
        GrupoModelo(cat_titulo: 'B', cur_nombre: 'b', anio: 2026, iterable: 2, cupos: 1, fechaCreacion: '2026-01-01'),
      ]);

      expect(entidades.map((g) => g.clave), ['A/a/2026/1', 'B/b/2026/2']);
    });
  });
}
