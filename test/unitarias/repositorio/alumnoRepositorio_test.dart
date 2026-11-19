import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/alumnosRepositorio.dart';
import 'package:dpt_movil/domain/entities/alumnoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionalumnosFalsa.dart';

//diagnostico del modulo 9a (plan-diagnostico-alumnos.md, U-Repo): el caso
//200 basico esta en horarioAlumnoInstructorRepositorio_test.dart; aqui van
//la lista vacia, los errores y los campos que el modelo si trae
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionalumnosFalsa conexion;
  late Alumnosrepositorio repositorio;

  setUp(() {
    conexion = ConexionalumnosFalsa();
    repositorio = Alumnosrepositorio(cliente: conexion);
  });

  group('Alumnos (repositorio con doble, listas vacias y errores):', () {
    test('$capa - $tipo - Listar alumnos de grupo - 200 [] es una lista vacia de entidades y pide la llave', () async {
      final respuesta = await repositorio.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(conexion.ultimoGrupo, 'Deportes/Iniciacion/2026/1');
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Alumnoentidad>>());
      expect(respuesta.datos, isEmpty);
    });

    test('$capa - $tipo - Listar alumnos de grupo - un error y el 406 de grupo vacio pasan sin cambios', () async {
      final e503 = RespuestaModelo(
        codigoHttp: 503,
        error: ErrorModelo(codigoHttp: 503, mensaje: 'sin red', url: '/alumnosGrupo', metodo: 'GET'),
      );
      conexion.respuestaAlumnos = e503;
      expect(await repositorio.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1), same(e503));

      final e406 = RespuestaModelo(codigoHttp: 406);
      conexion.respuestaAlumnos = e406;
      expect(await repositorio.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1), same(e406));
    });

    test('$capa - $tipo - Listar alumnos de grupo - la entidad conserva todos los campos del modelo', () async {
      conexion.respuestaAlumnos = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Alumnomodelo(
            id: '104619011001',
            codigo: '104619011001',
            tipo: 'Estudiante',
            nombre: 'Ana Ruiz',
            correo: 'ana@unicauca.edu.co',
            sexo: 'F',
            tipoid: 'CC',
            imagen: 33,
          ),
        ],
      );

      final a = ((await repositorio.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1)).datos
              as List<Alumnoentidad>)
          .single;

      expect([a.id, a.codigo, a.tipo, a.nombre, a.correo, a.sexo, a.tipoid, a.imagen], [
        '104619011001', '104619011001', 'Estudiante', 'Ana Ruiz',
        'ana@unicauca.edu.co', 'F', 'CC', 33,
      ]);
    });

    //AL-02 (corregido el 2026-11-19): la llamada a la conexion esta en el try
    test('$capa - $tipo - Listar alumnos de grupo - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      final conexion = ConexionalumnosFalsa()..lanzar = TypeError();
      final repositorio = Alumnosrepositorio(cliente: conexion);

      final respuesta = await repositorio.listarAlumnosGrupo('Deportes', 'Iniciacion', 2026, 1);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
