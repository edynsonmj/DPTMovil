import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionGruposRemoto.dart';
import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/periodoInscripcionModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de grupos sobre el transporte falso (plan de abrir
//inscripciones, fase 2): periodo de inscripcion de un grupo, con las
//respuestas observadas del backend en test/contratos/inscripciones
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late Conexiongruposremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexiongruposremoto(crearDioFalso(adaptador));
  });

  Future<RespuestaModelo> abrir(PeriodoInscripcionModelo periodo) =>
      conexion.abrirInscripciones(
        'prueba_actualizar_20260817183250444203',
        'curso prueba',
        2026,
        2,
        periodo,
      );

  Future<RespuestaModelo> cerrar() => conexion.cerrarInscripciones(
    'prueba_actualizar_20260817183250444203',
    'curso prueba',
    2026,
    2,
  );

  group('Grupos, periodo de inscripcion (conexion remota con transporte falso):', () {
    test('$capa - $tipo - Grupos no eliminados - 200 convierte a modelos con su periodo', () async {
      adaptador.responder(
        'GET',
        '/gruposNoEliminados',
        200,
        leerContrato('inscripciones', 'gruposNoEliminados_200'),
      );

      final respuesta = await conexion.obtenerGruposNoEliminados();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<GrupoModelo>>());
      final grupos = respuesta.datos as List<GrupoModelo>;
      expect(grupos.map((g) => g.fechaInscripcionApertura), [
        '2026-10-29',
        null,
        '2026-10-28',
      ]);
      expect(grupos.map((g) => g.fechaInscripcionCierre), [
        '2026-12-31',
        null,
        '2026-10-28',
      ]);
    });

    test('$capa - $tipo - Aplicar periodo - envia la llave del grupo y las fechas en el cuerpo y devuelve el grupo', () async {
      adaptador.responder('PATCH', '/grupo/periodo', 200, leerContrato('inscripciones', 'periodo_200'));

      final respuesta = await conexion.abrirInscripciones(
        'Fútbol & Voleibol',
        'Nivel 1 + avanzado',
        2026,
        3,
        PeriodoInscripcionModelo(apertura: '2026-10-29', cierre: '2026-11-30'),
      );

      final peticion = adaptador.peticionesA('PATCH', '/grupo/periodo').single;
      expect(peticion.cuerpo, {
        'fechaApertura': '2026-10-29',
        'fechaCierre': '2026-11-30',
        'grupos': [
          {'categoria': 'Fútbol & Voleibol', 'curso': 'Nivel 1 + avanzado', 'anio': 2026, 'iterable': 3},
        ],
      });
      expect(respuesta.codigoHttp, 200);
      final grupo = respuesta.datos as GrupoModelo;
      expect(grupo.iterable, 2);
      expect(grupo.fechaInscripcionApertura, '2026-10-29');
      expect(grupo.fechaInscripcionCierre, '2026-11-30');
    });

    test('$capa - $tipo - Aplicar periodo - sin apertura no la envia', () async {
      adaptador.responder('PATCH', '/grupo/periodo', 200, leerContrato('inscripciones', 'periodo_200'));

      await abrir(PeriodoInscripcionModelo(cierre: '2026-11-30'));

      final cuerpo = adaptador.peticionesA('PATCH', '/grupo/periodo').single.cuerpo as Map;
      expect(cuerpo.containsKey('fechaApertura'), isFalse);
      expect(cuerpo['fechaCierre'], '2026-11-30');
    });

    test('$capa - $tipo - Aplicar periodo - 422 de fechas llega con el mensaje del backend', () async {
      adaptador.responder('PATCH', '/grupo/periodo', 422, leerContrato('inscripciones', 'periodo_422_cierre'));

      final respuesta = await abrir(
        PeriodoInscripcionModelo(apertura: '2026-11-25', cierre: '2026-11-05'),
      );

      expect(respuesta.codigoHttp, 422);
      expect(respuesta.error?.mensaje, contains('GC-0015'));
      expect(respuesta.error?.metodo, 'PATCH');
    });

    test('$capa - $tipo - Aplicar periodo - 404 de grupo inexistente', () async {
      adaptador.responder('PATCH', '/grupo/periodo', 404, leerContrato('inscripciones', 'grupo_404'));

      final respuesta = await abrir(PeriodoInscripcionModelo(cierre: '2026-11-30'));

      expect(respuesta.codigoHttp, 404);
      expect(respuesta.error?.mensaje, contains('GC-0003'));
    });

    test('$capa - $tipo - Aplicar periodo - un 200 que no es una lista se devuelve como error, sin lanzar', () async {
      //lo que en atenciones se escapaba como TypeError (AS-06)
      adaptador.responder('PATCH', '/grupo/periodo', 200, {'inesperado': true});

      final respuesta = await abrir(PeriodoInscripcionModelo(cierre: '2026-11-30'));

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Cerrar inscripciones - va en la query con cerradas=true y devuelve el cierre manual', () async {
      adaptador.responder('PATCH', '/grupo/inscripciones', 200, leerContrato('inscripciones', 'cerrarManual_200'));

      final respuesta = await cerrar();

      final peticion = adaptador.peticionesA('PATCH', '/grupo/inscripciones').single;
      expect(peticion.cuerpo, isNull);
      expect(peticion.uri.queryParameters['iterable'], '2');
      expect(peticion.uri.queryParameters['cerradas'], 'true');
      expect((respuesta.datos as GrupoModelo).inscripcionesCerradasManual, isTrue);
    });

    test('$capa - $tipo - Reabrir inscripciones - va con cerradas=false y codifica la llave', () async {
      adaptador.responder('PATCH', '/grupo/inscripciones', 200, leerContrato('inscripciones', 'abrir_200'));

      await conexion.reabrirInscripciones('Fútbol & Voleibol', 'Nivel 1 + avanzado', 2026, 3);

      expect(adaptador.peticionesA('PATCH', '/grupo/inscripciones').single.uri.queryParameters, {
        'categoria': 'Fútbol & Voleibol',
        'curso': 'Nivel 1 + avanzado',
        'anio': '2026',
        'iterable': '3',
        'cerradas': 'false',
      });
    });

    test('$capa - $tipo - Cerrar inscripciones - sin red responde 503', () async {
      adaptador.fallar('PATCH', '/grupo/inscripciones', DioExceptionType.connectionError);

      final respuesta = await cerrar();

      expect(respuesta.codigoHttp, 503);
    });
  });
}
