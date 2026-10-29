import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de atenciones sobre el transporte falso (fase 3 del
//diagnostico): url armada, codigos y conversion a modelos, sin backend.
//El backend aun no tiene estos endpoints; lo esperado sale del contrato
//propuesto en test/contratos/atenciones
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late Conexionatencionesremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionatencionesremoto(crearDioFalso(adaptador));
  });

  Future obtener() =>
      conexion.obtenerAtencionesClase('Deportes', 'Iniciacion', 2026, 1, 210);

  //modelos armados campo por campo desde el json, sin pasar por fromJson:
  //asi este caso prueba solo el envio. La ida y vuelta por fromJson es otra
  //hipotesis (AS-05) y va en test/diagnostico
  List<Atencionmodelo> modelosCompletos(String nombre) =>
      (leerContrato('atenciones', nombre) as List).map((json) {
        final alumno = json['alumno'];
        return Atencionmodelo(
          alumno: Alumnomodelo(
            eliminadoestado: alumno['eliminadoestado'],
            id: alumno['id'],
            codigo: alumno['codigo'],
            tipo: alumno['tipo'],
            nombre: alumno['nombre'],
            correo: alumno['correo'],
            sexo: alumno['sexo'],
            tipoid: alumno['tipoid'],
            imagen: alumno['imagen'],
          ),
          idClase: json['idClase'],
          estaAtendido: json['estaAtendido'],
        );
      }).toList();

  group('Atenciones (conexion remota con transporte falso):', () {
    test('$capa - $tipo - Listar atenciones - arma la uri con los datos de la clase', () async {
      adaptador.responder('GET', '/atencionesporclase', 200, []);

      await obtener();

      final peticion = adaptador.peticionesA('GET', '/atencionesporclase').single;
      expect(peticion.uri.queryParameters, {
        'categoria': 'Deportes',
        'curso': 'Iniciacion',
        'anio': '2026',
        'iterable': '1',
        'claseid': '210',
      });
    });

    test('$capa - $tipo - Listar atenciones - 200 lista convierte a modelos', () async {
      adaptador.responder(
        'GET',
        '/atencionesporclase',
        200,
        leerContrato('atenciones', 'listar_200'),
      );

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.error, isNull);
      expect(respuesta.datos, isA<List<Atencionmodelo>>());
      final lista = respuesta.datos as List<Atencionmodelo>;
      expect(lista.map((a) => a.alumno.nombre), [
        'Ana Gomez',
        'Luis Perez',
        'Marta Ruiz',
      ]);
      expect(lista.map((a) => a.estaAtendido), [false, false, true]);
      expect(lista.every((a) => a.idClase == 210), isTrue);
    });

    test('$capa - $tipo - Listar atenciones - 200 lista vacia no es error', () async {
      adaptador.responder(
        'GET',
        '/atencionesporclase',
        200,
        leerContrato('atenciones', 'listar_vacia'),
      );

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isEmpty);
    });

    test('$capa - $tipo - Listar atenciones - 200 sin lista responde 406', () async {
      //mismo trato que /alumnosGrupo: 200 con un objeto en vez de lista
      adaptador.responder('GET', '/atencionesporclase', 200, {
        'codigo': 'GC-0002',
      });

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 406);
      expect(respuesta.error?.mensaje, 'se esperaba una lista');
    });

    test('$capa - $tipo - Listar atenciones - 404 y 500 llegan con su codigo', () async {
      for (final codigo in [404, 500]) {
        adaptador.responder(
          'GET',
          '/atencionesporclase',
          codigo,
          'detalle del backend $codigo',
        );

        final respuesta = await obtener();

        expect(respuesta.codigoHttp, codigo, reason: 'codigo $codigo');
        expect(respuesta.error?.codigoHttp, codigo);
        expect(respuesta.error?.mensaje, contains('detalle del backend $codigo'));
        expect(respuesta.error?.metodo, 'GET');
      }
    });

    test('$capa - $tipo - Listar atenciones - sin red responde 503', () async {
      adaptador.fallar(
        'GET',
        '/atencionesporclase',
        DioExceptionType.connectionError,
      );

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 503);
      expect(respuesta.error?.mensaje, 'No hay conexion a internet');
    });

    test('$capa - $tipo - Registrar atenciones - envia el cuerpo del contrato', () async {
      adaptador.responder('POST', '/atenciones', 200);

      final respuesta = await conexion.registrarAtencionesClase(
        modelosCompletos('registrar_peticion'),
        210,
      );

      expect(respuesta.codigoHttp, 200);
      final enviada = adaptador.peticionesA('POST', '/atenciones').single;
      expect(enviada.uri.queryParameters, {'idclase': '210'});
      expect(enviada.cuerpo, leerContrato('atenciones', 'registrar_peticion'));
    });

    test('$capa - $tipo - Registrar atenciones - 400 y 500 llegan con su codigo', () async {
      for (final codigo in [400, 500]) {
        adaptador.responder('POST', '/atenciones', codigo, 'rechazado $codigo');

        final respuesta = await conexion.registrarAtencionesClase(
          modelosCompletos('registrar_peticion'),
          210,
        );

        expect(respuesta.codigoHttp, codigo, reason: 'codigo $codigo');
        expect(respuesta.error?.mensaje, contains('rechazado $codigo'));
        expect(respuesta.error?.metodo, 'POST');
      }
    });

    test('$capa - $tipo - Registrar atenciones - sin red responde 503', () async {
      adaptador.fallar('POST', '/atenciones', DioExceptionType.connectionError);

      final respuesta = await conexion.registrarAtencionesClase(
        modelosCompletos('registrar_peticion'),
        210,
      );

      expect(respuesta.codigoHttp, 503);
    });
  });
}
