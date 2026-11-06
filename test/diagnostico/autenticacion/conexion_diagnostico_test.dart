@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/api/conexion/remoto/ConexionAutenticacionRemoto.dart';
import 'package:dpt_movil/data/models/perfilModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../contratos/leerContrato.dart';
import '../../dobles/adaptadorHttpFalso.dart';

//diagnostico de la conexion real de autenticacion sobre el transporte falso
//(plan-diagnostico-autenticacion.md). Afirman el comportamiento CORRECTO y
//se espera que salgan rojas mientras el bug exista
void main() {
  const String capa = "conexion";
  const String tipo = "diagnostico";

  late AdaptadorHttpFalso adaptador;
  late Conexionautenticacionremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionautenticacionremoto(crearDioFalso(adaptador));
  });

  Map<String, dynamic> loginDelContrato() =>
      Map<String, dynamic>.from(leerContrato('autenticacion', 'login_200'));

  group('Autenticacion (diagnostico de la conexion):', () {
    //el path se arma con "/login?email=$email" sin codificar: un + llega al
    //servidor como espacio (mismo caso que GR-05)
    for (final correo in ['ana+deporte@unicauca.edu.co', 'ana&b@unicauca.edu.co']) {
      test('$capa - $tipo - Login - BUG AU-01 - el correo "$correo" llega al backend sin cambios', () async {
        adaptador.responder('GET', '/login', 200, loginDelContrato());

        await conexion.login(correo);

        final peticion = adaptador.peticionesA('GET', '/login').single;
        expect(peticion.uri.queryParameters, {'email': correo});
      });
    }

    //Perfilmodelo.fromJson no lee facultad: la sesion nunca la conoce
    //fromJson lanza TypeError (un Error, no una Exception) y la conexion
    //solo captura Exception: atraviesa repositorio y vm hasta el onTap del
    //menu (mismo caso que AL-04)
    test('$capa - $tipo - Login - BUG AU-03 - un perfil con un campo obligatorio nulo se devuelve como error, sin lanzar', () async {
      adaptador.responder('GET', '/login', 200, loginDelContrato()..['tipoId'] = null);

      final respuesta = await conexion.login('ana@unicauca.edu.co');

      expect(respuesta, isA<RespuestaModelo>());
      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Registro - BUG AU-03 - un 201 sin cuerpo se devuelve como error, sin lanzar', () async {
      adaptador.responder('POST', '/RegistroPerfilAlumno', 201);
      final json = leerContrato('autenticacion', 'registro_peticion');

      final respuesta = await conexion.registro(
        Perfilmodelo(
          id: json['id'],
          nombre: json['nombre'],
          correo: json['correo'],
          tipoId: json['tipoId'],
          sexo: json['sexo'],
        ),
      );

      expect(respuesta, isA<RespuestaModelo>());
      expect(respuesta.error, isNotNull);
    });
  });
}
