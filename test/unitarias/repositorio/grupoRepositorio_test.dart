import 'package:dpt_movil/data/models/grupoModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/grupoRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexiongruposFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 4: estos
//casos deben pasar igual antes y despues de migrar grupos
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexiongruposFalsa conexion;
  late Gruporepositorio repositorio;

  GrupoModelo modelo(int iterable, {int? imagen}) => GrupoModelo(
    cat_titulo: 'Deportes',
    cur_nombre: 'Iniciacion',
    anio: 2026,
    iterable: iterable,
    cupos: 20,
    fechaCreacion: '2026-10-21',
    imagen: imagen,
    idInstructor: 'ins1',
  );

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexiongruposFalsa();
    repositorio = Gruporepositorio(conexion: conexion);
  });

  group('Grupos (repositorio con doble):', () {
    test('$capa - $tipo - Listar grupos de - 200 convierte a entidades', () async {
      conexion.respuestaGruposDe = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo(1, imagen: 7), modelo(2)],
      );

      final respuesta = await repositorio.listarGruposDe('Deportes', 'Iniciacion');

      expect(conexion.ultimaCategoria, 'Deportes');
      expect(conexion.ultimoCurso, 'Iniciacion');
      expect(respuesta.codigoHttp, 200);
      //ningun modelo sale de la capa de datos
      expect(respuesta.datos, isA<List<Grupoentidad>>());
      final lista = respuesta.datos as List<Grupoentidad>;
      expect(lista.map((g) => g.iterable), [1, 2]);
      expect(lista[0].categoria, 'Deportes');
      expect(lista[0].curso, 'Iniciacion');
      expect(lista[0].imagen, 7);
      expect(lista[0].idInstructor, 'ins1');
      expect(lista[1].imagen, isNull);
    });

    test('$capa - $tipo - Listar grupos de - 406 pasa sin cambios', () async {
      //la conexion responde 406 cuando el backend manda 200 sin lista
      final sinLista = RespuestaModelo(codigoHttp: 406);
      conexion.respuestaGruposDe = sinLista;

      final respuesta = await repositorio.listarGruposDe('Deportes', 'Iniciacion');

      expect(respuesta, same(sinLista));
    });

    test('$capa - $tipo - Insertar grupo - envia el modelo armado', () async {
      conexion.respuestaInsertar = RespuestaModelo(codigoHttp: 201);

      final respuesta = await repositorio.insertarGrupo(
        Grupoentidad(
          categoria: 'Deportes',
          curso: 'Iniciacion',
          anio: 2026,
          iterable: 0,
          imagen: 7,
          idInstructor: 'ins1',
          cupos: 20,
          fechaCreacion: '2026-10-21',
        ),
      );

      expect(conexion.llamadasInsertar, 1);
      final enviado = conexion.ultimoInsertado!;
      expect(enviado.cat_titulo, 'Deportes');
      expect(enviado.cur_nombre, 'Iniciacion');
      expect(enviado.anio, 2026);
      expect(enviado.imagen, 7);
      expect(enviado.idInstructor, 'ins1');
      expect(enviado.cupos, 20);
      expect(enviado.fechaCreacion, '2026-10-21');
      expect(respuesta.codigoHttp, 201);
    });
  });
}
