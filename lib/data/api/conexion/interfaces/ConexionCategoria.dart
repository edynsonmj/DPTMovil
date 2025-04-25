import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class ConexionCategoria {
  //Future<List<categoriaModelo>> obtenerCategorias();
  Future<RespuestaModelo> encontrarCategorias();
  Future<RespuestaModelo> guardarCategoria(categoriaModelo categoria);
  Future<RespuestaModelo> eliminarCategoria(String titulo);
  Future<RespuestaModelo> actualizarCategoria(categoriaModelo categoria);
}
