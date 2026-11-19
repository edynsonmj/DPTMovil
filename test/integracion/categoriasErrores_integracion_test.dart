import 'dart:io';

import 'package:dpt_movil/data/api/conexion/remoto/ConexionCategoriaRemota.dart';
import 'package:dpt_movil/data/api/conexion/remoto/ConexionImagenRemoto.dart';
import 'package:dpt_movil/data/repositories/categoriaRepositorio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

import '../contratos/leerContrato.dart';
import '../dobles/adaptadorHttpFalso.dart';

//errores de categorias de punta a punta sin backend (CAT-01, CAT-02, CAT-03,
//CAT-04, CAT-06, CAT-09): el mismo montaje que categorias_integracion_test.dart
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late CategoriaViewModel vm;

  String texto(Resultado r) => switch (r) {
    Exito() => 'Exito',
    Fallo(:final codigo, :final mensaje, :final origen) =>
      'Fallo $codigo $mensaje ($origen)',
  };

  setUp(() {
    adaptador = AdaptadorHttpFalso();
    final dio = crearDioFalso(adaptador);
    vm = CategoriaViewModel(
      ServicioCategoria(
        CategoriaRepositorio(
          cliente: ConexionCategoriaRemota(dio, Conexionimagenremoto(dio)),
        ),
      ),
    );
    adaptador.responder('GET', '/categorias2', 200, leerContrato('categorias', 'categorias2_200'));
  });

  group('Categorias (errores de punta a punta):', () {
    //lo mismo que hace la unitaria "Guardar categoria - 201 refresca la
    //lista" (T-01), pero con la conexion real en lugar del doble
    test('$capa - $tipo - Insertar categoria - con idImagen y sin archivo no escapa una excepcion hasta el vm', () async {
      adaptador.responder('POST', '/categoria', 201, leerContrato('categorias', 'categoria_201'));

      final resultado = await vm.insertarCategoria(
        CategoriaEntidad(titulo: 'Categoria nueva', descripcion: 'x', idImagen: 1300),
      );

      //Fallo(-1, ..., origen: 'ViewModel') es el catch del vm: una excepcion
      //que atraveso conexion, repositorio y servicio
      final escapo = switch (resultado) {
        Fallo(:final origen) => origen == 'ViewModel',
        Exito() => false,
      };
      expect(escapo, isFalse, reason: texto(resultado));
    });

    test('$capa - $tipo - Insertar categoria - un 201 sin cuerpo es Exito', () async {
      adaptador.responder('POST', '/imagenMultipart', 201, leerContrato('categorias', 'imagenMultipart_201'));
      adaptador.responder('POST', '/categoria', 201);

      final resultado = await vm.guardarCategoria(
        titulo: 'Categoria nueva',
        descripcion: 'x',
        imagenNueva: _imagen(),
      );

      expect(resultado, isA<Exito>(), reason: texto(resultado));
    });

    test('$capa - $tipo - Actualizar y eliminar - el titulo llega completo a la query', () async {
      adaptador.responder('PUT', '/categoria', 200, leerContrato('categorias', 'categoria_201'));
      adaptador.responder('DELETE', '/categoria', 200);
      const titulo = 'Fútbol & Voleibol';

      await vm.actualizarCategoria(
        CategoriaEntidad(titulo: titulo, descripcion: 'x', idImagen: 4),
      );
      await vm.eliminarCategoria(titulo);

      expect(
        [
          adaptador.peticionesA('PUT', '/categoria').single.uri.queryParameters['titulo'],
          adaptador.peticionesA('DELETE', '/categoria').single.uri.queryParameters['titulo'],
        ],
        [titulo, titulo],
      );
    });

    //la ruta crea el vm y lo desecha al salir: una carga que llega despues no
    //debe notificar
    test('$capa - $tipo - Listar categorias - una respuesta que llega despues de dispose no lanza', () async {
      final retenida = adaptador.retener('GET', '/categorias2');
      final carga = vm.listarYNotificarCategorias();
      await _hastaQue(() => adaptador.peticiones.length == 1);
      vm.dispose();
      retenida.complete();

      Object? lanzado;
      try {
        await carga;
      } catch (e) {
        lanzado = e;
      }
      expect(lanzado, isNull, reason: '$lanzado');
    });

    //una categoria sin titulo: fromJson lanza un TypeError que atraviesa la
    //conexion (solo captura Exception) y el repositorio (sin try)
    test('$capa - $tipo - Listar categorias - una categoria incompleta llega como error con codigo, no como excepcion', () async {
      adaptador.responder('GET', '/categorias2', 200, [
        {'titulo': null, 'descripcion': 'x', 'imagenId': 1},
      ]);

      await vm.listarYNotificarCategorias();

      expect(vm.error, isNotNull);
      expect(vm.error, startsWith('Código: '));
    });

    //la carga del inicio y la del refresco tras guardar pueden solaparse
    test('$capa - $tipo - Listar categorias - una respuesta vieja que llega tarde no pisa la nueva', () async {
      final vieja = adaptador.retener('GET', '/categorias2');
      final primera = vm.listarYNotificarCategorias();
      //hasta que la primera peticion este de verdad retenida en el adaptador
      await _hastaQue(() => adaptador.peticiones.length == 1);

      adaptador.retener('GET', '/categorias2').complete();
      adaptador.responder('GET', '/categorias2', 200, [
        {'titulo': 'Nueva', 'descripcion': 'x', 'imagenId': 1},
      ]);
      await vm.listarYNotificarCategorias();
      expect(vm.categorias!.map((c) => c.titulo), ['Nueva']);

      //la primera peticion trae los datos de antes
      adaptador.responder('GET', '/categorias2', 200, leerContrato('categorias', 'categorias2_200'));
      vieja.complete();
      await primera;

      expect(vm.categorias!.map((c) => c.titulo), ['Nueva']);
    });
  });
}

//relativa al directorio de trabajo: correr desde la raiz
File _imagen() => File('assets/images/1.jpg');

//Dio pasa por varios pasos asincronos antes de llegar al adaptador
Future<void> _hastaQue(bool Function() condicion) async {
  for (var i = 0; i < 200 && !condicion(); i++) {
    await Future.delayed(const Duration(milliseconds: 5));
  }
  expect(condicion(), isTrue, reason: 'la peticion no llego al adaptador');
}
