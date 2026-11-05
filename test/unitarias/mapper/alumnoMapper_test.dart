import 'package:dpt_movil/data/mappers/alumnoMapper.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

//conversion modelo <-> entidad de alumnos, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Alumnos (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos', () {
      final entidad = AlumnoMapper.aEntidad(
        Alumnomodelo(
          id: '1061001',
          codigo: '104619011001',
          tipo: 'Estudiante',
          nombre: 'Ana Gomez',
          correo: 'anagomez@unicauca.edu.co',
          sexo: 'F',
          tipoid: 'CC',
          imagen: 12,
        ),
      );

      expect(entidad.id, '1061001');
      expect(entidad.codigo, '104619011001');
      expect(entidad.tipo, 'Estudiante');
      expect(entidad.nombre, 'Ana Gomez');
      expect(entidad.correo, 'anagomez@unicauca.edu.co');
      expect(entidad.sexo, 'F');
      expect(entidad.tipoid, 'CC');
      expect(entidad.imagen, 12);
    });

    test('$capa - $tipo - aModelo - el json lleva los campos de la entidad', () {
      final modelo = AlumnoMapper.aModelo(
        Alumnoentidad(
          id: '1061002',
          tipo: 'Estudiante',
          nombre: 'Luis Perez',
          correo: 'luisperez@unicauca.edu.co',
          sexo: 'M',
          tipoid: 'CC',
        ),
      );

      expect(modelo.toJson(), {
        'eliminadoestado': 0,
        'id': '1061002',
        'codigo': null,
        'tipo': 'Estudiante',
        'nombre': 'Luis Perez',
        'correo': 'luisperez@unicauca.edu.co',
        'sexo': 'M',
        'tipoid': 'CC',
        'imagen': null,
      });
    });
  });
}
