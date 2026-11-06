import 'package:dio/dio.dart';
import 'package:dpt_movil/data/api/sesion/almacenToken.dart';

//agrega "Authorization: Bearer <dpt_token>" a toda peticion del Dio
//compartido mientras haya sesion. No pisa una cabecera puesta por la
//conexion: /auth/token lleva en ella el ID Token de Google
class InterceptorToken extends Interceptor {
  final AlmacenToken _almacen;

  InterceptorToken(this._almacen);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final yaTieneCabecera = options.headers.keys.any(
      (clave) => clave.toLowerCase() == 'authorization',
    );
    if (_almacen.hayToken && !yaTieneCabecera) {
      options.headers['Authorization'] = 'Bearer ${_almacen.token}';
    }
    handler.next(options);
  }
}
