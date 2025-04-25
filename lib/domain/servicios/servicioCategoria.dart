import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';

class ServicioCategoria {
  CategoriaRepositorio repositorio;

  ServicioCategoria()
    : repositorio = CategoriaRepositorio(
        cliente:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionCategoria(),
      );

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
}
