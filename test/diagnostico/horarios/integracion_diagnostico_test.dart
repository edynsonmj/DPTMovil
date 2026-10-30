@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionHorariosRemoto.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioHorario.dart';
import 'package:dpt_movil/presentation/viewmodels/horariosViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de horarios de punta a punta sin backend (plan-diagnostico-
//horarios.md): el mismo montaje que test/integracion/horarios_integracion_test.dart.
//Afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late Horariosviewmodel vm;

  Grupoentidad grupo(String categoria, String curso) => Grupoentidad(
    categoria: categoria,
    curso: curso,
    anio: 2026,
    iterable: 1,
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

  group('Horarios (diagnostico de punta a punta):', () {
    //HorarioModelo.fromJson no lee el id que manda el backend
    test('$capa - $tipo - Cargar horarios de - BUG HO-01 - el id del horario llega a la tarjeta', () async {
      adaptador.responder('GET', '/horarios', 200, leerContrato('horarios', 'horarios_200'));
      final g = grupo('Categoria Fase 4', 'Curso Categoria Fase 4');

      await vm.cargarHorariosDe([g]);

      expect(vm.horariosDe(g).datos.map((h) => h.id), [15, 16]);
    });

    //un horario sin dia: fromJson lanza un TypeError que atraviesa la
    //conexion, el repositorio y listarHorariosGrupo del vm (solo capturan
    //Exception, o la llamada esta fuera del try)
    test('$capa - $tipo - Cargar horarios de - BUG HO-03 - un horario incompleto llega como error con codigo, no como excepcion', () async {
      final incompleto = Map<String, dynamic>.from(
        (leerContrato('horarios', 'horarios_200') as List).first,
      )..['dia'] = null;
      adaptador.responder('GET', '/horarios', 200, [incompleto]);
      final g = grupo('Categoria Fase 4', 'Curso Categoria Fase 4');

      await vm.cargarHorariosDe([g]);

      expect(vm.horariosDe(g).error, isNotNull);
      expect(vm.horariosDe(g).error, startsWith('Código: '));
    });

    //GR-05 en la conexion de horarios: el mismo defecto, sin ID nuevo
    test('$capa - $tipo - Cargar horarios de - BUG GR-05 - categoria y curso llegan completos a la query de /horarios', () async {
      adaptador.responder('GET', '/horarios', 200, []);

      await vm.cargarHorariosDe([grupo('Fútbol & Voleibol', 'Nivel 1 + 2')]);

      final query = adaptador.peticionesA('GET', '/horarios').single.uri.queryParameters;
      expect([query['categoria'], query['curso']], ['Fútbol & Voleibol', 'Nivel 1 + 2']);
    });
  });
}
