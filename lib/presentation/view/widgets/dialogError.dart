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
    return AlertDialog(
        shadowColor: ColorTheme.error,
        title: Text(titulo),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ..._detalle(),
              //el codigo distingue, p. ej., un 503 (sin red) de un 500
              //(servidor) con el mismo texto (X-01). Un codigo <= 0 no viene
              //del servidor y no dice nada al usuario
              if (codigo > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('Código: $codigo',
                      style: Tipografia.cuerpo1(color: ColorTheme.error)),
                ),
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

  //un 400 por campo llega como JSON y se lista campo por campo; cualquier
  //otro mensaje se muestra tal cual
  List<Widget> _detalle() {
    try {
      final decodificado = jsonDecode(mensaje);
      if (decodificado is Map<String, dynamic>) {
        return decodificado.entries.map((entry) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${entry.key}: ', style: Tipografia.cuerpo1()),
              Flexible(child: Text('${entry.value}')),
            ],
          );
        }).toList();
      }
    } on FormatException {
      //no es JSON: va como texto
    }
    return [Text(mensaje)];
  }
}
