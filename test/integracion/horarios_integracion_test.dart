import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 6 (plan-diagnostico-horarios.md):
//Horariosviewmodel (tarjetas de grupos asignados y de inscripcion) con su
//cadena real hasta Conexionhorariosremoto y el transporte falso debajo. El
//contrato es propuesto: el backend no tiene horarios que observar
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late Horariosviewmodel vm;

  Grupoentidad grupo(int iterable) => Grupoentidad(
    categoria: 'Categoria Fase 4',
    curso: 'Curso Categoria Fase 4',
    anio: 2026,
    iterable: iterable,
    cupos: 10,
    fechaCreacion: '2026-10-22',
  );

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = Horariosviewmodel(
      Serviciohorario(
        Horariorepositorio(conexion: Conexionhorariosremoto(crearDioFalso(adaptador))),
      ),
    );
  });

  group('Horarios (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Cargar horarios de - 200 pide la llave y cada tarjeta recibe sus horarios', () async {
      adaptador.responder('GET', '/horarios', 200, leerContrato('horarios', 'horarios_200'));

      await vm.cargarHorariosDe([grupo(1)]);

      expect(adaptador.peticionesA('GET', '/horarios').single.uri.queryParameters, {
        'categoria': 'Categoria Fase 4',
        'curso': 'Curso Categoria Fase 4',
        'anio': '2026',
        'iterable': '1',
      });
      final estado = vm.horariosDe(grupo(1));
      expect(estado.cargando, isFalse);
      expect(estado.error, isNull);
      expect(estado.datos.map((h) => '${h.dia} ${h.horaInicio}-${h.horaFin} ${h.escenario}'), [
        'Lunes 08:00-10:00 Coliseo',
        'Miércoles 14:00-16:00 Piscina',
      ]);
    });

    test('$capa - $tipo - Cargar horarios de - 200 [] deja la tarjeta sin horarios y sin error', () async {
      adaptador.responder('GET', '/horarios', 200, []);

      await vm.cargarHorariosDe([grupo(1)]);

      expect(vm.horariosDe(grupo(1)).error, isNull);
      expect(vm.horariosDe(grupo(1)).datos, isEmpty);
    });

    test('$capa - $tipo - Cargar horarios de - una peticion por grupo; sin red cada tarjeta muestra el 503', () async {
      adaptador.fallar('GET', '/horarios', DioExceptionType.connectionError);

      await vm.cargarHorariosDe([grupo(1), grupo(2)]);

      expect(
        adaptador.peticionesA('GET', '/horarios').map((p) => p.uri.queryParameters['iterable']),
        unorderedEquals(['1', '2']),
      );
      for (final g in [grupo(1), grupo(2)]) {
        expect(vm.horariosDe(g).cargando, isFalse);
        expect(vm.horariosDe(g).error, startsWith('Código: 503'));
      }
    });

    test('$capa - $tipo - Cargar horarios de - 200 con un objeto es 406 en la tarjeta', () async {
      adaptador.responder('GET', '/horarios', 200, {'mensaje': 'no es una lista'});

      await vm.cargarHorariosDe([grupo(1)]);

      expect(vm.horariosDe(grupo(1)).error, startsWith('Código: 406'));
    });
    //los casos rojos de este montaje estan en
    //test/diagnostico/horarios/integracion_diagnostico_test.dart

    //antes HO-01: el id del horario se perdia en fromJson y en el repositorio
    test('$capa - $tipo - Cargar horarios de - el id del horario llega a la tarjeta', () async {
      adaptador.responder('GET', '/horarios', 200, leerContrato('horarios', 'horarios_200'));
      final g = grupo(1);

      await vm.cargarHorariosDe([g]);

      expect(vm.horariosDe(g).datos.map((h) => h.id), [15, 16]);
    });
  });
}
