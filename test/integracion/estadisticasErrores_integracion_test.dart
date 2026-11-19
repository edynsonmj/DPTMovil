import 'package:dpt_movil/data/api/conexion/remoto/ConexionEstadisticasRemoto.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/presentation/view/views/estadisticas/estadisticasGeneralesView.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//errores de las estadisticas generales de punta a punta sin backend (ES-02,
//ES-03, ES-04, ES-06): el mismo montaje que estadisticas_integracion_test.dart
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late EstadisticasViewModel vm;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    adaptador.responder('GET', '/estadisticas/categorias', 200, leerContrato('estadisticas', 'categorias_200'));
    adaptador.responder('GET', '/estadisticas/cursos', 200, leerContrato('estadisticas', 'cursos_200'));
    adaptador.responder('GET', '/estadisticas/grupos', 200, leerContrato('estadisticas', 'grupos_200'));
    vm = EstadisticasViewModel(
      ServicioEstadisticas(
        EstadisticasRespositorio(
          conexion: Conexionestadisticasremoto(crearDioFalso(adaptador)),
        ),
      ),
    );
  });

  Map<String, dynamic> fila(String leyenda1, double horas, double minutos) => {
    'leyenda1': leyenda1,
    'leyenda2': null,
    'leyenda3': null,
    'leyenda4': null,
    'clases': 1.0,
    'horas': horas,
    'minutos': minutos,
    'duracion': horas * 60 + minutos,
  };

  group('Estadisticas generales (errores de punta a punta):', () {
    //una fila incompleta: fromJson lanza un TypeError que la conexion (solo
    //captura Exception) y el repositorio (sin try) dejan pasar; el vm lo
    //atrapa y la seccion muestra el texto de la excepcion
    test('$capa - $tipo - Cargar - una fila sin leyenda1 llega como error de la conexion, no como excepcion', () async {
      adaptador.responder('GET', '/estadisticas/categorias', 200, [
        {...fila('x', 1, 0), 'leyenda1': null},
      ]);

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(vm.categorias.error, isNotNull);
      //formato del vm para una RespuestaModelo con error: "Código: N - ..."
      expect(vm.categorias.error, startsWith('Código: '));
    });

    //el json no distingue 1 de 1.0: un backend que mande enteros es valido
    test('$capa - $tipo - Cargar - los numeros enteros en el json se convierten sin error', () async {
      adaptador.responder('GET', '/estadisticas/categorias', 200, [
        {
          'leyenda1': 'Deportes',
          'leyenda2': null,
          'leyenda3': null,
          'leyenda4': null,
          'clases': 2,
          'horas': 3,
          'minutos': 15,
          'duracion': 195,
        },
      ]);

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(vm.categorias.error, isNull);
      expect(vm.categorias.datos.single.duracion, 195);
    });

    //1 h 10 min y 1 h 50 min tienen las mismas "horas": el orden debe
    //respetar el tiempo total
    test('$capa - $tipo - Cargar - el orden de mayor a menor tiempo tiene en cuenta los minutos', () async {
      adaptador.responder('GET', '/estadisticas/categorias', 200, [
        fila('Una hora y diez', 1, 10),
        fila('Una hora y cincuenta', 1, 50),
      ]);

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(vm.categorias.datos.map((e) => e.leyenda1), [
        'Una hora y cincuenta',
        'Una hora y diez',
      ]);
    });

    //forma observada el 2026-11-05: tres clases de 1 h 30 llegan como horas 3,
    //minutos 90 y duracion 270. La grafica pinta `horas`: 3 en lugar de 4,5,
    //y queda detras de un grupo de 4 h justas
    test('$capa - $tipo - Cargar - la grafica usa el tiempo total cuando los minutos pasan de 60', () async {
      adaptador.responder('GET', '/estadisticas/categorias', 200, [
        fila('Cuatro horas justas', 4, 0),
        fila('Tres clases de 1 h 30', 3, 90),
      ]);

      await vm.cargar('2026-01-01', '2026-11-05');

      final grafica = EstadisticasGeneralesView.formatoDatosCategorias(
        vm.categorias.datos,
      );
      expect(grafica.first.leyenda, 'Tres clases de 1 h 30');
      expect(grafica.first.indice2, 4.5);
    });
  });
}
