import 'dart:convert';

import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

//conversion modelo -> entidad de imagenes. Solo hay este sentido: para
//subir una imagen la conexion recibe el File directamente
class ImagenMapper {
  //la imagen pedida por id trae sus bytes en base64
  static ImagenEntidad aEntidad(ImagenModelo modelo) {
    return ImagenEntidad(
      id: modelo.id,
      nombre: modelo.nombre,
      tipoArchivo: modelo.tipoArchivo,
      longitud: modelo.longitud,
      datos: Base64Decoder().convert(modelo.datosBase64!),
    );
  }
}
