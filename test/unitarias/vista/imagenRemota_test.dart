import 'package:dpt_movil/data/api/sesion/almacenToken.dart';
import 'package:dpt_movil/data/repositories/autenticacionRepositorio.dart';
import 'package:dpt_movil/domain/servicios/servicioAutenticacion.dart';
import 'package:dpt_movil/presentation/view/widgets/encabezadoImagen.dart';
import 'package:dpt_movil/presentation/view/widgets/imagenRemota.dart';
import 'package:dpt_movil/presentation/view/widgets/tarjeta.dart';
import 'package:dpt_movil/presentation/viewmodels/autenticacionViewModel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../dobles/conexionautenticacionFalsa.dart';
import '../../dobles/googleSignInFalso.dart';

//Image.network no pasa por el Dio: sin la cabecera, /imagenStream responde 401
//y Tarjeta y EncabezadoImagen pintan la imagen por defecto sin avisar
void main() {
  const String capa = "vista";
  const String tipo = "widget";
  const String url = 'http://falso/api/v2/imagenStream?idImagen=7';

  late AlmacenToken almacen;
  late AutenticacionViewModel vmSesion;

  setUp(() {
    almacen = AlmacenToken();
    vmSesion = AutenticacionViewModel(
      Servicioautenticacion(
        Autenticacionrepositorio(
          conexion: ConexionautenticacionFalsa(),
          almacenToken: almacen,
        ),
      ),
      GoogleSignInFalso(),
    );
  });

  Future<void> montar(WidgetTester tester, Widget hijo) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AutenticacionViewModel>.value(
        value: vmSesion,
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: hijo))),
      ),
    );
  }

  //el cliente http de flutter_test responde 400: errorBuilder evita que eso
  //falle la prueba, que solo mira la cabecera
  Widget imagen() => ImagenRemota(url, errorBuilder: (_, __, ___) => const SizedBox());

  //la primera imagen de red del arbol (la de assets no cuenta)
  Map<String, String>? cabeceras(WidgetTester tester) {
    final imagen = tester
        .widgetList<Image>(find.byType(Image))
        .firstWhere((i) => i.image is NetworkImage);
    return (imagen.image as NetworkImage).headers;
  }

  testWidgets('$capa - $tipo - ImagenRemota - con sesion envia el JWT', (tester) async {
    almacen.token = 'jwt-del-sistema';

    await montar(tester, imagen());

    expect(cabeceras(tester), {'Authorization': 'Bearer jwt-del-sistema'});
  });

  testWidgets('$capa - $tipo - ImagenRemota - sin sesion no envia cabecera', (tester) async {
    await montar(tester, imagen());

    expect(cabeceras(tester), isNull);
  });

  testWidgets('$capa - $tipo - ImagenRemota - al iniciar sesion usa el token nuevo', (tester) async {
    await montar(tester, imagen());

    almacen.token = 'jwt-del-sistema';
    vmSesion.notifyListeners();
    await tester.pump();

    expect(cabeceras(tester), {'Authorization': 'Bearer jwt-del-sistema'});
  });

  testWidgets('$capa - $tipo - Tarjeta - la imagen del backend lleva el JWT', (tester) async {
    almacen.token = 'jwt-del-sistema';

    await montar(tester, Tarjeta(atrUrlImagen: url, atrTitulo: 'Futbol'));

    expect(cabeceras(tester), {'Authorization': 'Bearer jwt-del-sistema'});
  });

  testWidgets('$capa - $tipo - EncabezadoImagen - la imagen del backend lleva el JWT', (tester) async {
    almacen.token = 'jwt-del-sistema';

    await montar(tester, EncabezadoImagen(urlImagen: url));

    expect(cabeceras(tester), {'Authorization': 'Bearer jwt-del-sistema'});
  });
}
