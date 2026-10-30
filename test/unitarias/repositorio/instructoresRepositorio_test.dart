import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/instructorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/instructoresRepositorio.dart';
import 'package:dpt_movil/domain/entities/instructorEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexioninstructoresFalsa.dart';

//diagnostico del modulo 9b (plan-diagnostico-instructores-facultades.md,
//U-Repo): el caso 200 basico esta en horarioAlumnoInstructorRepositorio_test
//.dart; aqui van la lista vacia, los errores y los campos del modelo
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexioninstructoresFalsa conexion;
  late Instructoresrepositorio repositorio;

  setUp(() {
    conexion = ConexioninstructoresFalsa();
    repositorio = Instructoresrepositorio(conexion: conexion);
  });

  group('Instructores (repositorio con doble, listas vacias y errores):', () {
    test('$capa - $tipo - Listar instructores - 200 [] es una lista vacia de entidades', () async {
      final respuesta = await repositorio.listarInstructores();

      expect(conexion.llamadasInstructores, 1);
      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Instructorentidad>>());
      expect(respuesta.datos, isEmpty);
    });

    test('$capa - $tipo - Listar instructores - un error y el 406 pasan sin cambios', () async {
      final e503 = RespuestaModelo(
        codigoHttp: 503,
        error: ErrorModelo(codigoHttp: 503, mensaje: 'sin red', url: '/instructores', metodo: 'GET'),
      );
      conexion.respuestaInstructores = e503;
      expect(await repositorio.listarInstructores(), same(e503));

      final e406 = RespuestaModelo(codigoHttp: 406);
      conexion.respuestaInstructores = e406;
      expect(await repositorio.listarInstructores(), same(e406));
    });

    test('$capa - $tipo - Listar instructores - la entidad conserva los 4 campos del modelo', () async {
      conexion.respuestaInstructores = RespuestaModelo(
        codigoHttp: 200,
        datos: [
          Instructormodelo(id: '2', nombre: 'Luis Paz', correo: 'luis@unicauca.edu.co', sexo: 'M'),
        ],
      );

      final i = ((await repositorio.listarInstructores()).datos as List<Instructorentidad>).single;

      expect([i.id, i.nombre, i.correo, i.sexo], ['2', 'Luis Paz', 'luis@unicauca.edu.co', 'M']);
    });
  });
}
