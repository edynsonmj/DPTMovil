import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/estadistica.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmEstadisticasTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Estadisticas generales";

  //rango que cubre todo lo que crean los tests remotos (2026)
  static const String inicio = '2020-01-01';
  static const String fin = '2030-12-31';

  //cada caso construye su vm, como hara la ruta estadisticasGenerales. No
  //crean datos: leen lo que haya en la bd de pruebas
  void prueba1Categorias(EstadisticasViewModel Function() crearVm) {
    String caso = "200 categorias del rango como entidades";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      RespuestaModelo respuesta = await vm.estadisticasCategorias(inicio, fin);
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Estadistica>>());
      final lista = respuesta.datos as List<Estadistica>;
      expect(lista, isNotEmpty);
      //por categoria solo viene la primera leyenda
      expect(lista.every((e) => e.leyenda2 == null), isTrue);
    });
  }

  //la seccion de grupos es la que exporta el boton de descarga (hoy la
  //guarda en la lista de "categorias" del vm)
  void prueba2GruposParaExportar(EstadisticasViewModel Function() crearVm) {
    String caso = "200 grupos con las cuatro leyendas y listos para exportar";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      RespuestaModelo respuesta = await vm.estadisticasGrupos(inicio, fin);
      expect(respuesta.codigoHttp, 200);
      final lista = respuesta.datos as List<Estadistica>;
      expect(lista, isNotEmpty);
      //categoria, curso, anio e iterable del grupo
      expect(
        lista.every(
          (e) => e.leyenda2 != null && e.leyenda3 != null && e.leyenda4 != null,
        ),
        isTrue,
      );
      expect(vm.getListEstadisticasGeneralCategorias, same(lista));
    });
  }

  //visto el 2026-10-23: un rango sin clases no llega como lista vacia, el
  //backend devuelve todas las categorias con los valores en 0
  void prueba3RangoSinClases(EstadisticasViewModel Function() crearVm) {
    String caso = "rango sin clases devuelve las categorias en cero";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      RespuestaModelo respuesta = await vm.estadisticasCursos(
        '1990-01-01',
        '1990-12-31',
      );
      expect(respuesta.codigoHttp, 200);
      final lista = respuesta.datos as List<Estadistica>;
      expect(lista, isNotEmpty);
      expect(lista.every((e) => e.clases == 0 && e.duracion == 0), isTrue);
    });
  }

  //la pantalla siempre manda yyyy-mm-dd; una fecha mal formada da 400 y el
  //error vuelve en la respuesta, sin excepcion
  void prueba4FechaMalFormada(EstadisticasViewModel Function() crearVm) {
    String caso = "400 fecha mal formada vuelve como error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      RespuestaModelo respuesta = await vm.estadisticasGrupos('2026-1-5', fin);
      expect(respuesta.codigoHttp, 400);
      expect(respuesta.error, isNotNull);
      //un fallo no toca lo que se exportaria
      expect(vm.getListEstadisticasGeneralCategorias, isEmpty);
    });
  }
}
