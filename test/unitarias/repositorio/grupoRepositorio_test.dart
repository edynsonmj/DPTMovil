import 'package:dpt_movil/data/models/errorModelo.dart';
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

    test('$capa - $tipo - Abrir inscripciones - sin apertura no la inventa', () async {
      conexion.respuestaAbrir = RespuestaModelo(
        codigoHttp: 200,
        datos: conPeriodo('2026-10-29', '2026-12-20'),
      );

      await repositorio.abrirInscripciones(grupo, cierre: DateTime(2026, 12, 20));

      expect(conexion.ultimoPeriodo?.apertura, isNull);
      expect(conexion.ultimoPeriodo?.cierre, '2026-12-20');
      expect(conexion.llamadasReabrir, 0);
    });

    test('$capa - $tipo - Abrir inscripciones - un grupo cerrado a mano se reabre despues del periodo', () async {
      conexion.respuestaAbrir = RespuestaModelo(
        codigoHttp: 200,
        datos: conPeriodo('2026-10-29', '2026-12-20'),
      );
      conexion.respuestaReabrir = RespuestaModelo(
        codigoHttp: 200,
        datos: conPeriodo('2026-10-29', '2026-12-20'),
      );
      grupo.inscripcionesCerradasManual = true;

      final respuesta = await repositorio.abrirInscripciones(grupo, cierre: DateTime(2026, 12, 20));
      grupo.inscripcionesCerradasManual = false;

      expect(conexion.llamadasAbrir, 1);
      expect(conexion.llamadasReabrir, 1);
      expect(respuesta.datos, isA<Grupoentidad>());
    });

    test('$capa - $tipo - Abrir inscripciones - si el periodo falla no intenta reabrir', () async {
      final error = RespuestaModelo(codigoHttp: 422);
      conexion.respuestaAbrir = error;
      grupo.inscripcionesCerradasManual = true;

      final respuesta = await repositorio.abrirInscripciones(grupo, cierre: DateTime(2026, 12, 20));
      grupo.inscripcionesCerradasManual = false;

      expect(respuesta, same(error));
      expect(conexion.llamadasReabrir, 0);
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

      expect(
        await repositorio.abrirInscripciones(grupo, cierre: DateTime(2026, 12, 20)),
        same(error400),
      );
      expect(await repositorio.cerrarInscripciones(grupo), same(error404));
      expect(await repositorio.listarGruposNoEliminados(), same(error503));
    });
  });

  //diagnostico del modulo 3 (plan-diagnostico-grupos.md, U-Repo)
  group('Grupos (repositorio con doble, listas y errores):', () {
    RespuestaModelo error(int codigo) => RespuestaModelo(
      codigoHttp: codigo,
      error: ErrorModelo(
        codigoHttp: codigo,
        mensaje: 'fallo $codigo',
        url: '/grupos',
        metodo: 'GET',
      ),
    );

    test('$capa - $tipo - Listar grupos del instructor - 200 convierte a entidades y pasa el id', () async {
      conexion.respuestaInstructor = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo(1, imagen: 7), modelo(2)],
      );

      final respuesta = await repositorio.listarGruposInstructores('ins1');

      expect(conexion.ultimoInstructor, 'ins1');
      final lista = respuesta.datos as List<Grupoentidad>;
      expect(lista.map((g) => g.iterable), [1, 2]);
      expect(lista.first.imagen, 7);
      expect(lista.first.idInstructor, 'ins1');
      expect(lista.first.cupos, 20);
    });

    test('$capa - $tipo - Listar grupos disponibles - 200 convierte a entidades', () async {
      conexion.respuestaInscripcion = RespuestaModelo(
        codigoHttp: 200,
        datos: [modelo(3)],
      );

      final respuesta = await repositorio.listarGruposDisponiblesInscripcion();

      expect((respuesta.datos as List<Grupoentidad>).single.clave, 'Deportes/Iniciacion/2026/3');
    });

    test('$capa - $tipo - Listar grupos de - 200 [] es una lista vacia de entidades', () async {
      final respuesta = await repositorio.listarGruposDe('Deportes', 'Iniciacion');

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isA<List<Grupoentidad>>());
      expect(respuesta.datos, isEmpty);
    });

    test('$capa - $tipo - Listar grupos del instructor y disponibles - un error pasa sin cambios', () async {
      final e503 = error(503);
      final e500 = error(500);
      conexion.respuestaInstructor = e503;
      conexion.respuestaInscripcion = e500;

      expect(await repositorio.listarGruposInstructores('ins1'), same(e503));
      expect(await repositorio.listarGruposDisponiblesInscripcion(), same(e500));
    });

    test('$capa - $tipo - Insertar grupo - un error pasa sin cambios', () async {
      final e400 = error(400);
      conexion.respuestaInsertar = e400;

      final respuesta = await repositorio.insertarGrupo(
        Grupoentidad(
          categoria: 'Deportes',
          curso: 'Iniciacion',
          anio: 0,
          iterable: 0,
          cupos: 20,
          fechaCreacion: '2026-10-29',
          idInstructor: 'ins1',
        ),
      );

      expect(respuesta, same(e400));
    });

    //antes GR-02 (mitad del repositorio): el modelo perdia la fecha de
    //finalizacion. La otra mitad (toJson no la envia) sigue roja en
    //test/diagnostico/grupos/integracion_diagnostico_test.dart
    test('$capa - $tipo - Insertar grupo - la fecha de finalizacion de la entidad llega al modelo', () async {
      await repositorio.insertarGrupo(
        Grupoentidad(
          categoria: 'Deportes',
          curso: 'Iniciacion',
          anio: 0,
          iterable: 0,
          cupos: 20,
          fechaCreacion: '2026-10-29',
          fechaFinalizacion: '2026-12-15',
          idInstructor: 'ins1',
        ),
      );

      expect(conexion.ultimoInsertado?.fechaFinalizacion, '2026-12-15');
    });
    //el caso rojo (GR-01) esta en
    //test/diagnostico/grupos/repositorio_diagnostico_test.dart
  });
}
