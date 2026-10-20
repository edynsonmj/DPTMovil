import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

//cubre guardarCategoria, el metodo que usa CategoriaFormulario: las reglas que
//antes estaban en la vista (imagen obligatoria, crear o actualizar, que campos
//lleva la entidad) ahora se prueban aqui sin montar el widget
class VmGuardarFormularioCategoriaTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Guardar desde formulario";

  void prueba1CrearExito(CategoriaViewModel vm) {
    String caso = "crear con imagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = "prueba_formulario_${_marcaTiempo()}";
      Resultado<CategoriaEntidad> resultado = await vm.guardarCategoria(
        titulo: titulo,
        descripcion: "test unitario",
        imagenNueva: _imagenPrueba(),
      );
      _imprimir(resultado);
      expect(resultado, isA<Exito<CategoriaEntidad>>());
      expect((resultado as Exito<CategoriaEntidad>).datos?.idImagen, isNotNull);
      //sin original se crea, y el vm refresca la lista tras el exito
      expect(_buscar(vm, titulo), isNotNull);
    });
  }

  void prueba2CrearSinImagen(CategoriaViewModel vm) {
    String caso = "crear sin imagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = "prueba_formulario_${_marcaTiempo()}";
      Resultado<CategoriaEntidad> resultado = await vm.guardarCategoria(
        titulo: titulo,
        descripcion: "test unitario",
      );
      _imprimir(resultado);
      //codigo 0: lo corta el vm, antes de llegar al repositorio (que
      //responderia 400) y antes de la red
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 0);
      expect((resultado as Fallo).mensaje, contains('imagen'));
      expect(_buscar(vm, titulo), isNull);
    });
  }

  void prueba3CrearRecortaEspacios(CategoriaViewModel vm) {
    String caso = "crear recorta espacios";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = "prueba_formulario_${_marcaTiempo()}";
      Resultado<CategoriaEntidad> resultado = await vm.guardarCategoria(
        titulo: "  $titulo  ",
        descripcion: "  test unitario  ",
        imagenNueva: _imagenPrueba(),
      );
      _imprimir(resultado);
      expect(resultado, isA<Exito<CategoriaEntidad>>());
      //se guarda sin los espacios: el titulo luego es la clave de PUT y DELETE
      CategoriaEntidad? guardada = _buscar(vm, titulo);
      expect(guardada, isNotNull);
      expect(guardada!.descripcion, "test unitario");
    });
  }

  void prueba4EditarSinImagenNueva(CategoriaViewModel vm) {
    String caso = "editar sin imagen nueva conserva la imagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      CategoriaEntidad original = await _insertarCategoria(vm);

      Resultado<CategoriaEntidad> resultado = await vm.guardarCategoria(
        titulo: original.titulo,
        descripcion: "descripcion modificada",
        original: original,
      );
      _imprimir(resultado);
      expect(resultado, isA<Exito<CategoriaEntidad>>());
      //sin imagen nueva no se sube ninguna: el PUT reutiliza el imagenId
      expect(
        (resultado as Exito<CategoriaEntidad>).datos?.idImagen,
        original.idImagen,
      );
      CategoriaEntidad? modificada = _buscar(vm, original.titulo);
      expect(modificada?.descripcion, "descripcion modificada");
      expect(modificada?.idImagen, original.idImagen);
    });
  }

  void prueba5EditarConImagenNueva(CategoriaViewModel vm) {
    String caso = "editar con imagen nueva la reemplaza";
    test('$capa - $tipo - $metodo - $caso', () async {
      CategoriaEntidad original = await _insertarCategoria(vm);

      Resultado<CategoriaEntidad> resultado = await vm.guardarCategoria(
        titulo: original.titulo,
        descripcion: original.descripcion,
        imagenNueva: _imagenPrueba(),
        original: original,
      );
      _imprimir(resultado);
      expect(resultado, isA<Exito<CategoriaEntidad>>());
      int? idNuevo = (resultado as Exito<CategoriaEntidad>).datos?.idImagen;
      expect(idNuevo, isNotNull);
      expect(idNuevo, isNot(original.idImagen));
    });
  }

  void prueba6EditarSinNingunaImagen(CategoriaViewModel vm) {
    String caso = "editar sin imagen nueva ni idImagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      CategoriaEntidad existente = await _insertarCategoria(vm);
      //original sin idImagen: antes solo la vista frenaba este caso y el
      //backend respondia 400 imagenId; ahora lo corta el vm
      CategoriaEntidad original = CategoriaEntidad(
        titulo: existente.titulo,
        descripcion: existente.descripcion,
      );

      Resultado<CategoriaEntidad> resultado = await vm.guardarCategoria(
        titulo: original.titulo,
        descripcion: "no debe guardarse",
        original: original,
      );
      _imprimir(resultado);
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 0);

      await vm.listarYNotificarCategorias();
      expect(_buscar(vm, existente.titulo)?.descripcion, existente.descripcion);
    });
  }

  void prueba7EditarUsaTituloOriginal(CategoriaViewModel vm) {
    String caso = "editar usa el titulo original como clave";
    test('$capa - $tipo - $metodo - $caso', () async {
      CategoriaEntidad original = await _insertarCategoria(vm);

      //el campo esta deshabilitado en edicion, pero si llegara otro titulo el
      //vm debe seguir actualizando la categoria original y no crear otra
      String otroTitulo = "otro_${_marcaTiempo()}";
      Resultado<CategoriaEntidad> resultado = await vm.guardarCategoria(
        titulo: otroTitulo,
        descripcion: "descripcion por clave",
        original: original,
      );
      _imprimir(resultado);
      expect(resultado, isA<Exito<CategoriaEntidad>>());
      expect(_buscar(vm, original.titulo)?.descripcion, "descripcion por clave");
      expect(_buscar(vm, otroTitulo), isNull);
    });
  }

  void prueba8UrlImagen(CategoriaViewModel vm) {
    String caso = "url de imagen descarga la imagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      CategoriaEntidad existente = await _insertarCategoria(vm);

      //la vista pinta esta url con Image.network sin armarla ella misma
      String url = vm.urlImagen(existente.idImagen!);
      print('url: $url');
      expect(url, contains('idImagen=${existente.idImagen}'));

      //la url debe servir la imagen real, no solo tener buena forma
      Response<List<int>> respuesta = await Dio().get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      expect(respuesta.statusCode, 200);
      expect(respuesta.data, isNotEmpty);
    });
  }

  //inserta una categoria con titulo unico y la devuelve tal como la ve la
  //vista en la lista, que es lo que el formulario recibe como original
  Future<CategoriaEntidad> _insertarCategoria(CategoriaViewModel vm) async {
    String titulo = "prueba_formulario_${_marcaTiempo()}";
    Resultado<CategoriaEntidad> insercion = await vm.insertarCategoria(
      CategoriaEntidad(
        titulo: titulo,
        descripcion: "test unitario",
        imagenFile: _imagenPrueba(),
      ),
    );
    expect(insercion, isA<Exito>());
    CategoriaEntidad? enLista = _buscar(vm, titulo);
    expect(enLista, isNotNull);
    expect(enLista!.idImagen, isNotNull);
    return enLista;
  }

  CategoriaEntidad? _buscar(CategoriaViewModel vm, String titulo) {
    try {
      return vm.categorias?.firstWhere(
        (categoria) => categoria.titulo == titulo,
      );
    } on StateError {
      return null;
    }
  }

  void _imprimir(Resultado resultado) {
    if (resultado is Fallo) {
      print('codigo: ${resultado.codigo}');
      print('error mensaje: ${resultado.mensaje}');
      print('error origen: ${resultado.origen}');
    } else {
      print('exito');
    }
  }

  //marca de tiempo sin separadores para que el titulo sea unico en cada corrida
  //y seguro en la url
  String _marcaTiempo() =>
      DateTime.now().toIso8601String().replaceAll(RegExp(r'[-:.T]'), '');

  //imagen del proyecto, no hace falta bajar nada de internet
  //la ruta es relativa al directorio de trabajo: correr desde la raiz
  File _imagenPrueba() => File('assets/images/1.jpg');
}
