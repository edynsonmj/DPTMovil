import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/deporteRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexiondeporteFalsa.dart';

//Deporterepositorio no convierte nada: la conexion ya entrega los nombres
//(List<String>) y el repositorio los pasa tal cual (PR-003.3)
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexiondeporteFalsa conexion;
  late Deporterepositorio repositorio;

  setUp(() {
    conexion = ConexiondeporteFalsa();
    repositorio = Deporterepositorio(cliente: conexion);
  });

  test('$capa - $tipo - Obtener deportes - 200 devuelve los nombres sin cambios', () async {
    final ok = RespuestaModelo(codigoHttp: 200, datos: <String>['Fútbol', 'Natación']);
    conexion.respuestaDeportes = ok;

    final respuesta = await repositorio.obtenerDeportes();

    expect(respuesta, same(ok));
    expect(respuesta.datos, ['Fútbol', 'Natación']);
    expect(conexion.llamadasDeportes, 1);
  });

  test('$capa - $tipo - Obtener deportes - 204 y los errores pasan sin cambios', () async {
    for (final codigo in [204, 500, 503]) {
      final e = RespuestaModelo(
        codigoHttp: codigo,
        error: ErrorModelo(codigoHttp: codigo, mensaje: 'fallo', url: '/deportes', metodo: 'GET'),
      );
      conexion.respuestaDeportes = e;

      expect(await repositorio.obtenerDeportes(), same(e));
    }
  });
}
