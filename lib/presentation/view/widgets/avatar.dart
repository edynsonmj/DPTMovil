import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';

class Avatar extends StatelessWidget {
  Uint8List? atrDatosImagen;
  double atrDimension;

  Avatar({super.key, this.atrDatosImagen, required this.atrDimension});

  @override
  Widget build(BuildContext context) {
    return campoImagen();
  }

  Widget campoImagen() {
    return Container(
      width: atrDimension,
      height: atrDimension,
      margin: const EdgeInsets.fromLTRB(5, 0, 10, 0),
      decoration: BoxDecoration(
        border: Border.all(color: ColorTheme.primary, width: 2),
        borderRadius: BorderRadius.circular(100),
      ),
      clipBehavior: Clip.antiAlias,
      child: imagen(),
    );
  }

  Widget imagen() {
    return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: FittedBox(
          fit: BoxFit.cover,
          child: atrDatosImagen != null
              ? Image.memory(
                  atrDatosImagen!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/images/1.jpg'),
                )
              : Image.asset(
                  'assets/images/1.jpg',
                  fit: BoxFit.cover,
                ),
        ));
  }
}
