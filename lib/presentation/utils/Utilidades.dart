import 'package:flutter/material.dart';

class Utilidades {
  static Future<bool> mostrarDialogoConfirmacion(
    BuildContext context,
    String mensaje,
    String titulo,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: Text(
                titulo,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: Text(mensaje),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(
                    'Eliminar',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
  }
}
