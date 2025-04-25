import 'dart:io';

import 'package:dpt_movil/data/api/fabrica/ConexionFabricaAbstracta.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/imagenRepositorio.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

class Servicioimagen {
  Imagenrepositorio repositorio;
  Servicioimagen()
    : repositorio = Imagenrepositorio(
        conexion:
            ConexionFabricaAbstracta.obtenerConexionFabrica()
                .crearConexionImagenes(),
      );

  Future<RespuestaModelo> obtenerImagen(int id) async {
    return await repositorio.obtenerImagen(id);
  }

  Future<RespuestaModelo> insertarImagen(File imagen) async {
    return await repositorio.insertarImagen(imagen);
  }
}
