import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionhorariosFalsa.dart';

//diagnostico del modulo 6 (plan-diagnostico-horarios.md, U-Repo): el caso
//200 basico esta en horarioAlumnoInstructorRepositorio_test.dart; aqui van
//la lista vacia, los errores y los campos de cada horario
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionhorariosFalsa conexion;
  late Horariorepositorio repositorio;

  setUp(() {
    conexion = ConexionhorariosFalsa();
    repositorio = Horariorepositorio(conexion: conexion);
  });

  group('Horarios (repositorio con doble, listas vacias y errores):', () {
    test('$capa - $tipo - Listar horarios de grupo - 200 [] es una lista vacia de entidades y pide la llave', () async {
      final respuesta = await repositorio.obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(conexion.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Horarioentidad>>());
      expect(respuesta.datos, isEmpty);
    });

    test('$capa - $tipo - Listar horarios de grupo - un error y el 406 pasan sin cambios', () async {
      final e503 = RespuestaModelo(
        codigoHttp: 503,
        error: ErrorModelo(codigoHttp: 503, mensaje: 'sin red', url: '/horarios', metodo: 'GET'),
      );
      conexion.respuestaHorarios = e503;
      expect(await repositorio.obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1), same(e503));

      final e406 = RespuestaModelo(codigoHttp: 406);
      conexion.respuestaHorarios = e406;
      expect(await repositorio.obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1), same(e406));
    });

    test('$capa - $tipo - Listar horarios de grupo - conserva dia, horas, escenario y la llave del grupo', () async {
      conexion.respuestaHorarios = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          HorarioModelo(
            categoria: 'Deportes',
            curso: 'Iniciacion',
            anio: 2026,
            iterable: 1,
            dia: 'Miércoles',
            horaInicio: '14:00',
            horaFin: '16:00',
            escenario: 'Piscina',
          ),
        ],
      );

      final h = ((await repositorio.obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1)).datos
              as List<Horarioentidad>)
          .single;

      expect([h.categoria, h.curso, h.anio, h.iterable], ['Deportes', 'Iniciacion', 2026, 1]);
      expect([h.dia, h.horaInicio, h.horaFin, h.escenario], ['Miércoles', '14:00', '16:00', 'Piscina']);
    });
    //los casos rojos (HO-01 y HO-02) estan en
    //test/diagnostico/horarios/repositorio_diagnostico_test.dart
  });
}
