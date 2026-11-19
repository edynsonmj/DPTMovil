import 'dart:convert';

import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/adaptadorHttpFalso.dart';

//la conexion real de imagenes sobre el transporte falso: lectura de una
//imagen por id (GET /imagen?idImagen=)
void main() {
  const String capa = "conexion";
  const String tipo = "unitaria";

  late AdaptadorHttpFalso adaptador;
  late Conexionimagenremoto conexion;

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    conexion = Conexionimagenremoto(crearDioFalso(adaptador));
  });

  Map<String, dynamic> imagen() => {
    'id': 7,
    'nombre': 'balon.png',
    'tipoArchivo': 'image/png',
    'longitud': 3,
    'datosBase64': base64Encode([1, 2, 3]),
  };

  group('Imagenes (conexion remota con transporte falso):', () {
    test('$capa - $tipo - Obtener imagen - 200 pide el id y devuelve el modelo', () async {
      adaptador.responder('GET', '/imagen', 200, imagen());

      final respuesta = await conexion.obtenerImagen(7);

      expect(adaptador.peticionesA('GET', '/imagen').single.uri.queryParameters, {'idImagen': '7'});
      expect(respuesta.codigoHttp, 200);
      expect((respuesta.datos as ImagenModelo).datosBase64, base64Encode([1, 2, 3]));
    });

    //IM-01 (corregido el 2026-11-19): fromJson lanza un TypeError (un Error,
    //no una Exception) con un campo obligatorio nulo
    test('$capa - $tipo - Obtener imagen - IM-01 - una imagen incompleta se devuelve como error, sin lanzar', () async {
      adaptador.responder('GET', '/imagen', 200, imagen()..['nombre'] = null);

      final respuesta = await conexion.obtenerImagen(7);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });
  });
}
