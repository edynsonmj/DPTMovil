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

  //cada caso construye su vm, como la ruta estadisticasGenerales. No crean
  //datos: leen lo que haya en la bd de pruebas. Desde la fase 7c cargar()
  //pide las tres secciones y los casos leen la que les toca
  void prueba1Categorias(EstadisticasViewModel Function() crearVm) {
    String caso = "200 categorias del rango como entidades";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar(inicio, fin);
      expect(vm.categorias.cargando, isFalse);
      expect(vm.categorias.error, isNull);
      final lista = vm.categorias.datos;
      expect(lista, isA<List<Estadistica>>());
      expect(lista, isNotEmpty);
      //por categoria solo viene la primera leyenda
      expect(lista.every((e) => e.leyenda2 == null), isTrue);
    });
  }

  //la seccion de grupos es la que exporta el boton de descarga
  void prueba2GruposParaExportar(EstadisticasViewModel Function() crearVm) {
    String caso = "200 grupos con las cuatro leyendas y listos para exportar";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar(inicio, fin);
      expect(vm.grupos.error, isNull);
      final lista = vm.grupos.datos;
      expect(lista, isNotEmpty);
      //categoria, curso, anio e iterable del grupo
      expect(
        lista.every(
          (e) => e.leyenda2 != null && e.leyenda3 != null && e.leyenda4 != null,
        ),
        isTrue,
      );
      expect(vm.puedeExportar, isTrue);
    });
  }

  //visto el 2026-10-23: un rango sin clases no llega como lista vacia, el
  //backend devuelve todas las categorias con los valores en 0
  void prueba3RangoSinClases(EstadisticasViewModel Function() crearVm) {
    String caso = "rango sin clases devuelve las categorias en cero";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar('1990-01-01', '1990-12-31');
      expect(vm.cursos.error, isNull);
      final lista = vm.cursos.datos;
      expect(lista, isNotEmpty);
      expect(lista.every((e) => e.clases == 0 && e.duracion == 0), isTrue);
    });
  }

  //la pantalla siempre manda yyyy-mm-dd; una fecha mal formada da 400 y el
  //error queda en cada seccion, sin excepcion
  void prueba4FechaMalFormada(EstadisticasViewModel Function() crearVm) {
    String caso = "400 fecha mal formada vuelve como error";
    test('$capa - $tipo - $metodo - $caso', () async {
      final vm = crearVm();
      await vm.cargar('2026-1-5', fin);
      for (final seccion in [vm.categorias, vm.cursos, vm.grupos]) {
        expect(seccion.cargando, isFalse);
        expect(seccion.error, contains('400'));
        expect(seccion.datos, isEmpty);
      }
      //un fallo no deja nada que exportar
      expect(vm.puedeExportar, isFalse);
    });
  }
}
