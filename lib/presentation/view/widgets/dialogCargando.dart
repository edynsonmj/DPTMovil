import 'package:flutter/material.dart';

class DialogCargando extends StatelessWidget{
  DialogCargando({super.key});
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cargando'),
      content: CircularProgressIndicator()
    );
  }
}