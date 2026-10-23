import 'dart:async';

import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionEstadisticasFalsa.dart';

//cadena real con el doble abajo, igual que la arma la raiz de composicion
void main() {
  const String capa = "viewModel";
  const String tipo = "unitaria";

  late ConexionEstadisticasFalsa conexion;
  late EstadisticasViewModel vm;

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexionEstadisticasFalsa();
    vm = EstadisticasViewModel(
      ServicioEstadisticas(EstadisticasRespositorio(conexion: conexion)),
    );
  });

  EstadisticaModelo modelo(String leyenda, {double horas = 4}) =>
      EstadisticaModelo(
        leyenda1: leyenda,
        leyenda2: 'curso',
        leyenda3: '2026',
        leyenda4: '1',
        clases: 2,
        horas: horas,
        minutos: 0,
        duracion: horas * 60,
      );

  RespuestaModelo exito(List<EstadisticaModelo> datos) =>
      RespuestaModelo(codigoHttp: 200, datos: datos);

  RespuestaModelo fallo(int codigo) => RespuestaModelo(
    codigoHttp: codigo,
    error: ErrorModelo(
      codigoHttp: codigo,
      mensaje: 'error del servidor',
      url: '/estadisticas/grupos',
      metodo: 'GET',
    ),
  );

  group('Estadisticas (vm con doble):', () {
    test('$capa - $tipo - Cargar - las tres secciones cargan a la vez', () async {
      final pausa = Completer<void>();
      conexion.antesDeResponder = (_) => pausa.future;
      var notificaciones = 0;
      vm.addListener(() => notificaciones++);

      final carga = vm.cargar('2026-01-01', '2026-12-31');

      expect(vm.inicio, '2026-01-01');
      expect(vm.fin, '2026-12-31');
      expect(vm.categorias.cargando, isTrue);
      expect(vm.cursos.cargando, isTrue);
      expect(vm.grupos.cargando, isTrue);
      expect(vm.puedeExportar, isFalse);
      expect(notificaciones, 1);

      pausa.complete();
      await carga;
      expect(vm.categorias.cargando, isFalse);
      expect(vm.cursos.cargando, isFalse);
      expect(vm.grupos.cargando, isFalse);
      //una notificacion por seccion que llega
      expect(notificaciones, 4);
    });

    test('$capa - $tipo - Cargar - pasa el rango y ordena por horas', () async {
      conexion.respuestaCategorias = exito([
        modelo('Pocas', horas: 1),
        modelo('Muchas', horas: 9),
      ]);
      conexion.respuestaGrupos = exito([modelo('Deportes')]);

      await vm.cargar('2026-02-01', '2026-06-30');

      expect(conexion.ultimoInicio, '2026-02-01');
      expect(conexion.ultimoFin, '2026-06-30');
      expect(conexion.llamadasCategorias, 1);
      expect(conexion.llamadasCursos, 1);
      expect(conexion.llamadasGrupos, 1);
      expect(vm.categorias.datos.map((e) => e.leyenda1), ['Muchas', 'Pocas']);
      expect(vm.grupos.datos.single.leyenda1, 'Deportes');
      expect(vm.puedeExportar, isTrue);
    });

    test('$capa - $tipo - Cargar - un fallo en grupos no toca las otras secciones', () async {
      conexion.respuestaCategorias = exito([modelo('Deportes')]);
      conexion.respuestaCursos = exito([modelo('Deportes')]);
      conexion.respuestaGrupos = fallo(500);

      await vm.cargar('2026-01-01', '2026-12-31');

      expect(vm.grupos.error, contains('500'));
      expect(vm.grupos.datos, isEmpty);
      expect(vm.puedeExportar, isFalse);
      expect(vm.categorias.error, isNull);
      expect(vm.categorias.datos, hasLength(1));
      expect(vm.cursos.error, isNull);
      expect(vm.cursos.datos, hasLength(1));
    });

    //el usuario cambia el rango mientras el anterior sigue en camino
    test('$capa - $tipo - Cargar - descarta lo que llega de un rango anterior', () async {
      final pausaAnterior = Completer<void>();
      conexion.antesDeResponder =
          (inicio) =>
              inicio == '2025-01-01' ? pausaAnterior.future : Future.value();
      conexion.respuestaGrupos = exito([modelo('Nuevo')]);

      final anterior = vm.cargar('2025-01-01', '2025-12-31');
      await vm.cargar('2026-01-01', '2026-12-31');
      conexion.respuestaGrupos = exito([modelo('Viejo')]);
      pausaAnterior.complete();
      await anterior;

      expect(vm.inicio, '2026-01-01');
      expect(vm.grupos.datos.single.leyenda1, 'Nuevo');
    });

    test('$capa - $tipo - Limpiar - borra el rango y las secciones', () async {
      conexion.respuestaGrupos = exito([modelo('Deportes')]);
      await vm.cargar('2026-01-01', '2026-12-31');

      vm.limpiar();

      expect(vm.inicio, isNull);
      expect(vm.fin, isNull);
      expect(vm.grupos.datos, isEmpty);
      expect(vm.grupos.cargando, isFalse);
      expect(vm.puedeExportar, isFalse);
    });

    test('$capa - $tipo - Exportar - sin grupos no exporta', () async {
      conexion.respuestaGrupos = fallo(500);
      await vm.cargar('2026-01-01', '2026-12-31');

      expect(await vm.export(), isFalse);
    });
  });
}
