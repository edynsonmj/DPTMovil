import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de atenciones sobre el transporte falso (fase 3 del
//diagnostico): url armada, codigos y conversion a modelos, sin backend.
//Lo esperado sale del contrato observado en test/contratos/atenciones
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

  //modelos armados campo por campo, sin pasar por fromJson: asi este caso
  //prueba solo el envio. Son los de listar_200 con Luis (indice 1) marcado
  List<Atencionmodelo> modelosMarcados() {
    final lista =
        (leerContrato('atenciones', 'listar_200') as List).map((json) {
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
            idClase: 210,
            estaAtendido: json['asistio'],
          );
        }).toList();
    lista[1].estaAtendido = true;
    return lista;
  }

  group('Atenciones (conexion remota con transporte falso):', () {
    test('$capa - $tipo - Listar atenciones - pide la clase solo por su codigo', () async {
      adaptador.responder('GET', '/asistenciasClase', 200, []);

      await obtener();

      final peticion = adaptador.peticionesA('GET', '/asistenciasClase').single;
      expect(peticion.uri.queryParameters, {'idClase': '210'});
    });

    test('$capa - $tipo - Listar atenciones - 200 lista convierte a modelos', () async {
      adaptador.responder(
        'GET',
        '/asistenciasClase',
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
        '/asistenciasClase',
        200,
        leerContrato('atenciones', 'listar_vacia'),
      );

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isEmpty);
    });

    test('$capa - $tipo - Listar atenciones - 200 sin lista responde 406', () async {
      //mismo trato que /alumnosGrupo: 200 con un objeto en vez de lista
      adaptador.responder('GET', '/asistenciasClase', 200, {
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
          '/asistenciasClase',
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
        '/asistenciasClase',
        DioExceptionType.connectionError,
      );

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 503);
      expect(respuesta.error?.mensaje, 'No hay conexion a internet');
    });

    test('$capa - $tipo - Registrar atenciones - envia el cuerpo del contrato', () async {
      adaptador.responder(
        'POST',
        '/asistenciasClase',
        200,
        leerContrato('atenciones', 'registrar_200'),
      );

      final respuesta = await conexion.registrarAtencionesClase(
        modelosMarcados(),
        210,
      );

      expect(respuesta.codigoHttp, 200);
      final enviada = adaptador.peticionesA('POST', '/asistenciasClase').single;
      expect(enviada.uri.queryParameters, {'idClase': '210'});
      expect(enviada.cuerpo, leerContrato('atenciones', 'registrar_peticion'));
    });

    test('$capa - $tipo - Registrar atenciones - 400, 404, 424 y 500 llegan con su codigo', () async {
      //424: algun alumno no pertenece al grupo de la clase
      for (final codigo in [400, 404, 424, 500]) {
        adaptador.responder('POST', '/asistenciasClase', codigo, 'rechazado $codigo');

        final respuesta = await conexion.registrarAtencionesClase(
          modelosMarcados(),
          210,
        );

        expect(respuesta.codigoHttp, codigo, reason: 'codigo $codigo');
        expect(respuesta.error?.mensaje, contains('rechazado $codigo'));
        expect(respuesta.error?.metodo, 'POST');
      }
    });

    test('$capa - $tipo - Registrar atenciones - sin red responde 503', () async {
      adaptador.fallar('POST', '/asistenciasClase', DioExceptionType.connectionError);

      final respuesta = await conexion.registrarAtencionesClase(
        modelosMarcados(),
        210,
      );

      expect(respuesta.codigoHttp, 503);
    });
  });
}
