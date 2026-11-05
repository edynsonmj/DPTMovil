import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de autenticacion sobre el transporte falso
//(plan-diagnostico-autenticacion.md). Las respuestas salen de
//test/contratos/autenticacion, documentadas en /v3/api-docs: desde el
//2026-11-05 el backend local responde 401 sin JWT y no se pudieron observar
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late Conexionautenticacionremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionautenticacionremoto(crearDioFalso(adaptador));
  });

  Perfilmodelo perfilDelFormulario() {
    final json = leerContrato('autenticacion', 'registro_peticion');
    return Perfilmodelo(
      id: json['id'],
      nombre: json['nombre'],
      correo: json['correo'],
      tipoId: json['tipoId'],
      sexo: json['sexo'],
      facultad: json['facultad'],
      tipoAlumno: json['tipoAlumno'],
    );
  }

  group('Autenticacion (conexion remota con transporte falso):', () {
    test('$capa - $tipo - Login - 200 devuelve el perfil con su rol y el correo va en la query', () async {
      adaptador.responder('GET', '/login', 200, leerContrato('autenticacion', 'login_200'));

      final respuesta = await conexion.login('ana@unicauca.edu.co');

      final peticion = adaptador.peticionesA('GET', '/login').single;
      expect(peticion.uri.queryParameters, {'email': 'ana@unicauca.edu.co'});
      expect(respuesta.codigoHttp, 200);
      final perfil = respuesta.datos as Perfilmodelo;
      expect([perfil.id, perfil.correo, perfil.role], ['1061000001', 'ana@unicauca.edu.co', 'Coordinador']);
    });

    test('$capa - $tipo - Login - 404 de correo no registrado llega como 404', () async {
      adaptador.responder('GET', '/login', 404, {'mensaje': 'Perfil no encontrado'});

      final respuesta = await conexion.login('nadie@unicauca.edu.co');

      //el menu lateral abre el registro solo con este codigo
      expect(respuesta.codigoHttp, 404);
      expect(respuesta.datos, isNull);
    });

    test('$capa - $tipo - Login - sin red devuelve 503 sin lanzar', () async {
      adaptador.fallar('GET', '/login', DioExceptionType.connectionError);

      final respuesta = await conexion.login('ana@unicauca.edu.co');

      expect(respuesta.codigoHttp, 503);
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Registro - envia el perfil del formulario como json y 201 devuelve el perfil', () async {
      adaptador.responder('POST', '/RegistroPerfilAlumno', 201, leerContrato('autenticacion', 'registro_201'));

      final respuesta = await conexion.registro(perfilDelFormulario());

      final peticion = adaptador.peticionesA('POST', '/RegistroPerfilAlumno').single;
      expect(peticion.cuerpo, leerContrato('autenticacion', 'registro_peticion'));
      expect(respuesta.codigoHttp, 201);
      expect((respuesta.datos as Perfilmodelo).correo, 'beto@unicauca.edu.co');
    });

    test('$capa - $tipo - Registro - 409 de perfil existente llega como 409 sin lanzar', () async {
      adaptador.responder('POST', '/RegistroPerfilAlumno', 409, {'mensaje': 'El perfil ya existe'});

      final respuesta = await conexion.registro(perfilDelFormulario());

      expect(respuesta.codigoHttp, 409);
      expect(respuesta.datos, isNull);
    });
  });
}
