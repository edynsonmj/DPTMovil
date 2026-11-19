import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';
import '../../dobles/conexionatencionesFalsa.dart';

//errores de la conexion de atenciones (AS-06, AS-07, AS-12). Registro:
//auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late Conexionatencionesremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionatencionesremoto(crearDioFalso(adaptador));
  });

  group('Atenciones (errores de la conexion):', () {
    test('$capa - $tipo - Listar atenciones - json incompleto se devuelve como error, sin lanzar', () async {
      final alumnos = leerContrato('atenciones', 'alumnosGrupo_200') as List;
      alumnos.first['nombre'] = null;
      adaptador.responder('GET', '/alumnosGrupo', 200, alumnos);
      adaptador.responder('GET', '/atencionesporclase', 200, []);

      final resultado = await sinLanzar(
        () => conexion.obtenerAtencionesClase('Deportes', 'Iniciacion', 2026, 1, 210),
      );

      //la regla de la app: los errores se devuelven, no se lanzan
      expect(resultado.lanzado, isNull, reason: 'escapo: ${resultado.lanzado}');
      expect(resultado.respuesta!.codigoHttp, isNot(200));
      expect(resultado.respuesta!.error, isNotNull);
    });

    for (final codigo in [201, 204]) {
      test('$capa - $tipo - Registrar atenciones - $codigo es exito', () async {
        adaptador.responder('PUT', '/clase/210/asistencia', codigo);

        final resultado = await sinLanzar(
          () => conexion.registrarAtencionesClase(
            atencionesDelContrato('listar_200'),
            210,
          ),
        );

        expect(resultado.lanzado, isNull, reason: 'escapo: ${resultado.lanzado}');
        expect(resultado.respuesta!.error, isNull);
        expect(resultado.respuesta!.codigoHttp, inInclusiveRange(200, 299));
      });
    }

    test('$capa - $tipo - Listar atenciones - receiveTimeout responde 408', () async {
      adaptador.fallar(
        'GET',
        '/alumnosGrupo',
        DioExceptionType.receiveTimeout,
      );

      final respuesta = await conexion.obtenerAtencionesClase(
        'Deportes',
        'Iniciacion',
        2026,
        1,
        210,
      );

      expect(respuesta.codigoHttp, 408);
    });
  });
}

//ejecuta sin dejar escapar nada: asi la prueba distingue "devolvio un
//error" de "lanzo una excepcion" en lugar de reventar sin explicar
Future<({RespuestaModelo? respuesta, Object? lanzado})> sinLanzar(
  Future<RespuestaModelo> Function() accion,
) async {
  try {
    return (respuesta: await accion(), lanzado: null);
  } catch (e) {
    return (respuesta: null, lanzado: e);
  }
}
