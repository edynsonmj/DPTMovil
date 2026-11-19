import 'package:dpt_movil/data/mappers/atencionMapper.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';

//conversion modelo <-> entidad de asistencias, contra los contratos de
///asistenciasClase en test/contratos/atenciones
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Asistencias (mapper):', () {
    test('$capa - $tipo - aEntidad - convierte la asistencia y su alumno', () {
      final json = (leerContrato('atenciones', 'listar_200') as List).first;

      final entidad = AtencionMapper.aEntidad(Atencionmodelo.fromJson(json, 7));

      expect(entidad.idClase, 7);
      expect(entidad.estaAtendido, isFalse);
      expect(entidad.alumno.id, '1061001');
      expect(entidad.alumno.nombre, 'Ana Gomez');
      expect(entidad.alumno.correo, 'anagomez@unicauca.edu.co');
    });

    test('$capa - $tipo - aModelo - ida y vuelta da el cuerpo del registro', () {
      final listar = leerContrato('atenciones', 'listar_200') as List;
      final peticion = (leerContrato('atenciones', 'confirmar_peticion') as Map)['asistencias'] as List;

      //se marcan como en la peticion del contrato y se vuelve a modelo
      final enviados = [
        for (var i = 0; i < peticion.length; i++)
          AtencionMapper.aModelo(
            AtencionMapper.aEntidad(Atencionmodelo.fromJson(listar[i], 7))
              ..estaAtendido = peticion[i]['estaAtendido'],
          ).toJson(),
      ];

      expect(enviados, peticion);
    });
  });
}
