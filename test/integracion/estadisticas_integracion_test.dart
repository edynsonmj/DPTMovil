import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionEstadisticasRemoto.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 5 (plan-diagnostico-estadisticas.md, 4.2): el
//vm de la pantalla con su cadena real hasta Conexionestadisticasremoto y el
//transporte falso debajo, con las respuestas del contrato observado. Cubre
//lo que el backend real no deja provocar: sin red y respuestas raras
void main() {
  const String capa = "integracion";
  const String tipo = "local";
  const rutas = [
    '/estadisticas/categorias',
    '/estadisticas/cursos',
    '/estadisticas/grupos',
  ];

  late AdaptadorHttpFalso adaptador;
  late EstadisticasViewModel vm;

  List<EstadoSeccion<List<Estadistica>>> secciones() => [
    vm.categorias,
    vm.cursos,
    vm.grupos,
  ];

  void responderContrato() {
    adaptador.responder('GET', rutas[0], 200, leerContrato('estadisticas', 'categorias_200'));
    adaptador.responder('GET', rutas[1], 200, leerContrato('estadisticas', 'cursos_200'));
    adaptador.responder('GET', rutas[2], 200, leerContrato('estadisticas', 'grupos_200'));
  }

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = EstadisticasViewModel(
      ServicioEstadisticas(
        EstadisticasRespositorio(
          conexion: Conexionestadisticasremoto(crearDioFalso(adaptador)),
        ),
      ),
    );
  });

  group('Estadisticas generales (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Cargar - tres GET con el rango y las secciones del contrato', () async {
      responderContrato();

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(adaptador.peticiones.map((p) => p.ruta), unorderedEquals(rutas));
      for (final p in adaptador.peticiones) {
        expect(p.uri.queryParameters, {'inicio': '2026-01-01', 'fin': '2026-10-29'});
      }
      for (final s in secciones()) {
        expect(s.cargando, isFalse);
        expect(s.error, isNull);
      }
      //ordenadas por horas, de mayor a menor
      expect(vm.categorias.datos.map((e) => e.leyenda1), [
        'Categoria Fase 4',
        'Categoria Prueba 2',
        'Categoria1',
      ]);
      expect(vm.cursos.datos.first.leyenda2, 'Curso Categoria Fase 4');
      expect(vm.grupos.datos.map((e) => e.leyenda4), ['1', '2']);
      expect(vm.puedeExportar, isTrue);
    });

    test('$capa - $tipo - Cargar - 200 [] deja las secciones vacias, sin error ni exportacion', () async {
      for (final r in rutas) {
        adaptador.responder('GET', r, 200, []);
      }

      await vm.cargar('2026-01-01', '2026-10-29');

      for (final s in secciones()) {
        expect(s.error, isNull);
        expect(s.datos, isEmpty);
      }
      expect(vm.puedeExportar, isFalse);
    });

    test('$capa - $tipo - Cargar - sin red las tres secciones muestran el 503', () async {
      for (final r in rutas) {
        adaptador.fallar('GET', r, DioExceptionType.connectionError);
      }

      await vm.cargar('2026-01-01', '2026-10-29');

      for (final s in secciones()) {
        expect(s.cargando, isFalse);
        expect(s.error, contains('Código: 503'));
        expect(s.datos, isEmpty);
      }
    });

    test('$capa - $tipo - Cargar - 400 en texto plano muestra el codigo y el texto del backend', () async {
      responderContrato();
      adaptador.responder('GET', rutas[1], 400, 'Formato de fecha invalido');

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(vm.cursos.error, contains('Código: 400'));
      expect(vm.cursos.error, contains('Formato de fecha invalido'));
      expect(vm.categorias.error, isNull);
    });

    test('$capa - $tipo - Cargar - 200 con un objeto en vez de lista es 406', () async {
      responderContrato();
      adaptador.responder('GET', rutas[2], 200, {'mensaje': 'no es una lista'});

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(vm.grupos.error, contains('Código: 406'));
      expect(vm.puedeExportar, isFalse);
    });

    //nacio como diagnostico de ES-07
    test('$capa - $tipo - Cargar - un 401 sin cuerpo deja un mensaje en la seccion', () async {
      responderContrato();
      adaptador.responder('GET', rutas[0], 401, '');

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(vm.categorias.error, startsWith('Código: 401'));
      expect(vm.categorias.error, contains('sesión'));
    });
    //los casos rojos de este montaje (ES-02 a ES-04) estan en
    //test/diagnostico/estadisticas/integracion_diagnostico_test.dart
  });
}
