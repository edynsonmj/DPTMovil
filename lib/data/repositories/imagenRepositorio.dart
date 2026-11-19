import 'dart:io';

import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/mappers/imagenMapper.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

class Imagenrepositorio {
  Conexionimagen conexion;
  Imagenrepositorio({required this.conexion});

  Future<RespuestaModelo> obtenerImagen(int id) async {
    try {
      final RespuestaModelo respuesta = await conexion.obtenerImagen(id);
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      respuesta.datos = ImagenMapper.aEntidad(respuesta.datos as ImagenModelo);
      return respuesta;
    } on FormatException catch (formatError) {
      //base64 invalido
      return RespuestaModelo.fromFormatException(
        formatError,
        'GET',
        'obtenerImagen',
        'repositorio',
      );
    } catch (error) {
      //sin datosBase64 el mapper falla con un Error, no una Exception (IM-01)
      return RespuestaModelo.fromObjectError(
        error,
        'GET',
        'obtenerImagen',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> insertarImagen(File entidad) {
    return conexion.insertarImagenFile(entidad);
  }
}
