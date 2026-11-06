import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:flutter_test/flutter_test.dart';

//fromResponse arma el error de una respuesta que la conexion no esperaba. El
//cuerpo de un 2xx suele llegar como Map: nacio de CAT-07 y BK-08
void main() {
  const String capa = "modelo";
  const String tipo = "unitaria";

  Response<dynamic> respuesta(int codigo, dynamic cuerpo) => Response(
    requestOptions: RequestOptions(path: '/recurso'),
    statusCode: codigo,
    data: cuerpo,
  );

  RespuestaModelo rechazo(int codigo, dynamic cuerpo) =>
      RespuestaModelo.fromDioException(
        DioException(
          requestOptions: RequestOptions(path: '/recurso'),
          response: respuesta(codigo, cuerpo),
          type: DioExceptionType.badResponse,
        ),
        'POST',
      );

  //nacieron de IN-16 e IN-17
  group('RespuestaModelo.fromDioException:', () {
    test('$capa - $tipo - fromDioException - un rechazo del backend da solo su mensaje', () {
      final r = rechazo(422, {'codigoError': 'GC-0012', 'mensaje': 'Grupo cerrado', 'codigoHttp': 422});

      expect(r.codigoHttp, 422);
      expect(r.error?.mensaje, 'Grupo cerrado');
    });

    test('$capa - $tipo - fromDioException - un 400 por campo sigue como JSON', () {
      final r = rechazo(400, {'titulo': 'no puede estar vacio'});

      expect(jsonDecode(r.error!.mensaje), {'titulo': 'no puede estar vacio'});
    });

    test('$capa - $tipo - fromDioException - un cuerpo de texto se conserva', () {
      expect(rechazo(500, 'fallo interno').error?.mensaje, 'fallo interno');
    });

    test('$capa - $tipo - fromDioException - sin cuerpo se explica por el codigo', () {
      for (final vacio in ['', null]) {
        expect(rechazo(401, vacio).error?.mensaje, contains('sesión'));
        expect(rechazo(403, vacio).error?.mensaje, contains('permiso'));
        expect(rechazo(500, vacio).error?.mensaje, contains('500'));
      }
    });
  });

  group('RespuestaModelo.fromResponse:', () {
    test('$capa - $tipo - fromResponse - un cuerpo JSON da un mensaje legible, sin lanzar', () {
      final r = RespuestaModelo.fromResponse(respuesta(200, {'codigo': 1}), 'POST');

      expect(r.codigoHttp, 200);
      expect(r.error?.mensaje, 'Respuesta inesperada del servidor. Código: 200');
    });

    test('$capa - $tipo - fromResponse - una lista o un cuerpo vacio tampoco lanzan', () {
      for (final cuerpo in [<dynamic>[], null]) {
        final r = RespuestaModelo.fromResponse(respuesta(200, cuerpo), 'POST');

        expect(r.error?.mensaje, 'Respuesta inesperada del servidor. Código: 200');
      }
    });

    test('$capa - $tipo - fromResponse - un cuerpo de texto se conserva como mensaje', () {
      final r = RespuestaModelo.fromResponse(respuesta(409, 'ya existe'), 'POST');

      expect(r.codigoHttp, 409);
      expect(r.error?.mensaje, 'ya existe');
    });
  });
}
