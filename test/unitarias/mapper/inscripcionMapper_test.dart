import 'package:dpt_movil/data/mappers/inscripcionMapper.dart';
import 'package:dpt_movil/data/models/inscripcionResumenModelo.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

//conversion entidad -> modelo de inscripciones, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Inscripciones (mapper):', () {
    test('$capa - $tipo - aResumenes - copia el grupo y distingue la lista de espera', () {
      final resumenes = InscripcionMapper.aResumenes([
        Inscripcionresumenmodelo(categoria: 'c', curso: 'd', anio: 2026, iterable: 1, estado: 'EN_ESPERA'),
        Inscripcionresumenmodelo(categoria: 'c', curso: 'e', anio: 2026, iterable: 2, estado: 'INSCRITO'),
      ]);

      expect(resumenes.first.curso, 'd');
      expect(resumenes.first.iterable, 1);
      expect(resumenes.first.enEspera, isTrue);
      expect(resumenes.last.enEspera, isFalse);
    });

    test('$capa - $tipo - aModelo - copia los campos y las fechas', () {
      final inscripcion = DateTime(2026, 10, 29);
      final desvinculacion = DateTime(2026, 11, 4);

      final modelo = InscripcionMapper.aModelo(
        Inscripcionentidad(
          alumnoId: '1061001',
          categoria: 'Categoria Fase 4',
          curso: 'Curso Categoria Fase 4',
          anio: 2026,
          iterable: 1,
          fechaInscripcion: inscripcion,
          fechaDesvinculacion: desvinculacion,
        ),
      );

      expect(modelo.alumnoId, '1061001');
      expect(modelo.categoria, 'Categoria Fase 4');
      expect(modelo.curso, 'Curso Categoria Fase 4');
      expect(modelo.anio, 2026);
      expect(modelo.iterable, 1);
      expect(modelo.fechaInscripcion, inscripcion);
      expect(modelo.fechaDesvinculacion, desvinculacion);
    });

    test('$capa - $tipo - aModelo - sin fechas el json es el del alta', () {
      final modelo = InscripcionMapper.aModelo(
        Inscripcionentidad(
          alumnoId: '1061001',
          categoria: 'Categoria Fase 4',
          curso: 'Curso Categoria Fase 4',
          anio: 2026,
          iterable: 1,
        ),
      );

      expect(modelo.toJson(), {
        'fechaInscripcion': null,
        'fechaDesvinculacion': null,
        'alumnoId': '1061001',
        'categoria': 'Categoria Fase 4',
        'curso': 'Curso Categoria Fase 4',
        'anio': 2026,
        'iterable': 1,
        'eliminado': 0,
      });
    });
  });
}
