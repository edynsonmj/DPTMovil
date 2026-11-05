import 'dart:convert';

import 'package:dpt_movil/data/mappers/imagenMapper.dart';
import 'package:dpt_movil/data/models/imagenModelo.dart';
import 'package:flutter_test/flutter_test.dart';

//conversion modelo -> entidad de imagenes, sin conexion ni repositorio
void main() {
  const String capa = "mapper";
  const String tipo = "unitaria";

  group('Imagenes (mapper):', () {
    test('$capa - $tipo - aEntidad - copia los campos y decodifica los bytes', () {
      final entidad = ImagenMapper.aEntidad(
        ImagenModelo(
          id: 3,
          nombre: 'futbol.jpg',
          tipoArchivo: 'image/jpeg',
          longitud: 3,
          datosBase64: base64Encode([1, 2, 3]),
        ),
      );

      expect(entidad.id, 3);
      expect(entidad.nombre, 'futbol.jpg');
      expect(entidad.tipoArchivo, 'image/jpeg');
      expect(entidad.longitud, 3);
      expect(entidad.datos, [1, 2, 3]);
    });
  });
}
