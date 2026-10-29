@Tags(['diagnostico'])
library;

import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/atencionesRepositorio.dart';
import 'package:dpt_movil/domain/entities/claseEntidad.dart';
import 'package:dpt_movil/domain/entities/grupoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioAtencion.dart';
import 'package:dpt_movil/presentation/viewmodels/atencionViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';
import '../../dobles/conexionatencionesFalsa.dart';

//pruebas de diagnostico (fase 4): afirman el comportamiento CORRECTO y se
//espera que salgan rojas mientras el bug exista. Un verde descarta la
//hipotesis. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "conexion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late Conexionatencionesremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionatencionesremoto(crearDioFalso(adaptador));
  });

  //cadena real completa sobre el transporte falso, como la arma la raiz
  Atencionviewmodel vmReal() =>
      Atencionviewmodel(Servicioatencion(Atencionesrepositorio(conexion: conexion)));

  final grupo = Grupoentidad(
    categoria: 'Deportes',
    curso: 'Iniciacion',
    anio: 2026,
    iterable: 1,
    cupos: 20,
    fechaCreacion: '2026-10-23',
  );
  final clase = Claseentidad(
    codigo: 210,
    idGrupoCategoria: 'Deportes',
    idGrupoCurso: 'Iniciacion',
    idGrupoAnio: 2026,
    idGrupoIterable: 1,
    idInstructor: 'ins1',
    eliminado: 0,
  );

  group('Atenciones (diagnostico de la conexion):', () {
    test('$capa - $tipo - Listar atenciones - BUG AS-04 - los nombres con caracteres especiales llegan intactos', () async {
      adaptador.responder('GET', '/atencionesporclase', 200, []);

      final resultado = await sinLanzar(
        () => conexion.obtenerAtencionesClase(
          'Fútbol & Voleibol',
          'Nivel 1 + avanzado',
          2026,
          1,
          210,
        ),
      );

      expect(resultado.lanzado, isNull, reason: 'escapo: ${resultado.lanzado}');
      final peticion = adaptador.peticionesA('GET', '/atencionesporclase').single;
      expect(peticion.uri.queryParameters['categoria'], 'Fútbol & Voleibol');
      expect(peticion.uri.queryParameters['curso'], 'Nivel 1 + avanzado');
      expect(peticion.uri.queryParameters['claseid'], '210');
    });

    test('$capa - $tipo - Cargar y registrar - BUG AS-05 - el alumno se reenvia tal como llego', () async {
      adaptador.responder(
        'GET',
        '/atencionesporclase',
        200,
        leerContrato('atenciones', 'listar_200'),
      );
      adaptador.responder('POST', '/atenciones', 200);
      final vm = vmReal();

      await vm.cargarAtenciones(grupo, clase);
      vm.marcarAsistencia(1, true);
      await vm.registrarAtenciones();

      //registrar_peticion.json = listar_200.json con Luis marcado: si el
      //backend guarda el alumno anidado, cualquier diferencia es un dato
      //borrado (codigo, imagen)
      final enviada = adaptador.peticionesA('POST', '/atenciones').single;
      expect(enviada.cuerpo, leerContrato('atenciones', 'registrar_peticion'));
    });

    test('$capa - $tipo - Cargar y registrar - BUG AS-05 - un alumno retirado no se reenvia como activo', () async {
      final retirado = (leerContrato('atenciones', 'listar_200') as List).first;
      retirado['alumno']['eliminadoestado'] = 1;
      adaptador.responder('GET', '/atencionesporclase', 200, [retirado]);
      adaptador.responder('POST', '/atenciones', 200);
      final vm = vmReal();

      await vm.cargarAtenciones(grupo, clase);
      await vm.registrarAtenciones();

      final enviada = adaptador.peticionesA('POST', '/atenciones').single;
      expect(enviada.cuerpo[0]['alumno']['eliminadoestado'], 1);
    });

    test('$capa - $tipo - Listar atenciones - BUG AS-06 - json incompleto se devuelve como error, sin lanzar', () async {
      final incompleto = (leerContrato('atenciones', 'listar_200') as List).first;
      incompleto['estaAtendido'] = null;
      adaptador.responder('GET', '/atencionesporclase', 200, [incompleto]);

      final resultado = await sinLanzar(
        () => conexion.obtenerAtencionesClase('Deportes', 'Iniciacion', 2026, 1, 210),
      );

      //la regla de la app: los errores se devuelven, no se lanzan
      expect(resultado.lanzado, isNull, reason: 'escapo: ${resultado.lanzado}');
      expect(resultado.respuesta!.codigoHttp, isNot(200));
      expect(resultado.respuesta!.error, isNotNull);
    });

    for (final codigo in [201, 204]) {
      test('$capa - $tipo - Registrar atenciones - BUG AS-07 - $codigo es exito', () async {
        adaptador.responder('POST', '/atenciones', codigo);

        final resultado = await sinLanzar(
          () => conexion.registrarAtencionesClase(
            atencionesDelContrato('listar_200'),
            210,
          ),
        );

        expect(resultado.lanzado, isNull, reason: 'escapo: ${resultado.lanzado}');
        expect(resultado.respuesta!.error, isNull);
        expect(resultado.respuesta!.codigoHttp, inInclusiveRange(200, 299));
      });
    }

    test('$capa - $tipo - Listar atenciones - BUG AS-12 - receiveTimeout responde 408', () async {
      adaptador.fallar(
        'GET',
        '/atencionesporclase',
        DioExceptionType.receiveTimeout,
      );

      final respuesta = await conexion.obtenerAtencionesClase(
        'Deportes',
        'Iniciacion',
        2026,
        1,
        210,
      );

      expect(respuesta.codigoHttp, 408);
    });
  });
}

//ejecuta sin dejar escapar nada: asi la prueba distingue "devolvio un
//error" de "lanzo una excepcion" en lugar de reventar sin explicar
Future<({RespuestaModelo? respuesta, Object? lanzado})> sinLanzar(
  Future<RespuestaModelo> Function() accion,
) async {
  try {
    return (respuesta: await accion(), lanzado: null);
  } catch (e) {
    return (respuesta: null, lanzado: e);
  }
}
