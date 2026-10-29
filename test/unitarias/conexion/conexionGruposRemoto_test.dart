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

    test('$capa - $tipo - Abrir inscripciones - la llave del grupo va codificada en la query', () async {
      adaptador.responder(
        'PUT',
        '/abrirInscripcionesGrupo',
        200,
        leerContrato('inscripciones', 'abrir_200'),
      );

      //titulos con espacios, tilde, "&" y "+": lo que rompio AS-04 en
      //atenciones
      await conexion.abrirInscripciones(
        'Fútbol & Voleibol',
        'Nivel 1 + avanzado',
        2026,
        3,
        PeriodoInscripcionModelo(),
      );

      final peticion =
          adaptador.peticionesA('PUT', '/abrirInscripcionesGrupo').single;
      expect(peticion.uri.queryParameters, {
        'categoria': 'Fútbol & Voleibol',
        'curso': 'Nivel 1 + avanzado',
        'anio': '2026',
        'iterable': '3',
      });
    });

    test('$capa - $tipo - Abrir inscripciones - envia el periodo y devuelve el grupo actualizado', () async {
      adaptador.responder(
        'PUT',
        '/abrirInscripcionesGrupo',
        200,
        leerContrato('inscripciones', 'abrir_200'),
      );

      final respuesta = await abrir(
        PeriodoInscripcionModelo(apertura: '2026-10-29', cierre: '2026-11-30'),
      );

      final peticion =
          adaptador.peticionesA('PUT', '/abrirInscripcionesGrupo').single;
      expect(peticion.cuerpo, {
        'fechaInscripcionApertura': '2026-10-29',
        'fechaIncripcionCierre': '2026-11-30',
      });
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<GrupoModelo>());
      final grupo = respuesta.datos as GrupoModelo;
      expect(grupo.iterable, 2);
      expect(grupo.fechaInscripcionApertura, '2026-10-29');
      expect(grupo.fechaInscripcionCierre, '2026-11-30');
    });

    test('$capa - $tipo - Abrir inscripciones - sin fechas envia un cuerpo vacio', () async {
      adaptador.responder(
        'PUT',
        '/abrirInscripcionesGrupo',
        200,
        leerContrato('inscripciones', 'abrir_200'),
      );

      await abrir(PeriodoInscripcionModelo());

      final peticion =
          adaptador.peticionesA('PUT', '/abrirInscripcionesGrupo').single;
      expect(peticion.cuerpo, isEmpty);
    });

    test('$capa - $tipo - Abrir inscripciones - 400 de fechas llega con el mensaje del backend', () async {
      adaptador.responder(
        'PUT',
        '/abrirInscripcionesGrupo',
        400,
        leerContrato('inscripciones', 'abrir_400_cierre'),
      );

      final respuesta = await abrir(
        PeriodoInscripcionModelo(apertura: '2026-11-10', cierre: '2026-11-01'),
      );

      expect(respuesta.codigoHttp, 400);
      expect(respuesta.error?.mensaje, contains('cierreValido'));
      expect(respuesta.error?.metodo, 'PUT');
    });

    test('$capa - $tipo - Abrir inscripciones - 404 de grupo inexistente', () async {
      adaptador.responder(
        'PUT',
        '/abrirInscripcionesGrupo',
        404,
        leerContrato('inscripciones', 'grupo_404'),
      );

      final respuesta = await abrir(PeriodoInscripcionModelo());

      expect(respuesta.codigoHttp, 404);
      expect(respuesta.error?.mensaje, contains('GC-0003'));
    });

    test('$capa - $tipo - Cerrar inscripciones - sin cuerpo y devuelve el grupo cerrado', () async {
      adaptador.responder(
        'PUT',
        '/cerrarInscripcionesGrupo',
        200,
        leerContrato('inscripciones', 'cerrar_200'),
      );

      final respuesta = await cerrar();

      final peticion =
          adaptador.peticionesA('PUT', '/cerrarInscripcionesGrupo').single;
      expect(peticion.cuerpo, isNull);
      expect(peticion.uri.queryParameters['iterable'], '2');
      expect(respuesta.codigoHttp, 200);
      final grupo = respuesta.datos as GrupoModelo;
      expect(grupo.fechaInscripcionCierre, '2026-10-28');
    });

    test('$capa - $tipo - Cerrar inscripciones - sin red responde 503', () async {
      adaptador.fallar(
        'PUT',
        '/cerrarInscripcionesGrupo',
        DioExceptionType.connectionError,
      );

      final respuesta = await cerrar();

      expect(respuesta.codigoHttp, 503);
    });

    test('$capa - $tipo - Abrir inscripciones - un 200 que no es un grupo se devuelve como error, sin lanzar', () async {
      //lo que en atenciones se escapaba como TypeError (AS-06)
      adaptador.responder('PUT', '/abrirInscripcionesGrupo', 200, {
        'inesperado': true,
      });

      final respuesta = await abrir(PeriodoInscripcionModelo());

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
