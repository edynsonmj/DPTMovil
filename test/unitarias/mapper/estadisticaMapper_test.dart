import 'package:dpt_movil/data/mappers/estadisticaMapper.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//conversion modelo -> entidad de estadisticas, contra los contratos de
///estadisticas
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  List<EstadisticaModelo> modelos(String nombre) =>
      (leerContrato('estadisticas', nombre) as List)
          .map(EstadisticaModelo.fromJson)
          .toList();

  group('Estadisticas (mapper):', () {
    test('$capa - $tipo - aEntidad - copia las cuatro leyendas y las cifras', () {
      final entidad = EstadisticaMapper.aEntidad(modelos('grupos_200').first);

      expect(entidad.leyenda1, 'Categoria Fase 4');
      expect(entidad.leyenda2, 'Curso Categoria Fase 4');
      expect(entidad.leyenda3, '2026');
      expect(entidad.leyenda4, '1');
      expect(entidad.clases, 4.0);
      expect(entidad.horas, 27.0);
      expect(entidad.minutos, 0.0);
      expect(entidad.duracion, 1620.0);
    });

    test('$capa - $tipo - aEntidades - convierte la lista en orden', () {
      final lista = modelos('categorias_200');

      final entidades = EstadisticaMapper.aEntidades(lista);

      expect(entidades.map((e) => e.leyenda1), lista.map((m) => m.leyenda1));
      expect(entidades.first.leyenda2, isNull);
    });
  });
}
