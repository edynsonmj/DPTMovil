import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de horarios sobre el transporte falso: el cuerpo es el
//HorarioDto completo (grupo incluido, con "&" intacto)
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late Conexionhorariosremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionhorariosremoto(crearDioFalso(adaptador));
  });

  HorarioModelo horario(String categoria, String curso) => HorarioModelo(
    categoria: categoria,
    curso: curso,
    anio: 2026,
    iterable: 1,
    dia: 'Lunes',
    horaInicio: '08:00',
    horaFin: '10:00',
    escenario: 'Coliseo',
  );

  group('Conexion de horarios (transporte falso):', () {
    test('$capa - $tipo - Agregar horario - 201 manda el grupo y el horario en el cuerpo', () async {
      adaptador.responder('POST', '/horario', 201, leerContrato('horarios', 'horario_201'));

      final respuesta = await conexion.agregarHorario(horario('Fútbol & Voleibol', 'Nivel 1'));

      expect(respuesta.codigoHttp, 201);
      final peticion = adaptador.peticionesA('POST', '/horario').single;
      expect(peticion.uri.queryParameters, isEmpty);
      expect(peticion.cuerpo, {
        'categoria': 'Fútbol & Voleibol',
        'curso': 'Nivel 1',
        'anio': 2026,
        'iterable': 1,
        'dia': 'Lunes',
        'horaInicio': '08:00',
        'horaFin': '10:00',
        'escenario': 'Coliseo',
      });
    });

    test('$capa - $tipo - Agregar horario - 400 y 404 vuelven como error', () async {
      adaptador.responder('POST', '/horario', 400, leerContrato('horarios', 'horario_400_rango'));
      expect((await conexion.agregarHorario(horario('A', 'B'))).codigoHttp, 400);

      adaptador.responder('POST', '/horario', 404, leerContrato('horarios', 'horario_404_grupo'));
      expect((await conexion.agregarHorario(horario('A', 'B'))).codigoHttp, 404);
    });

    test('$capa - $tipo - Eliminar horario - 200 manda prmId en la query', () async {
      adaptador.responder('DELETE', '/horario', 200, leerContrato('horarios', 'horario_201'));

      final respuesta = await conexion.eliminarHorario(15);

      expect(respuesta.codigoHttp, 200);
      expect(adaptador.peticionesA('DELETE', '/horario').single.uri.queryParameters, {'prmId': '15'});
    });

    test('$capa - $tipo - Eliminar horario - 404 y fallo de red vuelven como error', () async {
      adaptador.responder('DELETE', '/horario', 404, leerContrato('horarios', 'horario_404'));
      expect((await conexion.eliminarHorario(15)).codigoHttp, 404);

      adaptador.fallar('DELETE', '/horario', DioExceptionType.connectionTimeout);
      final respuesta = await conexion.eliminarHorario(15);
      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
