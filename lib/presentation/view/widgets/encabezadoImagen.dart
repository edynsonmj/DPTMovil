import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../config/configServicio.dart';

class EncabezadoImagen extends StatelessWidget {
  Uint8List? atrDatosImagen;
  int? idImagen; // agrega esto

  EncabezadoImagen({super.key, this.atrDatosImagen, this.idImagen});

  @override
  Widget build(BuildContext context) {
    //TODO fase 4: recibir la url desde el vm, como Tarjeta; la pantalla de
    //curso no tiene vm de cursos y se rediseña en esa fase
    String path = '${ConfigServicio().obtenerBaseApi()}/imagenStream?idImagen=$idImagen';

    if (idImagen != null) {
      return Image.network(
        path,
        height: 200,
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            Image.asset('assets/images/1.jpg', fit: BoxFit.cover),
      );
    }
    return Image.asset('assets/images/1.jpg', fit: BoxFit.cover);
  }
}