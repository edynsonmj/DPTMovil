@Tags(['diagnostico'])
library;

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';
import '../../dobles/conexionatencionesFalsa.dart';

//pruebas de diagnostico (fase 4): afirman el comportamiento CORRECTO y se
//espera que salgan rojas mientras el bug exista. Un verde descarta la
//hipotesis. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "conexion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late Conexionatencionesremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionatencionesremoto(crearDioFalso(adaptador));
  });

  //AS-04 y AS-05 salieron de aqui el 2026-10-29: con /asistenciasClase la
  //app solo envia idClase (no hay texto que escapar) y el POST lleva
  //{idPerfil, asistio}, asi que ya no se reenvia el alumno completo
  group('Atenciones (diagnostico de la conexion):', () {
    test('$capa - $tipo - Listar atenciones - BUG AS-06 - json incompleto se devuelve como error, sin lanzar', () async {
      final incompleto = (leerContrato('atenciones', 'listar_200') as List).first;
      incompleto['asistio'] = null;
      adaptador.responder('GET', '/asistenciasClase', 200, [incompleto]);

      final resultado = await sinLanzar(
        () => conexion.obtenerAtencionesClase('Deportes', 'Iniciacion', 2026, 1, 210),
      );

      //la regla de la app: los errores se devuelven, no se lanzan
      expect(resultado.lanzado, isNull, reason: 'escapo: ${resultado.lanzado}');
      expect(resultado.respuesta!.codigoHttp, isNot(200));
      expect(resultado.respuesta!.error, isNotNull);
    });

    for (final codigo in [201, 204]) {
      test('$capa - $tipo - Registrar atenciones - BUG AS-07 - $codigo es exito', () async {
        adaptador.responder('POST', '/asistenciasClase', codigo);

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

    test('$capa - $tipo - Listar atenciones - BUG AS-12 - receiveTimeout responde 408', () async {
      adaptador.fallar(
        'GET',
        '/asistenciasClase',
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
