import 'dart:typed_data';

import 'package:dpt_movil/presentation/view/widgets/imagenTarjeta.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/edit_icon.dart';

///Widget sin estado que muestra una tarjeta con imagen e informacion
class Tarjeta extends StatelessWidget {
  Uint8List? atrDatosImagen;
  int? idImagen;
  String? atrUrlImagen;
  String? atrTitulo;
  String? atrDescripcion;
  String? atrInfo1;
  String? atrInfo2;
  String? atrInfoPie;
  String? atrRutaTarjeta;

  Tarjeta({
    super.key,
    //la url de la imagen no puede ser nula, pero si vacia, en cuyo caso tomara el valor por defecto
    this.atrDatosImagen,
    this.atrUrlImagen = '',
    this.idImagen,
    this.atrTitulo,
    this.atrDescripcion,
    this.atrInfo1,
    this.atrInfo2,
    this.atrInfoPie,
    this.atrRutaTarjeta,
  });
  @override
  Widget build(BuildContext context) {
    return tarjeta(context);
  }

  Widget tarjeta(BuildContext context) {
    final dimension = MediaQuery.of(context).size;
    Card tarjeta = Card(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
      elevation: 4,
      //border redondeados
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //Stack permite posicionar elementos sobre elementos, con el arguemento positioned
      child: SizedBox(
        width: dimension.width * 0.8,
        child: cardBox(context, dimension, atrRutaTarjeta),
      ),
    );
    return tarjeta;
  }

  //contenido de la carta encapsulado
  Widget cardBox(BuildContext context, Size dimension, String? route) {
    //Inkwell permite definir un comportamiento al tocar el elemento
    return Column(
      children: [
        //if (atrUrlImagen != null) imagen(context, dimension),
        //imagen(context, dimension),
        Imagentarjeta(idImagen: idImagen),
        titulo(),
        //notese que se hacen las validaciones previo a pasar los datos, para no tener errores de null
        if (atrInfo2 != null && atrInfo1 != null) info(atrInfo1!, atrInfo2!),
        if (atrDescripcion != null) descripcion(atrDescripcion!),
        if (atrInfoPie != null) pieTarjeta(atrInfoPie!),
      ],
    );
  }

  Widget imagen(BuildContext context, Size dimension) {
    return ClipRRect(
      //border redondeador en la parte superior
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child:
          atrDatosImagen != null
              ? SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.memory(
                  atrDatosImagen!,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) =>
                          Image.asset('assets/images/1.jpg'),
                ),
              )
              : SizedBox(
                height: 200,
                width: double.infinity,
                child: Image.asset('assets/images/1.jpg', fit: BoxFit.cover),
              ),
    );
  }

  Widget titulo() {
    return Text(
      (atrTitulo != null) ? atrTitulo! : '',
      style: Tipografia.h6(color: ColorTheme.primary),
    );
  }

  Widget info(String info1, String info2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        chipInfo(info1, ColorTheme.secondary),
        chipInfo(info2, ColorTheme.secondary),
      ],
    );
  }

  Widget chipInfo(String data, Color color) {
    return Chip(
      label: Text(data),
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(fontSize: 12, color: color),
      padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      side: BorderSide(color: color),
    );
  }

  Widget descripcion(String texto) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      child: Text(
        texto,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: Tipografia.cuerpo2(),
      ),
    );
  }

  Widget pieTarjeta(String texto) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Tipografia.leyendaNegrita(color: ColorTheme.secondary),
      ),
    );
  }
}
