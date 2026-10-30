@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionEstadisticasRemoto.dart';
import 'package:dpt_movil/data/repositories/estadisticasRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioEstadisticas.dart';
import 'package:dpt_movil/presentation/viewmodels/estadisticasViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de las estadisticas generales de punta a punta sin backend
//(plan-diagnostico-estadisticas.md, 4.2): el mismo montaje que
//test/integracion/estadisticas_integracion_test.dart. Afirman el
//comportamiento CORRECTO y se espera que salgan rojas mientras el bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

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

  group('Estadisticas generales (diagnostico de punta a punta):', () {
    //una fila incompleta: fromJson lanza un TypeError que la conexion (solo
    //captura Exception) y el repositorio (sin try) dejan pasar; el vm lo
    //atrapa y la seccion muestra el texto de la excepcion
    test('$capa - $tipo - Cargar - BUG ES-02 - una fila sin leyenda1 llega como error de la conexion, no como excepcion', () async {
      adaptador.responder('GET', '/estadisticas/categorias', 200, [
        {...fila('x', 1, 0), 'leyenda1': null},
      ]);

      await vm.cargar('2026-01-01', '2026-10-29');

      expect(vm.categorias.error, isNotNull);
      //formato del vm para una RespuestaModelo con error: "Código: N - ..."
      expect(vm.categorias.error, startsWith('Código: '));
    });

    //el json no distingue 1 de 1.0: un backend que mande enteros es valido
    test('$capa - $tipo - Cargar - BUG ES-03 - los numeros enteros en el json se convierten sin error', () async {
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
    test('$capa - $tipo - Cargar - BUG ES-04 - el orden de mayor a menor tiempo tiene en cuenta los minutos', () async {
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
  });
}
