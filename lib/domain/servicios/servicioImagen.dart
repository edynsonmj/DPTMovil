import 'dart:io';

import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/imagenRepositorio.dart';

class Servicioimagen {
  Imagenrepositorio repositorio;

  //registrado en la raiz con la conexion de imagenes compartida; hoy ninguna
  //pantalla lo lee, se conserva para cuando se necesite
  Servicioimagen(this.repositorio);

  Future<RespuestaModelo> obtenerImagen(int id) async {
    return await repositorio.obtenerImagen(id);
  }

  Future<RespuestaModelo> insertarImagen(File imagen) async {
    return await repositorio.insertarImagen(imagen);
  }
}
