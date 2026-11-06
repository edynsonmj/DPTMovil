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
