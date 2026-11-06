import 'dart:typed_data';

import 'package:dpt_movil/presentation/view/widgets/imagenRemota.dart';
import 'package:flutter/material.dart';

class EncabezadoImagen extends StatelessWidget {
  Uint8List? atrDatosImagen;
  //la url llega armada desde el vm: el widget no conoce el servidor
  String? urlImagen;

  EncabezadoImagen({super.key, this.atrDatosImagen, this.urlImagen});

  @override
  Widget build(BuildContext context) {
    if (urlImagen != null && urlImagen!.isNotEmpty) {
      return ImagenRemota(
        urlImagen!,
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
