import 'dart:io';

import 'package:dio/dio.dart';
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

//integracion local del modulo 7 (plan-diagnostico-categorias.md):
//CategoriaViewModel con su cadena real hasta ConexionCategoriaRemota y
//Conexionimagenremoto, con el transporte falso debajo y las respuestas del
//contrato observado
void main() {
  const String capa = "integracion";
  const String tipo = "local";

  late AdaptadorHttpFalso adaptador;
  late CategoriaViewModel vm;

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

  List<String> rutas() =>
      adaptador.peticiones.map((p) => '${p.metodo} ${p.ruta}').toList();

  group('Categorias (vm → conexion real → transporte falso):', () {
    test('$capa - $tipo - Listar categorias - 200 llena la lista, el desplegable y el id de imagen', () async {
      await vm.listarYNotificarCategorias();

      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      expect(vm.categorias!.map((c) => c.titulo), [
        'Categoria Fase 4',
        'Categoria Fase 3',
        'categoria Fase 5',
      ]);
      expect(vm.categorias!.first.idImagen, 1196);
      expect(vm.titulos, hasLength(3));
    });

    test('$capa - $tipo - Listar categorias - sin red deja el 503 en el error y la lista vacia', () async {
      adaptador.fallar('GET', '/categorias2', DioExceptionType.connectionError);

      await vm.listarYNotificarCategorias();

      expect(vm.error, startsWith('Código: 503'));
      expect(vm.categorias, isEmpty);
      expect(vm.titulos, isEmpty);
    });

    //nacio como diagnostico de BK-10: sin sesion todo responde 401 sin cuerpo
    test('$capa - $tipo - Listar categorias - un 401 sin cuerpo pide iniciar sesion', () async {
      adaptador.responder('GET', '/categorias2', 401, '');

      await vm.listarYNotificarCategorias();

      expect(vm.error, contains('sesión'));
    });

    test('$capa - $tipo - Guardar categoria - crear sube la imagen, envia el CategoriaDto y refresca la lista', () async {
      adaptador.responder('POST', '/imagenMultipart', 201, leerContrato('categorias', 'imagenMultipart_201'));
      adaptador.responder('POST', '/categoria', 201, leerContrato('categorias', 'categoria_201'));

      final resultado = await vm.guardarCategoria(
        titulo: '  Categoria nueva ',
        descripcion: 'Creada en la prueba',
        imagenNueva: File('assets/images/1.jpg'),
      );

      expect(resultado, isA<Exito>());
      expect(rutas(), ['POST /imagenMultipart', 'POST /categoria', 'GET /categorias2']);
      expect(adaptador.peticionesA('POST', '/categoria').single.cuerpo, {
        'titulo': 'Categoria nueva',
        'descripcion': 'Creada en la prueba',
        'imagenId': 1300,
      });
    });

    test('$capa - $tipo - Guardar categoria - editar sin imagen nueva conserva el id y no sube imagen', () async {
      adaptador.responder('PUT', '/categoria', 200, {
        'titulo': 'Categoria1',
        'descripcion': 'Descripcion nueva',
        'imagenId': 206,
      });
      final original = CategoriaEntidad(titulo: 'Categoria1', descripcion: 'x', idImagen: 206);

      final resultado = await vm.guardarCategoria(
        titulo: 'Categoria1',
        descripcion: 'Descripcion nueva',
        original: original,
      );

      expect(resultado, isA<Exito>());
      expect(rutas(), ['PUT /categoria', 'GET /categorias2']);
      final put = adaptador.peticionesA('PUT', '/categoria').single;
      expect(put.uri.queryParameters, {'titulo': 'Categoria1'});
      expect(put.cuerpo, {'titulo': 'Categoria1', 'descripcion': 'Descripcion nueva', 'imagenId': 206});
    });

    test('$capa - $tipo - Eliminar categoria - 200 envia el titulo y refresca; 404 es Fallo con el error del backend', () async {
      adaptador.responder('DELETE', '/categoria', 200);
      expect(await vm.eliminarCategoria('Categoria1'), isA<Exito>());
      expect(adaptador.peticionesA('DELETE', '/categoria').single.uri.queryParameters, {'titulo': 'Categoria1'});
      expect(adaptador.peticionesA('GET', '/categorias2'), hasLength(1));

      adaptador.responder('DELETE', '/categoria', 404, {
        'codigoError': 'GC-0003',
        'mensaje': 'No se encuentra registrado el elemento',
      });
      final fallo = await vm.eliminarCategoria('No existe');
      expect(fallo, isA<Fallo>());
      expect((fallo as Fallo).codigo, 404);
      expect(fallo.mensaje, 'No se encuentra registrado el elemento');
    });
    //los casos rojos de este montaje (CAT-01 a CAT-09) estan en
    //test/diagnostico/categorias/integracion_diagnostico_test.dart
  });
}
