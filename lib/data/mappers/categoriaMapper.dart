import 'dart:typed_data';

import 'package:dpt_movil/data/models/categoriaModelo.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';

//conversion modelo <-> entidad de categorias. Vive en la capa de datos para
//que las entidades no conozcan los modelos (el dominio no depende de datos)
class CategoriaMapper {
  static CategoriaEntidad aEntidad(categoriaModelo modelo) {
    return CategoriaEntidad(
      titulo: modelo.titulo,
      descripcion: modelo.descripcion,
      imagen: (modelo.imagen == null) ? null : _imagenAEntidad(modelo.imagen!),
      idImagen: modelo.imagenId,
    );
  }

  static categoriaModelo aModelo(CategoriaEntidad entidad) {
    return categoriaModelo(
      titulo: entidad.titulo,
      descripcion: entidad.descripcion,
      imagenId: entidad.idImagen,
      imagenFile: entidad.imagenFile,
    );
  }

  //el listado no trae los bytes de la imagen: las vistas la piden por url
  //(urlImagen), asi que datos queda como relleno
  static ImagenEntidad _imagenAEntidad(ImagenModelo imagen) {
    return ImagenEntidad(
      id: imagen.id,
      nombre: imagen.nombre,
      tipoArchivo: imagen.tipoArchivo,
      longitud: imagen.longitud,
      datos: Uint8List(8),
    );
  }
}
