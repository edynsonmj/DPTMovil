@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionhorariosFalsa.dart';

//diagnostico del repositorio de horarios (plan-diagnostico-horarios.md):
//afirman el comportamiento CORRECTO y se espera que salgan rojas mientras el
//bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexionhorariosFalsa conexion;
  late Horariorepositorio repositorio;

  setUp(() {
    conexion = ConexionhorariosFalsa();
    repositorio = Horariorepositorio(conexion: conexion);
  });

  group('Horarios (diagnostico del repositorio):', () {
    //la llamada a la conexion esta fuera del try del repositorio
    test('$capa - $tipo - Listar horarios de grupo - BUG HO-02 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzar = TypeError();

      final respuesta = await repositorio.obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });

    //Horarioentidad.fromModelo no copia el id
    test('$capa - $tipo - Listar horarios de grupo - BUG HO-01 - el id del horario llega a la entidad', () async {
      conexion.respuestaHorarios = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          HorarioModelo(
            id: 15,
            categoria: 'Deportes',
            curso: 'Iniciacion',
            anio: 2026,
            iterable: 1,
            dia: 'Lunes',
            horaInicio: '08:00',
            horaFin: '10:00',
            escenario: 'Coliseo',
          ),
        ],
      );

      final respuesta = await repositorio.obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect((respuesta.datos as List<Horarioentidad>).single.id, 15);
    });
  });
}
