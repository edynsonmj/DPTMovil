import 'package:dpt_movil/data/mappers/horarioMapper.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:flutter_test/flutter_test.dart';

//conversion modelo -> entidad de horarios, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Horarios (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos y el id', () {
      final entidad = HorarioMapper.aEntidad(
        HorarioModelo(
          id: 15,
          categoria: 'Categoria Fase 4',
          curso: 'Curso Categoria Fase 4',
          anio: 2026,
          iterable: 1,
          dia: 'Lunes',
          horaInicio: '08:00',
          horaFin: '10:00',
          escenario: 'Coliseo',
        ),
      );

      expect(entidad.id, 15);
      expect(entidad.categoria, 'Categoria Fase 4');
      expect(entidad.curso, 'Curso Categoria Fase 4');
      expect(entidad.anio, 2026);
      expect(entidad.iterable, 1);
      expect(entidad.dia, 'Lunes');
      expect(entidad.horaInicio, '08:00');
      expect(entidad.horaFin, '10:00');
      expect(entidad.escenario, 'Coliseo');
    });
  });
}
