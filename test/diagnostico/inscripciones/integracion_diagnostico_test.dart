@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionInscripcionRemoto.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de la inscripcion del alumno de punta a punta sin backend
//(plan-diagnostico-inscripciones.md, 4.2): el vm con su cadena real hasta
//Conexioninscripcionremoto y el transporte falso debajo, el mismo montaje
//que test/integracion/inscripcion_integracion_test.dart. Afirman el
//comportamiento CORRECTO y se espera que salgan rojas mientras el bug exista
void main() {
  const String capa = "integracion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late Inscripcionviewmodel vm;

  final grupo = Grupoentidad(
    categoria: 'Educación física',
    curso: 'Natación nivel 1',
    anio: 2026,
    iterable: 2,
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );

  Inscripcionentidad inscripcion() => Inscripcionentidad(
    alumnoId: '104619011001',
    categoria: grupo.categoria,
    curso: grupo.curso,
    anio: grupo.anio,
    iterable: grupo.iterable,
  );

  String texto(Resultado<void> r) => switch (r) {
    Exito() => 'Exito',
    Fallo(:final codigo, :final mensaje, :final origen) =>
      'Fallo $codigo $mensaje ($origen)',
  };

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    vm = Inscripcionviewmodel(
      Servicioinscripcion(
        Inscripcionrepositorio(
          conexion: Conexioninscripcionremoto(crearDioFalso(adaptador)),
        ),
      ),
    );
  });

  group('Inscripcion del alumno (diagnostico de punta a punta):', () {
    test('$capa - $tipo - Inscribir - BUG IN-11 - una inscripcion con fecha sale con la fecha en ISO 8601', () async {
      adaptador.responder('POST', '/inscripcion', 201, {'alumnoId': '104619011001'});
      adaptador.responder('GET', '/validarInscripcion', 200, true);
      final fecha = DateTime(2026, 10, 29, 8, 30);

      final resultado = await vm.agregarIncripcion(
        inscripcion()..fechaInscripcion = fecha,
      );

      expect(resultado, isA<Exito>(), reason: texto(resultado));
      final cuerpo =
          adaptador.peticionesA('POST', '/inscripcion').single.cuerpo as Map;
      expect(cuerpo['fechaInscripcion'], fecha.toIso8601String());
    });
  });
}
