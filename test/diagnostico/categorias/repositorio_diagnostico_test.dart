@Tags(['diagnostico'])
library;

import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dobles/conexionCategoriaFalsa.dart';

//diagnostico del repositorio de categorias (plan-diagnostico-
//categorias.md): afirman el comportamiento CORRECTO y se espera que salgan
//rojas mientras el bug exista. Registro: auditoria-mvvm/registro-bugs.md
void main() {
  const String capa = "repositorio";
  const String tipo = "diagnostico";

  late ConexionCategoriaFalsa conexion;
  late CategoriaRepositorio repositorio;

  setUp(() {
    conexion = ConexionCategoriaFalsa();
    repositorio = CategoriaRepositorio(cliente: conexion);
  });

  group('Categorias (diagnostico del repositorio):', () {
    //los errores no se lanzan entre capas, se devuelven. La conexion real deja
    //pasar el TypeError de fromJson (CAT-06) y el de imagenFile! (CAT-01)
    test('$capa - $tipo - Listar, guardar, actualizar y eliminar - BUG CAT-13 - un TypeError de la conexion se devuelve como error, sin lanzar', () async {
      conexion.lanzar = TypeError();
      final entidad = CategoriaEntidad(titulo: 'Futbol', descripcion: 'Desc', idImagen: 4);

      for (final pedir in <Future<dynamic> Function()>[
        () => repositorio.encontrarCategorias(),
        () => repositorio.insertarCategoria(entidad),
        () => repositorio.actualizarCategoria(entidad),
        () => repositorio.eliminarCategoria('Futbol'),
      ]) {
        final respuesta = await pedir();
        expect(respuesta.codigoHttp, isNot(200));
        expect(respuesta.error, isNotNull);
      }
    });
    //CAT-14 (corregido) paso a test/unitarias/repositorio/categoriaRepositorio_test.dart
  });
}
