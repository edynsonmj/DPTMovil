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

  group('Grupos, periodo de inscripcion (repositorio con doble):', () {
    final grupo = Grupoentidad(
      categoria: 'Deportes',
      curso: 'Iniciacion',
      anio: 2026,
      iterable: 2,
      cupos: 20,
      fechaCreacion: '2026-10-21',
    );
    GrupoModelo conPeriodo(String? apertura, String? cierre) => GrupoModelo(
      cat_titulo: 'Deportes',
      cur_nombre: 'Iniciacion',
      anio: 2026,
      iterable: 2,
      cupos: 20,
      fechaCreacion: '2026-10-21',
      fechaInscripcionApertura: apertura,
      fechaInscripcionCierre: cierre,
    );

    test('$capa - $tipo - Grupos no eliminados - 200 convierte a entidades con su periodo', () async {
      conexion.respuestaNoEliminados = RespuestaModelo(
        codigoHttp: 200,
        datos: [conPeriodo('2026-10-29', '2026-12-31'), conPeriodo(null, null)],
      );

      final respuesta = await repositorio.listarGruposNoEliminados();

      expect(conexion.llamadasNoEliminados, 1);
      expect(respuesta.datos, isA<List<Grupoentidad>>());
      final lista = respuesta.datos as List<Grupoentidad>;
      expect(lista[0].fechaInscripcionApertura, '2026-10-29');
      expect(lista[0].fechaInscripcionCierre, '2026-12-31');
      expect(lista[1].fechaInscripcionApertura, isNull);
    });

    test('$capa - $tipo - Abrir inscripciones - pasa la llave y las fechas como yyyy-MM-dd', () async {
      conexion.respuestaAbrir = RespuestaModelo(
        codigoHttp: 200,
        datos: conPeriodo('2026-12-01', '2026-12-20'),
      );

      final respuesta = await repositorio.abrirInscripciones(
        grupo,
        apertura: DateTime(2026, 12, 1),
        cierre: DateTime(2026, 12, 20),
      );

      expect(conexion.ultimoGrupoAbierto, 'Deportes/Iniciacion/2026/2');
      expect(conexion.ultimoPeriodo?.apertura, '2026-12-01');
      expect(conexion.ultimoPeriodo?.cierre, '2026-12-20');
      //el grupo actualizado sale como entidad
      expect(respuesta.datos, isA<Grupoentidad>());
      expect(
        (respuesta.datos as Grupoentidad).fechaInscripcionApertura,
        '2026-12-01',
      );
    });

    test('$capa - $tipo - Abrir inscripciones - sin fechas no las inventa', () async {
      conexion.respuestaAbrir = RespuestaModelo(
        codigoHttp: 200,
        datos: conPeriodo('2026-10-29', null),
      );

      await repositorio.abrirInscripciones(grupo);

      expect(conexion.ultimoPeriodo?.apertura, isNull);
      expect(conexion.ultimoPeriodo?.cierre, isNull);
    });

    test('$capa - $tipo - Cerrar inscripciones - devuelve el grupo como entidad', () async {
      conexion.respuestaCerrar = RespuestaModelo(
        codigoHttp: 200,
        datos: conPeriodo('2026-10-28', '2026-10-28'),
      );

      final respuesta = await repositorio.cerrarInscripciones(grupo);

      expect(conexion.ultimoGrupoCerrado, 'Deportes/Iniciacion/2026/2');
      expect(
        (respuesta.datos as Grupoentidad).fechaInscripcionCierre,
        '2026-10-28',
      );
    });

    test('$capa - $tipo - Periodo de inscripcion - los errores pasan sin cambios', () async {
      final error400 = RespuestaModelo(codigoHttp: 400);
      final error404 = RespuestaModelo(codigoHttp: 404);
      final error503 = RespuestaModelo(codigoHttp: 503);
      conexion.respuestaAbrir = error400;
      conexion.respuestaCerrar = error404;
      conexion.respuestaNoEliminados = error503;

      expect(await repositorio.abrirInscripciones(grupo), same(error400));
      expect(await repositorio.cerrarInscripciones(grupo), same(error404));
      expect(await repositorio.listarGruposNoEliminados(), same(error503));
    });
  });
}
