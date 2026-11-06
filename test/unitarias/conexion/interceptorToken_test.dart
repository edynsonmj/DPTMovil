import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/api/sesion/interceptorToken.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/adaptadorHttpFalso.dart';

//el Dio compartido con InterceptorToken, como lo arma la raiz: el JWT de la
//sesion sale en Authorization solo mientras hay sesion
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late AlmacenToken almacen;
  late Dio dio;

  setUp(() {
    adaptador = AdaptadorHttpFalso()..responder('GET', '/categorias2', 200, []);
    almacen = AlmacenToken();
    dio = crearDioFalso(adaptador)..interceptors.add(InterceptorToken(almacen));
  });

  test('$capa - $tipo - Interceptor token - sin sesion no envia Authorization', () async {
    await dio.get('/categorias2');

    expect(adaptador.peticiones.single.autorizacion, isNull);
  });

  test('$capa - $tipo - Interceptor token - con sesion envia el JWT y al cerrarla deja de enviarlo', () async {
    almacen.token = 'jwt-del-sistema';
    await dio.get('/categorias2');
    almacen.borrar();
    await dio.get('/categorias2');

    expect(adaptador.peticiones.map((p) => p.autorizacion), ['Bearer jwt-del-sistema', null]);
  });

  test('$capa - $tipo - Interceptor token - no pisa la cabecera que pone la conexion', () async {
    almacen.token = 'jwt-del-sistema';

    await dio.get('/categorias2', options: Options(headers: {'Authorization': 'Bearer id-token-de-google'}));

    expect(adaptador.peticiones.single.autorizacion, 'Bearer id-token-de-google');
  });
}
