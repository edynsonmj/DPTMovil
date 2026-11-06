import 'package:dpt_movil/data/api/conexion/remoto/ConexionInscripcionRemoto.dart';
import 'package:dpt_movil/data/models/inscripcionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de inscripciones sobre el transporte falso. Cubre IN-07:
//GET /validarInscripcion recibe la inscripcion como parametros de query (asi
//lo publica /v3/api-docs desde el 2026-10-29), no en el cuerpo
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late Conexioninscripcionremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexioninscripcionremoto(crearDioFalso(adaptador));
  });

  final inscripcion = Inscripcionmodelo(
    alumnoId: '104619011001',
    categoria: 'prueba Educación física',
    curso: 'curso & co',
    anio: 2026,
    iterable: 1,
  );

  group('Inscripciones (conexion remota con transporte falso):', () {
    test('$capa - $tipo - Validar inscripcion - la inscripcion va en la query, codificada y sin cuerpo', () async {
      adaptador.responder('GET', '/validarInscripcion', 200, true);

      await conexion.validarInscripcion(inscripcion);

      final peticion = adaptador.peticionesA('GET', '/validarInscripcion').single;
      expect(peticion.uri.queryParameters, {
        'alumnoId': '104619011001',
        'categoria': 'prueba Educación física',
        'curso': 'curso & co',
        'anio': '2026',
        'iterable': '1',
      });
      expect(peticion.cuerpo, isNull);
    });

    test('$capa - $tipo - Validar inscripcion - 200 devuelve el booleano del backend', () async {
      adaptador.responder('GET', '/validarInscripcion', 200, true);
      expect((await conexion.validarInscripcion(inscripcion)).datos, isTrue);

      adaptador.responder('GET', '/validarInscripcion', 200, false);
      expect((await conexion.validarInscripcion(inscripcion)).datos, isFalse);
    });

    test('$capa - $tipo - Validar inscripcion - 400 llega como error, no como "no inscrito"', () async {
      adaptador.responder('GET', '/validarInscripcion', 400, {
        'message': "Required parameter 'alumnoId' is not present.",
      });

      final respuesta = await conexion.validarInscripcion(inscripcion);

      expect(respuesta.codigoHttp, 400);
      expect(respuesta.datos, isNull);
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Validar inscripcion - una respuesta que no es booleana se devuelve como error, sin lanzar', () async {
      adaptador.responder('GET', '/validarInscripcion', 200, {'inscrito': true});

      final respuesta = await conexion.validarInscripcion(inscripcion);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });

    //nacio como diagnostico de IN-12: un 2xx distinto del esperado con cuerpo
    //JSON hace que fromResponse lance un TypeError (mismo mecanismo que BK-08)
    test('$capa - $tipo - Agregar inscripcion - un 200 con cuerpo se devuelve como error, sin lanzar', () async {
      adaptador.responder('POST', '/inscripcion', 200, {'alumnoId': '104619011001'});

      final respuesta = await conexion.agregarInscripcion(inscripcion);

      expect(respuesta.codigoHttp, isNot(201));
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Eliminar inscripcion - un 201 con cuerpo se devuelve como error, sin lanzar', () async {
      adaptador.responder('PUT', '/desvincularInscripcion', 201, {'alumnoId': '104619011001'});

      final respuesta = await conexion.eliminarInscripcion(inscripcion);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
