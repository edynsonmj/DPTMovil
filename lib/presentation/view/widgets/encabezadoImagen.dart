import 'dart:typed_data';

import 'package:flutter/material.dart';

class EncabezadoImagen extends StatelessWidget {
  Uint8List? atrDatosImagen;
  EncabezadoImagen({super.key, this.atrDatosImagen});

  @override
  Widget build(BuildContext context) {
    return (atrDatosImagen != null
        ? Image.memory(
            atrDatosImagen!,
            height: 200,
            width: MediaQuery.of(context).size.width,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Image.asset('assets/images/1.jpg'),
          )
        : Image.asset('assets/images/1.jpg', fit: BoxFit.cover));
  }
}
