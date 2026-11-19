import 'dart:io';

import 'package:dpt_movil/data/api/conexion/interfaces/ConexionImagen.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';

//doble programable de la conexion de imagenes: el test fija las respuestas
//y mira que id o que archivo llegaron
class ConexionimagenFalsa implements Conexionimagen {
  RespuestaModelo respuestaObtener = RespuestaModelo(codigoHttp: 200);
  int? ultimoId;
  int llamadasObtener = 0;

  RespuestaModelo respuestaInsertar = RespuestaModelo(codigoHttp: 201, datos: 1);
  File? ultimoArchivo;
  int llamadasInsertar = 0;

  @override
  Future<RespuestaModelo> obtenerImagen(int idImagen) async {
    llamadasObtener++;
    ultimoId = idImagen;
    return respuestaObtener;
  }

  @override
  Future<RespuestaModelo> insertarImagenFile(File file) async {
    llamadasInsertar++;
    ultimoArchivo = file;
    return respuestaInsertar;
  }
}
