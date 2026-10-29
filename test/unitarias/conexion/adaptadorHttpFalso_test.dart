import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//prueba de humo del transporte falso (fase 1 del diagnostico): antes de
//usarlo debajo de las conexiones reales se comprueba que responde, registra
//y falla como se programa
void main() {
  const String capa = "conexion";
  const String tipo = "humo";

  late AdaptadorHttpFalso adaptador;
  late Dio dio;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    dio = crearDioFalso(adaptador);
  });

  group('Adaptador http falso:', () {
    test('$capa - $tipo - GET - responde el json programado y registra la peticion', () async {
      adaptador.responder(
        'GET',
        '/atencionesporclase',
        200,
        leerContrato('atenciones', 'listar_200'),
      );

      final response = await dio.get('/atencionesporclase?claseid=210');

      expect(response.statusCode, 200);
      expect(response.data, isA<List>());
      expect((response.data as List).length, 3);
      expect(adaptador.peticiones.length, 1);
      final peticion = adaptador.peticiones.single;
      expect(peticion.ruta, '/atencionesporclase');
      expect(peticion.uri.queryParameters['claseid'], '210');
    });

    test('$capa - $tipo - POST - registra el cuerpo json enviado', () async {
      adaptador.responder('POST', '/atenciones', 200);

      await dio.post(
        '/atenciones?idclase=210',
        data: [
          {'idClase': 210, 'estaAtendido': true},
        ],
      );

      final enviada = adaptador.peticionesA('POST', '/atenciones').single;
      expect(enviada.cuerpo, [
        {'idClase': 210, 'estaAtendido': true},
      ]);
    });

    test('$capa - $tipo - fallo programado - llega como DioException', () async {
      adaptador.fallar('GET', '/atencionesporclase', DioExceptionType.connectionError);

      await expectLater(
        dio.get('/atencionesporclase'),
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.connectionError,
          ),
        ),
      );
    });

    test('$capa - $tipo - ruta sin programar - responde 404 visible', () async {
      //Dio lanza en 4xx: una ruta olvidada en el test se nota
      await expectLater(
        dio.get('/inexistente'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
      expect(adaptador.peticiones.single.ruta, '/inexistente');
    });

    test('$capa - $tipo - retener - la respuesta espera al Completer', () async {
      adaptador.responder('POST', '/atenciones', 200);
      final pausa = adaptador.retener('POST', '/atenciones');

      var terminada = false;
      final peticion = dio
          .post('/atenciones', data: [])
          .then((_) => terminada = true);
      await Future<void>.delayed(Duration.zero);
      expect(terminada, isFalse);

      pausa.complete();
      await peticion;
      expect(terminada, isTrue);
    });
  });
}
