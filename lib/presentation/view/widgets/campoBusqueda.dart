import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';

class CampoBusqueda extends StatelessWidget {
  String leyenda;
  CampoBusqueda({super.key, required this.leyenda});

  @override
  Widget build(BuildContext context) {
    return cuadroBusqueda(context);
  }

  Widget cuadroBusqueda(BuildContext context) {
    return Container(
        height: 50,
        child: TextField(
          decoration: InputDecoration(
            hintText: leyenda,
            prefixIcon: Icon(Icons.search),
            hintStyle: TextStyle(
                color: ColorTheme.neutral, fontFamily: Tipografia.cuerpo),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ));
  }
}
