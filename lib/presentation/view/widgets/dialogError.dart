import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';

class DialogError extends StatelessWidget {
  String titulo;
  int codigo;
  String mensaje;
  DialogError(
      {super.key,
      required this.titulo,
      required this.mensaje,
      required this.codigo});
  @override
  Widget build(BuildContext context) {
    try {
      final Map<String, dynamic> jsonDecodificado = jsonDecode(mensaje);
      return AlertDialog(
          shadowColor: ColorTheme.error,
          title: Text(titulo),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...jsonDecodificado.entries.map((entry) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${entry.key}: ', style: Tipografia.cuerpo1()),
                      Flexible(child: Text('${entry.value}')),
                    ],
                  );
                }).toList(),
              ],
            ),
          ),
          actions: [
            FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cerrar'))
          ]);
    } catch (e) {
      return AlertDialog(
          title: Text(titulo),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(mensaje),
              ],
            ),
          ),
          actions: [
            FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('Cerrar'))
          ]);
    }

    //final data = jsonDecodificado.map((item)=> item as MapEntry<String,dynamic>).toList();
  }
}
