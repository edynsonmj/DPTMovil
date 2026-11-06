import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dpt_movil/config/configApi.dart' show crearClienteHttp;
import 'package:dpt_movil/config/routes/roles.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/api/sesion/interceptorToken.dart';

//JWT de prueba para la suite remota. El backend valida su propio JWT solo con
//la firma HS256 y la fecha, asi que una prueba que conoce el secreto del
//backend LOCAL puede emitirlo sin pasar por Google. Mismos claims que
//TokenServicio del backend: sub, iat, exp, rol y perf_id.
//
//El camino real Google → /auth/token no se prueba aqui: se comprueba a mano
//en el emulador. Nunca usar el secreto de un backend de produccion.

//ruta del .env del backend; se cambia con la variable de entorno DPT_BACKEND_ENV
const String _envBackendPorDefecto =
    'E:/2026-1/Practica/BackDeporteParaTodos (Nuevo)/.env';

//orden: --dart-define=JWT_SECRET, variable de entorno JWT_SECRET, .env del
//backend. El valor no se guarda en el repositorio ni se imprime
String _leerSecreto() {
  const definido = String.fromEnvironment('JWT_SECRET');
  if (definido.isNotEmpty) return definido;

  final delEntorno = Platform.environment['JWT_SECRET'];
  if (delEntorno != null && delEntorno.isNotEmpty) return delEntorno;

  final ruta = Platform.environment['DPT_BACKEND_ENV'] ?? _envBackendPorDefecto;
  final archivo = File(ruta);
  if (archivo.existsSync()) {
    for (final linea in archivo.readAsLinesSync()) {
      final m = RegExp(r'^\s*(?:export\s+)?JWT_SECRET=(.*)$').firstMatch(linea);
      if (m != null) {
        return m.group(1)!.trim().replaceAll(RegExp('''^["']|["']\$'''), '');
      }
    }
  }
  throw StateError(
    'Falta JWT_SECRET para la suite remota: define JWT_SECRET o apunta '
    'DPT_BACKEND_ENV al .env del backend local ($ruta)',
  );
}

final List<int> _claveSecreta = base64.decode(_leerSecreto());

String _base64Url(List<int> bytes) =>
    base64Url.encode(bytes).replaceAll('=', '');

//firma un JWT como lo haria TokenServicio
String firmarJwtPrueba({
  required String correo,
  required String rol,
  required String perfId,
  Duration vigencia = const Duration(hours: 2),
}) {
  final ahora = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final cabecera = _base64Url(utf8.encode(jsonEncode({'alg': 'HS256'})));
  final datos = _base64Url(
    utf8.encode(
      jsonEncode({
        'sub': correo,
        'iat': ahora,
        'exp': ahora + vigencia.inSeconds,
        'rol': rol,
        'perf_id': perfId,
      }),
    ),
  );
  final firma = Hmac(
    sha256,
    _claveSecreta,
  ).convert(utf8.encode('$cabecera.$datos'));
  return '$cabecera.$datos.${_base64Url(firma.bytes)}';
}

//identidad con la que sale cada peticion de la suite: una sola, compartida
//por todos los Dio de crearDioPruebas, igual que AlmacenToken en la app. Por
//defecto, coordinador: es quien siembra casi todos los datos
final AlmacenToken almacenPruebas = AlmacenToken()..token = _tokenCoordinador();

String _tokenCoordinador() => firmarJwtPrueba(
  correo: 'coordinador@prueba.test',
  rol: Roles.coordinador,
  perfId: 'coordinador-prueba',
);

void actuarComoCoordinador() => almacenPruebas.token = _tokenCoordinador();

void actuarComoAlumno(String idPerfil, {String correo = 'alumno@prueba.test'}) =>
    almacenPruebas.token = firmarJwtPrueba(
      correo: correo,
      rol: Roles.alumno,
      perfId: idPerfil,
    );

void actuarComoInstructor(
  String idPerfil, {
  String correo = 'instructor@prueba.test',
}) => almacenPruebas.token = firmarJwtPrueba(
  correo: correo,
  rol: Roles.instructor,
  perfId: idPerfil,
);

//el Dio de la raiz apuntando al backend de pruebas, con el mismo interceptor
//de la app
Dio crearDioPruebas(String baseUrl) =>
    crearClienteHttp(baseUrl)
      ..interceptors.add(InterceptorToken(almacenPruebas));
