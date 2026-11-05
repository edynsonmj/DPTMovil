import 'package:dpt_movil/data/mappers/claseMapper.dart';
import 'package:dpt_movil/data/models/claseModelo.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//conversion modelo <-> entidad de clases, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Clases (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos de /clasesGrupo', () {
      final json = (leerContrato('clases', 'clasesGrupo_200') as List).first;

      final entidad = ClaseMapper.aEntidad(Clasemodelo.fromJson(json));

      expect(entidad.codigo, 207);
      expect(entidad.idGrupoCategoria, 'Categoria Fase 4');
      expect(entidad.idGrupoCurso, 'Curso Categoria Fase 4');
      expect(entidad.idGrupoAnio, 2026);
      expect(entidad.idGrupoIterable, 1);
      expect(entidad.idInstructor, '2');
      expect(entidad.fecha, DateTime(2026, 10, 22));
      expect(entidad.horas, 10);
      expect(entidad.minutos, 0);
      expect(entidad.observacion, isNull);
      expect(entidad.eliminado, 0);
    });

    test('$capa - $tipo - aModelo - el json enviado lleva la fecha con zona', () {
      final fecha = DateTime(2026, 10, 26);

      final modelo = ClaseMapper.aModelo(
        Claseentidad(
          idGrupoCategoria: 'Categoria Fase 4',
          idGrupoCurso: 'Curso Categoria Fase 4',
          idGrupoAnio: 2026,
          idGrupoIterable: 1,
          idInstructor: '2',
          fecha: fecha,
          horas: 2,
          minutos: 30,
          observacion: 'Obs',
          eliminado: 0,
        ),
      );

      expect(modelo.toJson(), {
        'codigo': null,
        'idGrupoCategoria': 'Categoria Fase 4',
        'idGrupoCurso': 'Curso Categoria Fase 4',
        'idGrupoAnio': 2026,
        'idGrupoIterable': 1,
        'idInstructor': '2',
        'fecha': fecha.toUtc().toIso8601String(),
        'horas': 2,
        'minutos': 30,
        'observacion': 'Obs',
        'eliminado': 0,
      });
    });
    //una entidad sin fecha u horas todavia lanza: CL-04 sigue rojo en
    //test/diagnostico/clases/repositorio_diagnostico_test.dart
  });
}
