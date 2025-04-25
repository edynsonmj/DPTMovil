import 'dart:io';

import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

abstract class Conexionimagen {
  Future<RespuestaModelo> insertarImagenFile(File file);
  Future<RespuestaModelo> obtenerImagen(int idImagen);
}
