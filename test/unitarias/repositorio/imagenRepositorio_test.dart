import 'dart:convert';
import 'dart:io';

import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/data/repositories/imagenRepositorio.dart';
import 'package:dpt_movil/domain/entities/imagenEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionimagenFalsa.dart';

//Imagenrepositorio: la imagen pedida por id llega con sus bytes en base64 y
//sale como ImagenEntidad con los bytes decodificados; subir un archivo pasa
//directo a la conexion (PR-003.3)
void main() {
  const String capa = "repositorio";
  const String tipo = "unitaria";

  late ConexionimagenFalsa conexion;
  late Imagenrepositorio repositorio;

  setUp(() {
    conexion = ConexionimagenFalsa();
    repositorio = Imagenrepositorio(conexion: conexion);
  });

  ImagenModelo modelo({String? base64}) => ImagenModelo(
    id: 7,
    nombre: 'balon.png',
    tipoArchivo: 'image/png',
    longitud: 3,
    datosBase64: base64,
  );

  group('Imagenes (repositorio con doble):', () {
    test('$capa - $tipo - Obtener imagen - 200 convierte el modelo y decodifica los bytes', () async {
      conexion.respuestaObtener = RespuestaModelo(
        codigoHttp: 200,
        datos: modelo(base64: base64Encode([1, 2, 3])),
      );

      final respuesta = await repositorio.obtenerImagen(7);

      expect(conexion.ultimoId, 7);
      expect(respuesta.codigoHttp, 200);
      final imagen = respuesta.datos as ImagenEntidad;
      expect(
        [imagen.id, imagen.nombre, imagen.tipoArchivo, imagen.longitud, imagen.datos],
        [7, 'balon.png', 'image/png', 3, [1, 2, 3]],
      );
    });

    test('$capa - $tipo - Obtener imagen - un error pasa sin cambios', () async {
      final e404 = RespuestaModelo(
        codigoHttp: 404,
        error: ErrorModelo(codigoHttp: 404, mensaje: 'no existe', url: '/imagen', metodo: 'GET'),
      );
      conexion.respuestaObtener = e404;

      expect(await repositorio.obtenerImagen(99), same(e404));
    });

    test('$capa - $tipo - Obtener imagen - un base64 invalido se devuelve como error, sin lanzar', () async {
      conexion.respuestaObtener = RespuestaModelo(
        codigoHttp: 200,
        datos: modelo(base64: 'esto no es base64!'),
      );

      final respuesta = await repositorio.obtenerImagen(7);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });

    //IM-01 (corregido el 2026-11-19): el mapper hace datosBase64! y el
    //repositorio solo capturaba Exception; la conexion real deja
    //datosBase64 en null si no viene
    test('$capa - $tipo - Obtener imagen - IM-01 - una imagen sin datos se devuelve como error, sin lanzar', () async {
      conexion.respuestaObtener = RespuestaModelo(codigoHttp: 200, datos: modelo());

      final respuesta = await repositorio.obtenerImagen(7);

      expect(respuesta.codigoHttp, isNot(200));
      expect(respuesta.error, isNotNull);
    });

    test('$capa - $tipo - Insertar imagen - pasa el archivo a la conexion y devuelve su respuesta', () async {
      final archivo = File('assets/images/1.jpg');
      final creada = RespuestaModelo(codigoHttp: 201, datos: 12);
      conexion.respuestaInsertar = creada;

      final respuesta = await repositorio.insertarImagen(archivo);

      expect(respuesta, same(creada));
      expect(conexion.ultimoArchivo, same(archivo));
      expect(conexion.llamadasInsertar, 1);
    });
  });
}
