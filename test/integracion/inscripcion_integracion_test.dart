import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionInscripcionRemoto.dart';
import 'package:dpt_movil/data/repositories/inscripcionRepositorio.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/entities/inscripcionEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioInscripcion.dart';
import 'package:dpt_movil/presentation/viewmodels/inscripcionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../dobles/adaptadorHttpFalso.dart';

//integracion local del modulo 4 (plan-diagnostico-inscripciones.md, 4.2): el
//vm de la pantalla del alumno con su cadena real hasta Conexioninscripcionremoto
//y el transporte falso debajo. Cubre lo que el backend real no deja provocar:
//sin red y fallos a mitad del flujo
void main() {
  const String capa = "integracion";
  const String tipo = "local";

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

  group('Inscripcion del alumno (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Inscribir - 201 envia los datos del grupo y revalida', () async {
      adaptador.responder('POST', '/inscripcion', 201, {
        'alumnoId': '104619011001',
        'categoria': grupo.categoria,
        'curso': grupo.curso,
        'anio': 2026,
        'iterable': 2,
        'eliminado': 0,
      });
      adaptador.responder('GET', '/validarInscripcion', 200, true);

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Exito>(), reason: '$resultado');
      expect(
        adaptador.peticiones.map((p) => '${p.metodo} ${p.ruta}'),
        ['POST /inscripcion', 'GET /validarInscripcion'],
      );
      final cuerpo =
          adaptador.peticionesA('POST', '/inscripcion').single.cuerpo as Map;
      expect(cuerpo['alumnoId'], '104619011001');
      expect(cuerpo['categoria'], 'Educación física');
      expect(cuerpo['curso'], 'Natación nivel 1');
      expect(cuerpo['anio'], 2026);
      expect(cuerpo['iterable'], 2);
      expect(vm.estadoDe(grupo).datos, isTrue);
      expect(vm.procesando(grupo), isFalse);
    });

    test('$capa - $tipo - Desvincular - 200 envia un PUT con la inscripcion y revalida', () async {
      adaptador.responder('PUT', '/desvincularInscripcion', 200, {
        'alumnoId': '104619011001',
        'eliminado': 1,
      });
      adaptador.responder('GET', '/validarInscripcion', 200, false);

      final resultado = await vm.desvincularInscripcion(inscripcion());

      expect(resultado, isA<Exito>(), reason: '$resultado');
      final cuerpo =
          adaptador.peticionesA('PUT', '/desvincularInscripcion').single.cuerpo
              as Map;
      expect(cuerpo['alumnoId'], '104619011001');
      expect(cuerpo['iterable'], 2);
      expect(vm.estadoDe(grupo).datos, isFalse);
    });

    //nacio como diagnostico de IN-08: la conexion etiquetaba el error del PUT
    //como POST
    test('$capa - $tipo - Desvincular - un error lleva como origen el metodo PUT que se envio', () async {
      adaptador.responder('PUT', '/desvincularInscripcion', 500, 'error interno');

      final resultado = await vm.desvincularInscripcion(inscripcion());

      expect(resultado, isA<Fallo>());
      //la peticion que salio fue un PUT
      expect(adaptador.peticionesA('PUT', '/desvincularInscripcion'), hasLength(1));
      expect((resultado as Fallo).origen, startsWith('PUT '));
    });

    //nacio como diagnostico de IN-09: validarInscripcion convertia el error
    //en "no inscrito"
    test('$capa - $tipo - Cargar estados - sin red el grupo queda con error, no como "no inscrito"', () async {
      adaptador.fallar(
        'GET',
        '/validarInscripcion',
        DioExceptionType.connectionError,
      );

      await vm.cargarEstados('104619011001', [grupo]);

      final estado = vm.estadoDe(grupo);
      expect(estado.cargando, isFalse);
      //la pantalla pinta "Matricular" con datos == false: sin un error, el
      //alumno no puede saber que su inscripcion no se pudo consultar
      expect(estado.error, isNotNull, reason: 'datos: ${estado.datos}');
    });

    //nacio como diagnostico de IN-10: misma causa que IN-09, despues de un 201
    test('$capa - $tipo - Inscribir - si la revalidacion falla tras un 201, el grupo no queda como "no inscrito"', () async {
      adaptador.responder('POST', '/inscripcion', 201, {'alumnoId': '104619011001'});
      adaptador.fallar(
        'GET',
        '/validarInscripcion',
        DioExceptionType.connectionError,
      );

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Exito>());
      final estado = vm.estadoDe(grupo);
      //el usuario ve "Te has inscrito al grupo" y debajo el boton "Matricular"
      expect(
        estado.datos == true || estado.error != null,
        isTrue,
        reason: 'datos: ${estado.datos}, error: ${estado.error}',
      );
    });

    test('$capa - $tipo - Inscribir - 409 es Fallo con el mensaje del backend y no revalida', () async {
      adaptador.responder('POST', '/inscripcion', 409, {
        'codigoError': 'GC-0012',
        'mensaje': 'El grupo no tiene inscripciones abiertas',
      });

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Fallo>());
      final fallo = resultado as Fallo;
      expect(fallo.codigo, 409);
      expect(fallo.mensaje, contains('GC-0012'));
      expect(adaptador.peticionesA('GET', '/validarInscripcion'), isEmpty);
      expect(vm.procesando(grupo), isFalse);
    });

    test('$capa - $tipo - Inscribir - sin red es Fallo 503 y el boton se libera', () async {
      adaptador.fallar('POST', '/inscripcion', DioExceptionType.connectionError);

      final resultado = await vm.agregarIncripcion(inscripcion());

      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 503);
      expect(vm.procesando(grupo), isFalse);
    });
    //los casos rojos de este mismo montaje (IN-08 a IN-11) estan en
    //test/diagnostico/inscripciones/integracion_diagnostico_test.dart
  });
}
