import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionEstadisticasFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 7
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionEstadisticasFalsa conexion;
  late EstadisticasRespositorio repositorio;

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexionEstadisticasFalsa();
    repositorio = EstadisticasRespositorio(conexion: conexion);
  });

  group('Estadisticas (repositorio con doble):', () {
    test('$capa - $tipo - Estadisticas de grupos - 200 convierte a entidades', () async {
      conexion.respuestaGrupos = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          EstadisticaModelo(
            leyenda1: 'Deportes',
            leyenda2: 'Iniciacion',
            leyenda3: '2026',
            leyenda4: '1',
            clases: 4,
            horas: 27,
            minutos: 30,
            duracion: 1650,
          ),
        ],
      );

      final respuesta = await repositorio.generalGrupos(
        '2026-01-01',
        '2026-12-31',
      );

      expect(conexion.llamadasGrupos, 1);
      expect(conexion.ultimoInicio, '2026-01-01');
      expect(conexion.ultimoFin, '2026-12-31');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Estadistica>>());
      final estadistica = (respuesta.datos as List<Estadistica>).single;
      expect(estadistica.leyenda1, 'Deportes');
      expect(estadistica.leyenda2, 'Iniciacion');
      expect(estadistica.leyenda3, '2026');
      expect(estadistica.leyenda4, '1');
      expect(estadistica.clases, 4);
      expect(estadistica.horas, 27);
      expect(estadistica.minutos, 30);
      expect(estadistica.duracion, 1650);
    });

    //un 200 que no trae la lista esperada no llega a la vista como exito
    test('$capa - $tipo - Estadisticas de categorias - 200 sin lista pasa a codigo 0', () async {
      conexion.respuestaCategorias = RespuestaModelo(
        codigoHttp: 200,
        datos: {'mensaje': 'no es una lista'},
      );

      final respuesta = await repositorio.generalCategorias(
        '2026-01-01',
        '2026-12-31',
      );

      expect(respuesta.codigoHttp, 0);
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Estadisticas de cursos - 400 pasa sin cambios', () async {
      final fallo = RespuestaModelo(
        codigoHttp: 400,
        error: ErrorModelo(
          codigoHttp: 400,
          mensaje: 'fecha invalida',
          url: '/estadisticas/cursos',
          metodo: 'GET',
        ),
      );
      conexion.respuestaCursos = fallo;

      final respuesta = await repositorio.generalCursos('2026-1-5', '2026-12-31');

      expect(conexion.llamadasCursos, 1);
      expect(respuesta, same(fallo));
      expect(respuesta.codigoHttp, 400);
    });
  });

  //diagnostico del modulo 5 (plan-diagnostico-estadisticas.md, 4.1)
  group('Estadisticas (repositorio con doble, rutas y errores):', () {
    EstadisticaModelo modelo(String l1, [String? l2]) => EstadisticaModelo(
      leyenda1: l1,
      leyenda2: l2,
      clases: 2,
      horas: 3,
      minutos: 15,
      duracion: 195,
    );

    RespuestaModelo error(int codigo, String url) => RespuestaModelo(
      codigoHttp: codigo,
      error: ErrorModelo(
        codigoHttp: codigo,
        mensaje: 'fallo $codigo',
        url: url,
        metodo: 'GET',
      ),
    );

    test('$capa - $tipo - Estadisticas de categorias - 200 convierte a entidades sin leyenda2', () async {
      conexion.respuestaCategorias = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo('Deportes'), modelo('Cultura')],
      );

      final respuesta = await repositorio.generalCategorias('2026-01-01', '2026-12-31');

      expect(respuesta.codigoHttp, 200);
      final lista = respuesta.datos as List<Estadistica>;
      expect(lista.map((e) => e.leyenda1), ['Deportes', 'Cultura']);
      expect(lista.every((e) => e.leyenda2 == null), isTrue);
      expect(lista.first.duracion, 195);
    });

    test('$capa - $tipo - Estadisticas de cursos - 200 convierte a entidades con categoria y curso', () async {
      conexion.respuestaCursos = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo('Deportes', 'Natacion')],
      );

      final respuesta = await repositorio.generalCursos('2026-01-01', '2026-12-31');

      final e = (respuesta.datos as List<Estadistica>).single;
      expect(e.leyenda1, 'Deportes');
      expect(e.leyenda2, 'Natacion');
      expect(e.horas, 3);
      expect(e.minutos, 15);
    });

    test('$capa - $tipo - Estadisticas de las tres rutas - 200 [] es una lista vacia de entidades', () async {
      for (final pedir in [
        repositorio.generalCategorias,
        repositorio.generalCursos,
        repositorio.generalGrupos,
      ]) {
        final respuesta = await pedir('2026-01-01', '2026-12-31');
        expect(respuesta.codigoHttp, 200);
        expect(respuesta.datos, isA<List<Estadistica>>());
        expect(respuesta.datos, isEmpty);
        expect(respuesta.error, isNull);
      }
    });

    test('$capa - $tipo - Estadisticas de categorias y grupos - un error pasa sin cambios', () async {
      final falloCategorias = error(503, '/estadisticas/categorias');
      final falloGrupos = error(500, '/estadisticas/grupos');
      conexion.respuestaCategorias = falloCategorias;
      conexion.respuestaGrupos = falloGrupos;

      expect(
        await repositorio.generalCategorias('2026-01-01', '2026-12-31'),
        same(falloCategorias),
      );
      expect(
        await repositorio.generalGrupos('2026-01-01', '2026-12-31'),
        same(falloGrupos),
      );
    });

    test('$capa - $tipo - Estadisticas de cursos y grupos - 200 sin lista pasa a codigo 0', () async {
      conexion.respuestaCursos = RespuestaModelo(codigoHttp: 200, datos: 'texto');
      conexion.respuestaGrupos = RespuestaModelo(codigoHttp: 200, datos: {'a': 1});

      final cursos = await repositorio.generalCursos('2026-01-01', '2026-12-31');
      final grupos = await repositorio.generalGrupos('2026-01-01', '2026-12-31');

      expect(cursos.codigoHttp, 0);
      expect(cursos.error?.url, '/estadisticas/cursos');
      expect(grupos.codigoHttp, 0);
      expect(grupos.error?.url, '/estadisticas/grupos');
    });

    //un TypeError de la conexion atraviesa el repositorio: BUG ES-01, en
    //test/diagnostico/estadisticas/repositorio_diagnostico_test.dart
  });
}
