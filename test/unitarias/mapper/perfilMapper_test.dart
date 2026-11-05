import 'package:dpt_movil/data/mappers/perfilMapper.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/domain/entities/PerfilEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

//conversion modelo <-> entidad del perfil, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Perfil (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos y el rol', () {
      final entidad = PerfilMapper.aEntidad(
        Perfilmodelo(
          id: '1061001',
          nombre: 'Ana Gomez',
          correo: 'anagomez@unicauca.edu.co',
          tipoId: 'CC',
          sexo: 'F',
          role: 'Alumno',
          facultad: 'Ingenieria',
          tipoAlumno: 'Estudiante',
        ),
      );

      expect(entidad.id, '1061001');
      expect(entidad.nombre, 'Ana Gomez');
      expect(entidad.correo, 'anagomez@unicauca.edu.co');
      expect(entidad.tipoId, 'CC');
      expect(entidad.sexo, 'F');
      expect(entidad.role, 'Alumno');
      expect(entidad.facultad, 'Ingenieria');
      expect(entidad.tipoAlumno, 'Estudiante');
    });

    test('$capa - $tipo - aModelo - el json del registro lleva los campos de la entidad', () {
      final modelo = PerfilMapper.aModelo(
        PerfilEntidad(
          id: '1061001',
          nombre: 'Ana Gomez',
          correo: 'anagomez@unicauca.edu.co',
          tipoId: 'CC',
          sexo: 'F',
          facultad: 'Ingenieria',
          tipoAlumno: 'Estudiante',
        ),
      );

      expect(modelo.toJson(), {
        'id': '1061001',
        'nombre': 'Ana Gomez',
        'correo': 'anagomez@unicauca.edu.co',
        'tipoId': 'CC',
        'sexo': 'F',
        'facultad': 'Ingenieria',
        'tipoAlumno': 'Estudiante',
        'role': null,
      });
    });
  });
}
