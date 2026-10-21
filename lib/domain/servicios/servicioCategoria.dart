import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';

class ServicioCategoria {
  CategoriaRepositorio repositorio;

  //el repositorio llega armado desde la raiz de composicion
  //(lib/config/inyeccion/dependencias.dart)
  ServicioCategoria(this.repositorio);

  Future<RespuestaModelo> insertarCategoria(CategoriaEntidad entidad) async {
    return await repositorio.insertarCategoria(entidad);
  }

  Future<RespuestaModelo> encontrarCategorias() async {
    return await repositorio.encontrarCategorias();
  }

  Future<RespuestaModelo> eliminarCategoria(String titulo) async {
    return await repositorio.eliminarCategoria(titulo);
  }

  Future<RespuestaModelo> actualizarCategoria(CategoriaEntidad entidad) async {
    return await repositorio.actualizarCategoria(entidad);
  }

  String urlImagen(int idImagen) => repositorio.urlImagen(idImagen);
}
