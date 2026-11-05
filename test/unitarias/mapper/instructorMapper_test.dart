import 'package:dpt_movil/data/mappers/instructorMapper.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//conversion modelo -> entidad de instructores, contra el contrato de
///instructores
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Instructores (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos de /instructores', () {
      final json = (leerContrato('instructores', 'instructores_200') as List).first;

      final entidad = InstructorMapper.aEntidad(Instructormodelo.fromJson(json));

      expect(entidad.id, '2');
      expect(entidad.nombre, 'edynson muñoz jimenez');
      expect(entidad.correo, 'edynsonmj@gmail.com');
      expect(entidad.sexo, 'M');
    });
  });
}
