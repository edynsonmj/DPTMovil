import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAtencionesRemoto.dart';
import 'package:dpt_movil/data/models/alumnoModelo.dart';
import 'package:dpt_movil/data/models/atencionModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de atenciones sobre el transporte falso: alumnos del grupo
//+ marcas de la clase al leer, PUT /clase/{codigo}/asistencia al registrar.
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

  void programarCarga({Object? marcas}) {
    adaptador.responder('GET', '/alumnosGrupo', 200, leerContrato('atenciones', 'alumnosGrupo_200'));
    adaptador.responder(
      'GET',
      '/atencionesporclase',
      200,
      marcas ?? leerContrato('atenciones', 'atencionesporclase_200'),
    );
  }

  group('Atenciones (conexion remota con transporte falso):', () {
    test('$capa - $tipo - Listar atenciones - pide alumnos del grupo y marcas de la clase', () async {
      programarCarga();

      await obtener();

      final alumnos = adaptador.peticionesA('GET', '/alumnosGrupo').single;
      expect(alumnos.uri.queryParameters, {
        'categoria': 'Deportes',
        'curso': 'Iniciacion',
        'anio': '2026',
        'iterable': '1',
      });
      final marcas = adaptador.peticionesA('GET', '/atencionesporclase').single;
      expect(marcas.uri.queryParameters, {'claseid': '210'});
    });

    test('$capa - $tipo - Listar atenciones - une alumnos con sus marcas', () async {
      programarCarga();

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.error, isNull);
      final lista = respuesta.datos as List<Atencionmodelo>;
      expect(lista.map((a) => a.alumno.nombre), ['Ana Gomez', 'Luis Perez', 'Marta Ruiz']);
      expect(lista.map((a) => a.estaAtendido), [false, false, true]);
      expect(lista.every((a) => a.idClase == 210), isTrue);
    });

    test('$capa - $tipo - Listar atenciones - clase sin marcas (GC-0002) deja a todos ausentes', () async {
      programarCarga(marcas: leerContrato('atenciones', 'atencionesporclase_vacia'));

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 200);
      expect((respuesta.datos as List<Atencionmodelo>).map((a) => a.estaAtendido), [false, false, false]);
    });

    test('$capa - $tipo - Listar atenciones - grupo sin alumnos (GC-0002) es lista vacia', () async {
      adaptador.responder('GET', '/alumnosGrupo', 200, leerContrato('atenciones', 'atencionesporclase_vacia'));

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 200);
      expect(respuesta.datos, isEmpty);
      expect(adaptador.peticionesA('GET', '/atencionesporclase'), isEmpty);
    });

    test('$capa - $tipo - Listar atenciones - 404 y 500 llegan con su codigo', () async {
      for (final codigo in [404, 500]) {
        adaptador.responder('GET', '/alumnosGrupo', codigo, 'detalle del backend $codigo');

        final respuesta = await obtener();

        expect(respuesta.codigoHttp, codigo, reason: 'codigo $codigo');
        expect(respuesta.error?.mensaje, contains('detalle del backend $codigo'));
        expect(respuesta.error?.metodo, 'GET');
      }
    });

    test('$capa - $tipo - Listar atenciones - falla la segunda consulta: llega su codigo', () async {
      adaptador.responder('GET', '/alumnosGrupo', 200, leerContrato('atenciones', 'alumnosGrupo_200'));
      adaptador.responder('GET', '/atencionesporclase', 404, 'sin clase');

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 404);
    });

    test('$capa - $tipo - Listar atenciones - sin red responde 503', () async {
      adaptador.fallar('GET', '/alumnosGrupo', DioExceptionType.connectionError);

      final respuesta = await obtener();

      expect(respuesta.codigoHttp, 503);
      expect(respuesta.error?.mensaje, 'No hay conexion a internet');
    });

    test('$capa - $tipo - Registrar atenciones - PUT con el cuerpo del contrato', () async {
      adaptador.responder('PUT', '/clase/210/asistencia', 200, leerContrato('atenciones', 'confirmar_200'));

      final respuesta = await conexion.registrarAtencionesClase(modelosMarcados(), 210);

      expect(respuesta.codigoHttp, 200);
      final enviada = adaptador.peticionesA('PUT', '/clase/210/asistencia').single;
      expect(enviada.uri.queryParameters, isEmpty);
      expect(enviada.cuerpo, leerContrato('atenciones', 'confirmar_peticion'));
    });

    test('$capa - $tipo - Registrar atenciones - sin ningun presente confirma que todos faltaron', () async {
      adaptador.responder('PUT', '/clase/210/asistencia', 200, leerContrato('atenciones', 'confirmar_200'));
      final ausentes = modelosMarcados()..forEach((a) => a.estaAtendido = false);

      await conexion.registrarAtencionesClase(ausentes, 210);

      final enviada = adaptador.peticionesA('PUT', '/clase/210/asistencia').single;
      expect(enviada.cuerpo['confirmaTodosAusentes'], isTrue);
      expect((enviada.cuerpo['asistencias'] as List).every((a) => a['estaAtendido'] == false), isTrue);
    });

    test('$capa - $tipo - Registrar atenciones - 400, 404, 422 y 500 llegan con su codigo', () async {
      for (final codigo in [400, 404, 422, 500]) {
        adaptador.responder('PUT', '/clase/210/asistencia', codigo, 'rechazado $codigo');

        final respuesta = await conexion.registrarAtencionesClase(modelosMarcados(), 210);

        expect(respuesta.codigoHttp, codigo, reason: 'codigo $codigo');
        expect(respuesta.error?.mensaje, contains('rechazado $codigo'));
        expect(respuesta.error?.metodo, 'PUT');
      }
    });

    test('$capa - $tipo - Registrar atenciones - sin red responde 503', () async {
      adaptador.fallar('PUT', '/clase/210/asistencia', DioExceptionType.connectionError);

      final respuesta = await conexion.registrarAtencionesClase(modelosMarcados(), 210);

      expect(respuesta.codigoHttp, 503);
    });
  });
}
