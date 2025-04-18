import 'package:flutter/material.dart';

class Tipografia {
  static String cuerpo = 'OpenSans';
  static String titulo = 'TitiliumWeb';

  static FontWeight thin = FontWeight.w100;
  static FontWeight extraLight = FontWeight.w200;
  static FontWeight light = FontWeight.w300;
  static FontWeight regular = FontWeight.w400;
  static FontWeight medium = FontWeight.w500;
  static FontWeight semiBold = FontWeight.w600;
  static FontWeight bold = FontWeight.w700;
  static FontWeight extraBold = FontWeight.w800;
  static FontWeight black = FontWeight.w900;

  static TextStyle h1({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 90,
      fontWeight: light,
      fontFamily: titulo,
    );
  }

  static TextStyle h2({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 60,
      fontWeight: bold,
      fontFamily: titulo,
    );
  }

  static TextStyle h3({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 46,
      fontWeight: bold,
      fontFamily: titulo,
    );
  }

  static TextStyle h4({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 32,
      fontWeight: bold,
      fontFamily: titulo,
    );
  }

  static TextStyle h5({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 22,
      fontWeight: bold,
      fontFamily: titulo,
    );
  }

  static TextStyle h6({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 18,
      fontWeight: semiBold,
      fontFamily: titulo,
    );
  }

  static TextStyle subtitulo1({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 16,
      fontWeight: bold,
      fontFamily: titulo,
    );
  }

  static TextStyle subtitulo2({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 16,
      fontWeight: semiBold,
      fontFamily: titulo,
    );
  }

  static TextStyle subtitulo3({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 14,
      fontWeight: semiBold,
      fontFamily: titulo,
    );
  }

  static TextStyle cuerpo1({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 14,
      fontWeight: bold,
      fontFamily: cuerpo,
    );
  }

  static TextStyle cuerpo2({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 14,
      fontWeight: regular,
      fontFamily: cuerpo,
    );
  }

  static TextStyle cuerpo3({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: regular,
      fontFamily: cuerpo,
    );
  }

  static TextStyle boton1({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: bold,
      fontFamily: cuerpo,
    );
  }

  //el texto debe ser usado en mayusculas
  static TextStyle boton2({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 14,
      fontWeight: bold,
      fontFamily: cuerpo,
    );
  }

  static TextStyle leyenda({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: regular,
      fontFamily: cuerpo,
    );
  }

  static TextStyle leyendaNegrita({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: bold,
      fontFamily: cuerpo,
    );
  }

  static TextStyle overline({Color? color}) {
    return TextStyle(
      color: color,
      fontSize: 10,
      fontWeight: regular,
      fontFamily: cuerpo,
    );
  }
}
