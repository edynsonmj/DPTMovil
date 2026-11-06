import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexioninscripcionFalsa.dart';

//el repositorio ya recibe su conexion por constructor, asi que se prueba
//con el doble y sin backend. Su constructor no cambia en la fase 6
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexioninscripcionFalsa conexion;
  late Inscripcionrepositorio repositorio;

  Inscripcionentidad inscripcion() => Inscripcionentidad(
    alumnoId: 'alu1',
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
  );

  //un doble nuevo por caso: ningun test hereda respuestas de otro
  setUp(() {
    conexion = ConexioninscripcionFalsa();
    repositorio = Inscripcionrepositorio(conexion: conexion);
  });

  group('Inscripciones (repositorio con doble):', () {
    test('$capa - $tipo - Agregar inscripcion - envia el modelo armado', () async {
      conexion.respuestaAgregar = RespuestaModelo(codigoHttp: 201);

      final respuesta = await repositorio.agregarInscripcion(inscripcion());

      expect(conexion.llamadasAgregar, 1);
      final enviada = conexion.ultimaAgregada!;
      expect(enviada.alumnoId, 'alu1');
      expect(enviada.categoria, 'Deportes');
      expect(enviada.curso, 'Iniciacion');
      expect(enviada.anio, 2026);
      expect(enviada.iterable, 1);
      expect(respuesta.codigoHttp, 201);
    });

    test('$capa - $tipo - Validar inscripcion - el bool llega sin cambios', () async {
      final inscrito = RespuestaModelo(codigoHttp: 200, datos: true);
      conexion.respuestaValidar = inscrito;

      final respuesta = await repositorio.validarInscripcion(inscripcion());

      expect(conexion.ultimaValidada?.alumnoId, 'alu1');
      expect(respuesta, same(inscrito));
      expect(respuesta.datos, isTrue);
    });

    test('$capa - $tipo - Eliminar inscripcion - envia el modelo armado', () async {
      conexion.respuestaEliminar = RespuestaModelo(codigoHttp: 200);

      final respuesta = await repositorio.eliminarInscripcion(inscripcion());

      expect(conexion.llamadasEliminar, 1);
      expect(conexion.ultimaEliminada?.alumnoId, 'alu1');
      expect(conexion.ultimaEliminada?.iterable, 1);
      expect(respuesta.codigoHttp, 200);
    });
  });

  //diagnostico del modulo 4 (plan-diagnostico-inscripciones.md, 4.1): lo que
  //el repositorio debe cumplir cuando la conexion falla o hay fechas
  group('Inscripciones (repositorio con doble, errores y fechas):', () {
    RespuestaModelo error(int codigo) => RespuestaModelo(
      codigoHttp: codigo,
      error: ErrorModelo(
        codigoHttp: codigo,
        mensaje: 'fallo $codigo',
        url: '/inscripcion',
        metodo: 'POST',
      ),
    );

    test('$capa - $tipo - Agregar inscripcion - un error de la conexion pasa sin cambios', () async {
      final fallo = error(409);
      conexion.respuestaAgregar = fallo;

      expect(await repositorio.agregarInscripcion(inscripcion()), same(fallo));
    });

    test('$capa - $tipo - Validar inscripcion - un error de la conexion pasa sin cambios', () async {
      final fallo = error(503);
      conexion.respuestaValidar = fallo;

      expect(await repositorio.validarInscripcion(inscripcion()), same(fallo));
    });

    test('$capa - $tipo - Eliminar inscripcion - un error de la conexion pasa sin cambios', () async {
      final fallo = error(500);
      conexion.respuestaEliminar = fallo;

      expect(await repositorio.eliminarInscripcion(inscripcion()), same(fallo));
    });

    test('$capa - $tipo - Agregar y eliminar - las fechas de la entidad llegan al modelo', () async {
      final alta = DateTime(2026, 10, 29, 8, 30);
      final baja = DateTime(2026, 11, 2, 17);
      final conFechas = inscripcion()
        ..fechaInscripcion = alta
        ..fechaDesvinculacion = baja;

      await repositorio.agregarInscripcion(conFechas);
      await repositorio.eliminarInscripcion(conFechas);

      expect(conexion.ultimaAgregada?.fechaInscripcion, alta);
      expect(conexion.ultimaEliminada?.fechaInscripcion, alta);
      expect(conexion.ultimaEliminada?.fechaDesvinculacion, baja);
    });

    //nacieron como diagnostico de IN-12: los errores no se lanzan entre capas
    test('$capa - $tipo - Agregar inscripcion - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzarAlAgregar = TypeError();

      final respuesta = await repositorio.agregarInscripcion(inscripcion());

      expect(respuesta.codigoHttp, isNot(201));
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Eliminar inscripcion - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzarAlEliminar = TypeError();

      final respuesta = await repositorio.eliminarInscripcion(inscripcion());

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
