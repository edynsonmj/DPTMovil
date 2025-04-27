//TODO: construir contrato (interface) que sea implementado por un repositorio
import 'dart:typed_data';

import 'package:dpt_movil/data/api/conexion/interfaces/ConexionCategoria.dart';
import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

class CategoriaRepositorio {
  ConexionCategoria cliente;
  CategoriaRepositorio({required this.cliente});

  Future<RespuestaModelo> encontrarCategorias() async {
    RespuestaModelo respuesta = await cliente.encontrarCategorias();
    //transformar datos si el codigo es 200
    if (respuesta.codigoHttp == 200) {
      //convertir los datos de modelo a entidad para que sean manjados por el front
      List<categoriaModelo> listaModelo =
          respuesta.datos as List<categoriaModelo>;
      List<CategoriaEntidad> listaEntidad = [];
      //convertimos los datos de modelo a entidad
      for (var item in listaModelo) {
        CategoriaEntidad entidad = CategoriaEntidad(
          titulo: item.titulo,
          descripcion: item.descripcion,
          imagen:
              (item.imagen == null)
                  ? null
                  : ImagenEntidad(
                    //si la imagen no es nula se crea el objeto
                    id: item.imagen!.id,
                    nombre: item.imagen!.nombre,
                    tipoArchivo: item.imagen!.tipoArchivo,
                    longitud: item.imagen!.longitud,
                    datos: Uint8List(8),
                  ),
          idImagen:
              item.imagenId, //se convierte la imagen a un tipo de dato manejable en el sistema
        );
        listaEntidad.add(entidad);
      }
      return RespuestaModelo(codigoHttp: 200, datos: listaEntidad);
    }
    //si el estado no es 200 solo se envia la respuesta que debe contener el o los errores encontrados con sus codigos
    return respuesta;
  }

  Future<RespuestaModelo> insertarCategoria(CategoriaEntidad entidad) async {
    categoriaModelo modeloPeticion = categoriaModelo(
      titulo: entidad.titulo,
      descripcion: entidad.descripcion,
      imagenFile: entidad.imagenFile,
    );
    CategoriaEntidad entidadRespuesta;

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
      categoriaModelo modelo = respuesta.datos as categoriaModelo;
      entidadRespuesta = CategoriaEntidad(
        titulo: modelo.titulo,
        descripcion: modelo.descripcion,
        idImagen: modelo.imagenId,
      );
      //escribo los datos transformados
      respuesta.datos = entidadRespuesta;
    }
    return respuesta;
  }

  Future<RespuestaModelo> eliminarCategoria(String titulo) async {
    RespuestaModelo respuesta = await cliente.eliminarCategoria(titulo);
    return respuesta;
  }

  Future<RespuestaModelo> actualizarCategoria(CategoriaEntidad entidad) async {
    categoriaModelo modeloPeticion = categoriaModelo(
      titulo: entidad.titulo,
      descripcion: entidad.descripcion,
      imagenId: entidad.idImagen,
    );
    CategoriaEntidad entidadRespuesta;
    if (entidad.imagenFile != null) {
      modeloPeticion.imagenFile = entidad.imagenFile;
    }

    final RespuestaModelo respuesta = await cliente.actualizarCategoria(
      modeloPeticion,
    );

    return respuesta;
  }
}
