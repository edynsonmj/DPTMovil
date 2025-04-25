import 'dart:io';

import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

class Imagenrepositorio {
  Conexionimagen conexion;
  Imagenrepositorio({required this.conexion});

  Future<RespuestaModelo> obtenerImagen(int id) async {
    try {
      final RespuestaModelo respuesta = await conexion.obtenerImagen(id);
      if (respuesta.codigoHttp != 200) {
        return respuesta;
      }
      ImagenEntidad entidad = ImagenEntidad.fromModelo(respuesta.datos);
      respuesta.datos = entidad;
      return respuesta;
    } on FormatException catch (formatError) {
      return RespuestaModelo.fromFormatException(
        formatError,
        'POST',
        'agregarClaseGrupo',
        'Repositorio',
      );
    } on Exception catch (error) {
      return RespuestaModelo.fromException(
        error,
        'POST',
        'AgregarClaseGrupo',
        'repositorio',
      );
    }
  }

  Future<RespuestaModelo> insertarImagen(File entidad) {
    return conexion.insertarImagenFile(entidad);
  }
}
