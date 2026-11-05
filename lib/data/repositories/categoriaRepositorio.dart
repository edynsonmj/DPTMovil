//TODO: construir contrato (interface) que sea implementado por un repositorio
import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/mappers/categoriaMapper.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';

class CategoriaRepositorio {
  ConexionCategoria cliente;
  CategoriaRepositorio({required this.cliente});

  String urlImagen(int idImagen) => cliente.urlImagen(idImagen);

  Future<RespuestaModelo> encontrarCategorias() async {
    RespuestaModelo respuesta = await cliente.encontrarCategorias();
    //transformar datos si el codigo es 200
    if (respuesta.codigoHttp == 200) {
      //convertir los datos de modelo a entidad para que sean manejados por el front
      List<categoriaModelo> listaModelo =
          respuesta.datos as List<categoriaModelo>;
      List<CategoriaEntidad> listaEntidad =
          listaModelo.map(CategoriaMapper.aEntidad).toList();
      return RespuestaModelo(codigoHttp: 200, datos: listaEntidad);
    }
    //si el estado no es 200 solo se envia la respuesta que debe contener el o los errores encontrados con sus codigos
    return respuesta;
  }

  Future<RespuestaModelo> insertarCategoria(CategoriaEntidad entidad) async {
    //sin imagen la conexion no puede armar la peticion, se corta antes de la red
    if (entidad.imagenFile == null && entidad.idImagen == null) {
      return RespuestaModelo(
        codigoHttp: 400,
        datos: null,
        error: ErrorModelo(
          codigoHttp: 400,
          mensaje: 'La categoria requiere una imagen',
          url: 'insertarCategoria',
          metodo: 'POST',
        ),
      );
    }
    //si hay archivo, la conexion lo sube y reemplaza el imagenId
    categoriaModelo modeloPeticion = CategoriaMapper.aModelo(entidad);

    final RespuestaModelo respuesta = await cliente.guardarCategoria(
      modeloPeticion,
    );

    //transformar los datos para que puedan ser manejados apropiadamente.
    if (respuesta.codigoHttp == 201) {
      if (respuesta.datos == null) {
        //a travez del codigo informamos que no hay datos pero la peticion fue correcta
        respuesta.codigoHttp = 204;
        return respuesta;
      }
      //escribo los datos transformados
      respuesta.datos = CategoriaMapper.aEntidad(
        respuesta.datos as categoriaModelo,
      );
    }
    return respuesta;
  }

  Future<RespuestaModelo> eliminarCategoria(String titulo) async {
    RespuestaModelo respuesta = await cliente.eliminarCategoria(titulo);
    return respuesta;
  }

  Future<RespuestaModelo> actualizarCategoria(CategoriaEntidad entidad) async {
    categoriaModelo modeloPeticion = CategoriaMapper.aModelo(entidad);

    final RespuestaModelo respuesta = await cliente.actualizarCategoria(
      modeloPeticion,
    );

    //transformar los datos para que puedan ser manejados apropiadamente,
    //el modelo no debe salir de la capa de datos
    if (respuesta.codigoHttp == 200) {
      if (respuesta.datos == null) {
        //a travez del codigo informamos que no hay datos pero la peticion fue correcta
        respuesta.codigoHttp = 204;
        return respuesta;
      }
      respuesta.datos = CategoriaMapper.aEntidad(
        respuesta.datos as categoriaModelo,
      );
    }
    return respuesta;
  }
}
