import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/imagenRepositorio.dart';
import 'package:flutter_test/flutter_test.dart';

class Obtenerimagentest {
  void prueba1codigo200(Imagenrepositorio repositorio) {
    test('Evaluacion codigo 200', () async {
      RespuestaModelo respuesta = await repositorio.obtenerImagen(3);
      print(respuesta.codigoHttp);
      expect(respuesta.codigoHttp, 200);
    });
  }
}
