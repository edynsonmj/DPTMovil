import 'package:flutter/material.dart';

class EditIcon extends StatelessWidget {
  //TODO: quitar ruta
  String? ruta;
  EditIcon({super.key, this.ruta});
  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.edit,
      color: Colors.white,
      shadows: [
        Shadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 5)
      ],
    );
  }
}
