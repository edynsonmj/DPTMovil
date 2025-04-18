import 'package:flutter/material.dart';

class DialogExito extends StatelessWidget {
  String titulo;
  String mensaje;

  DialogExito({required this.titulo, required this.mensaje});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(titulo),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [Text(mensaje)]),
      actions: [
        FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('OK')),
      ],
    );
  }
}
