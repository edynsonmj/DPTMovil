import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dpt_movil/config/theme/color_tema.dart';
import 'package:dpt_movil/config/theme/tipografia.dart';
import 'package:dpt_movil/presentation/view/widgets/avatar.dart';

class MiniTarjeta extends StatelessWidget {
  final double atrMargerSuperior;
  final double atrMargerInferior;
  final double atrMargenIzquierdo;
  final double atrMargenDerecho;
  final String atrTitulo;
  final String atrSubTitulo;

  final Uint8List? atrDatosImagen;

  ///Indicador textual en la parte superior derecha
  String? atrIndicador;

  ///Indicador chip en la parte inferior derecha
  String? atrIndicadorEstado;

  ///habilitar boton de cierre en la parte derecha
  bool existeBotonCierre;
  bool existeCampoImagen;

  MiniTarjeta({
    super.key,
    required this.atrTitulo,
    required this.atrSubTitulo,
    //la url de la imagen no puede ser nula, pero si vacia, en cuyo caso tomara el valor por defecto
    this.atrDatosImagen,
    required this.existeCampoImagen,
    this.atrIndicador,
    this.atrIndicadorEstado,
    this.existeBotonCierre = false,
    this.atrMargerSuperior = 5,
    this.atrMargerInferior = 5,
    this.atrMargenIzquierdo = 5,
    this.atrMargenDerecho = 5,
  });

  @override
  Widget build(BuildContext context) {
    return tarjeta(context);
  }

  Widget tarjeta(BuildContext context) {
    final dimension = MediaQuery.of(context).size;
    Card tarjeta = Card(
      elevation: 4,
      margin: EdgeInsets.fromLTRB(atrMargenIzquierdo, atrMargerSuperior,
          atrMargenDerecho, atrMargerInferior),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: dimension.width * 0.9,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              if (existeCampoImagen)
                Avatar(atrDimension: 60, atrDatosImagen: atrDatosImagen),
              campoInformacion(context),
              if (existeBotonCierre) iconoAccion()
            ],
          ),
        ),
      ),
    );

    return tarjeta;
  }

  Widget campoInformacion(context) {
    Row fila = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        informacionTextual(),
        if (atrIndicador != null && atrIndicador != null) atrIndicadores(),
      ],
    );
    return Expanded(child: fila);
  }

  Widget iconoAccion() {
    return IconButton(
        onPressed: () {
          print('hola');
        },
        icon: Icon(Icons.close));
  }

  Widget informacionTextual() {
    return Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(atrTitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.subtitulo1(color: ColorTheme.primary)),
        Text(atrSubTitulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Tipografia.cuerpo2())
      ]),
    );
  }

  Widget atrIndicadores() {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      //antes de llamar se debe confirmar que los valores existen
      if (atrIndicador != null)
        Text(atrIndicador!,
            style: Tipografia.cuerpo2(color: ColorTheme.neutral)),
      if (atrIndicadorEstado != null)
        Chip(
            label: Text(
              atrIndicadorEstado!,
            ),
            labelPadding: EdgeInsets.all(0))
    ]);
  }
}
