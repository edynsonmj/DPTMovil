import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/estadisticaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
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

  EstadisticaModelo modelo(String leyenda) => EstadisticaModelo(
    leyenda1: leyenda,
    leyenda2: 'curso',
    leyenda3: '2026',
    leyenda4: '1',
    clases: 2,
    horas: 4,
    minutos: 0,
    duracion: 240,
  );

  group('Estadisticas (vm con doble):', () {
    test('$capa - $tipo - Estadisticas de grupos - 200 queda para exportar', () async {
      conexion.respuestaGrupos = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo('Deportes')],
      );

      final respuesta = await vm.estadisticasGrupos('2026-01-01', '2026-12-31');

      expect(conexion.llamadasGrupos, 1);
      expect(respuesta.codigoHttp, 200);
      expect(vm.getListEstadisticasGeneralCategorias, same(respuesta.datos));
      expect(vm.getListEstadisticasGeneralCategorias.single.leyenda1, 'Deportes');
    });

    test('$capa - $tipo - Estadisticas de grupos - un fallo no toca lo exportable', () async {
      conexion.respuestaGrupos = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo('Deportes')],
      );
      await vm.estadisticasGrupos('2026-01-01', '2026-12-31');
      final antes = vm.getListEstadisticasGeneralCategorias;

      conexion.respuestaGrupos = RespuestaModelo(
        codigoHttp: 500,
        error: ErrorModelo(
          codigoHttp: 500,
          mensaje: 'error del servidor',
          url: '/estadisticas/grupos',
          metodo: 'GET',
        ),
      );
      final respuesta = await vm.estadisticasGrupos('2026-01-01', '2026-12-31');

      expect(respuesta.codigoHttp, 500);
      expect(vm.getListEstadisticasGeneralCategorias, same(antes));
    });

    //categorias solo consulta: no guarda nada en el vm
    test('$capa - $tipo - Estadisticas de categorias - pasa el rango y no toca el estado', () async {
      conexion.respuestaCategorias = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo('Deportes')],
      );

      final respuesta = await vm.estadisticasCategorias(
        '2026-02-01',
        '2026-06-30',
      );

      expect(conexion.ultimoInicio, '2026-02-01');
      expect(conexion.ultimoFin, '2026-06-30');
      expect(respuesta.datos, isA<List<Estadistica>>());
      expect(vm.getListEstadisticasGeneralCategorias, isEmpty);
    });
  });
}
