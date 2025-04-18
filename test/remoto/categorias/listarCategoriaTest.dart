import 'package:flutter_test/flutter_test.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';

class ListarCategoriaTest {
  void prueba1codigo200(CategoriaRepositorio repositorio) {
    test('Evaluacion codigo 200', () async {
      RespuestaModelo respuesta = await repositorio.encontrarCategorias();
      imprimirRespuesta(respuesta);
      expect(respuesta.codigoHttp, 200);
    });
  }

  void prueba2codigo204(CategoriaRepositorio repositorio) {
    test('Evaluacion codigo 204', () async {
      RespuestaModelo respuesta = await repositorio.encontrarCategorias();
      imprimirRespuesta(respuesta);
      expect(respuesta.codigoHttp, 204);
    });
  }

  void imprimirRespuesta(RespuestaModelo respuesta) {
    print('codigo: ${respuesta.codigoHttp}');
    if (respuesta.datos != null) {
      imprimirDatos(respuesta.datos);
    }
    if (respuesta.error != null) {
      imprimirError(respuesta.error!);
    }
  }

  void imprimirDatos(dynamic datos) {
    if (datos is List<CategoriaEntidad>) {
      List<CategoriaEntidad> lista = datos as List<CategoriaEntidad>;
      print('longitud: ${lista.length}');
      print('primardato: ${lista[0].titulo}');
    } else {
      print('no se registra una lista');
    }
  }

  void imprimirError(ErrorModelo error) {
    print('error codigo: ${error.codigoHttp}');
    print('error mensaje: ${error.mensaje}');
    print('error metodo: ${error.metodo}');
    print('error url: ${error.url}');
  }
}
