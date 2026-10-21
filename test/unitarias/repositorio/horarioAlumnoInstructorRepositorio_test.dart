import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/horarioModelo.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/data/repositories/horarioRepositorio.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:dpt_movil/domain/entities/horarioEntidad.dart';
import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionalumnosFalsa.dart';
import '../../dobles/conexionhorariosFalsa.dart';
import '../../dobles/conexioninstructoresFalsa.dart';

//los tres repositorios que solo listan: cada uno con su doble y sin backend.
//Sus constructores no cambian en la fase 4
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  group('Horarios, alumnos e instructores (repositorio con doble):', () {
    test('$capa - $tipo - Listar horarios de grupo - 200 convierte a entidades', () async {
      final conexion = ConexionhorariosFalsa();
      conexion.respuestaHorarios = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          HorarioModelo(
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

      final respuesta = await Horariorepositorio(
        conexion: conexion,
      ).obtenerHoariosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(conexion.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Horarioentidad>>());
      final horario = (respuesta.datos as List<Horarioentidad>).single;
      expect(horario.dia, 'Lunes');
      expect(horario.horaInicio, '08:00');
      expect(horario.horaFin, '10:00');
      expect(horario.escenario, 'Coliseo');
    });

    test('$capa - $tipo - Listar alumnos de grupo - 200 convierte a entidades', () async {
      final conexion = ConexionalumnosFalsa();
      conexion.respuestaAlumnos = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Alumnomodelo(
            id: 'alu1',
            tipo: 'Estudiante',
            nombre: 'Ana',
            correo: 'ana@x.co',
            sexo: 'F',
            tipoid: 'CC',
          ),
        ],
      );

      final respuesta = await Alumnosrepositorio(
        cliente: conexion,
      ).listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(conexion.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Alumnoentidad>>());
      final alumno = (respuesta.datos as List<Alumnoentidad>).single;
      expect(alumno.id, 'alu1');
      expect(alumno.nombre, 'Ana');
    });

    test('$capa - $tipo - Listar instructores - 200 convierte a entidades', () async {
      final conexion = ConexioninstructoresFalsa();
      conexion.respuestaInstructores = RespuestaModelo(
        codigoHttp: 200,
        datos: [Instructormodelo(id: 'ins1', nombre: 'Luis')],
      );

      final respuesta = await Instructoresrepositorio(
        conexion: conexion,
      ).listarInstructores();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Instructorentidad>>());
      final instructor = (respuesta.datos as List<Instructorentidad>).single;
      //el id es el valor que el formulario de grupo envia como idInstructor
      expect(instructor.id, 'ins1');
      expect(instructor.nombre, 'Luis');
    });
  });
}
