import 'dart:io';

import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/presentation/viewmodels/categoriaViewModel.dart';
import 'package:flutter_test/flutter_test.dart';

class VmActualizarCategoriaTest {
  final String capa = "viewModel";
  final String tipo = "remoto";
  final String metodo = "Actualizar categoria";

  //la categoria a modificar se inserta en el mismo test para no depender de
  //datos previos en la bd ni del orden de ejecucion de los demas casos
  void prueba1codigo200(CategoriaViewModel vm) {
    String caso = "exito 200 cambio de descripcion";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = await _insertarCategoria(vm);
      CategoriaEntidad? original = _buscar(vm, titulo);
      expect(original, isNotNull);

      String descripcionNueva = "descripcion modificada";
      //el titulo no cambia: el formulario lo deshabilita en edicion y la
      //conexion lo usa como identificador en la query del PUT
      Resultado<CategoriaEntidad> resultado = await vm.actualizarCategoria(
        CategoriaEntidad(
          titulo: titulo,
          descripcion: descripcionNueva,
          idImagen: original!.idImagen,
        ),
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Exito<CategoriaEntidad>>());
      //el repositorio debe entregar entidad, el modelo no sale de la capa datos
      expect(
        (resultado as Exito<CategoriaEntidad>).datos,
        isA<CategoriaEntidad>(),
      );

      //tras el 200 el vm dispara listarYNotificarCategorias, se verifica el
      //estado que realmente consume la vista, no solo el codigo http
      expect(vm.cargando, isFalse);
      expect(vm.error, isNull);
      CategoriaEntidad? modificada = _buscar(vm, titulo);
      expect(modificada, isNotNull);
      expect(modificada!.descripcion, descripcionNueva);
    });
  }

  void prueba2CambioImagen(CategoriaViewModel vm) {
    String caso = "exito 200 cambio de imagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = await _insertarCategoria(vm);
      CategoriaEntidad? original = _buscar(vm, titulo);
      expect(original, isNotNull);

      //al mandar imagenFile la conexion sube una imagen nueva antes del PUT y
      //reemplaza el imagenId, la anterior queda huerfana en el servidor
      Resultado<CategoriaEntidad> resultado = await vm.actualizarCategoria(
        CategoriaEntidad(
          titulo: titulo,
          descripcion: original!.descripcion,
          idImagen: original.idImagen,
          imagenFile: _imagenPrueba(),
        ),
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Exito<CategoriaEntidad>>());

      CategoriaEntidad entidad =
          (resultado as Exito<CategoriaEntidad>).datos!;
      expect(entidad.idImagen, isNotNull);
      expect(entidad.idImagen, isNot(original.idImagen));
    });
  }

  void prueba3Inexistente(CategoriaViewModel vm) {
    String caso = "error categoria inexistente";
    test('$capa - $tipo - $metodo - $caso', () async {
      //hace falta un imagenId real: el backend valida el cuerpo antes de buscar
      //la categoria, sin el nunca se llega a comprobar si el titulo existe
      String existente = await _insertarCategoria(vm);
      int? idImagen = _buscar(vm, existente)?.idImagen;
      expect(idImagen, isNotNull);

      String titulo = "inexistente_${_marcaTiempo()}";
      Resultado<CategoriaEntidad> resultado = await vm.actualizarCategoria(
        CategoriaEntidad(
          titulo: titulo,
          descripcion: "test unitario",
          idImagen: idImagen,
        ),
      );
      _imprimirRespuesta(resultado);
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 404);
    });
  }

  void prueba4DescripcionVacia(CategoriaViewModel vm) {
    String caso = "error 400 descripcion vacia";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = await _insertarCategoria(vm);
      CategoriaEntidad? original = _buscar(vm, titulo);
      expect(original, isNotNull);

      Resultado<CategoriaEntidad> resultado = await vm.actualizarCategoria(
        CategoriaEntidad(
          titulo: titulo,
          descripcion: "",
          idImagen: original!.idImagen,
        ),
      );
      _imprimirRespuesta(resultado);
      //el PUT valida la descripcion igual que el POST, con mensaje por campo
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect((resultado as Fallo).mensaje, contains('descripcion'));

      //el fallo no debe haber tocado la categoria
      await vm.listarYNotificarCategorias();
      expect(_buscar(vm, titulo)?.descripcion, original.descripcion);
    });
  }

  void prueba5TituloVacio(CategoriaViewModel vm) {
    String caso = "error 400 titulo vacio";
    test('$capa - $tipo - $metodo - $caso', () async {
      //con imagenId valido el unico dato invalido es el titulo, asi el mensaje
      //de error identifica que validacion se disparo
      String existente = await _insertarCategoria(vm);
      int? idImagen = _buscar(vm, existente)?.idImagen;
      expect(idImagen, isNotNull);

      Resultado<CategoriaEntidad> resultado = await vm.actualizarCategoria(
        CategoriaEntidad(
          titulo: "",
          descripcion: "test unitario",
          idImagen: idImagen,
        ),
      );
      _imprimirRespuesta(resultado);
      //a diferencia del DELETE, que trata el titulo vacio como inexistente y
      //responde 404, el PUT si lo valida y responde 400
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect((resultado as Fallo).mensaje, contains('titulo'));
    });
  }

  void prueba6SinImagen(CategoriaViewModel vm) {
    String caso = "sin imagen ni idImagen";
    test('$capa - $tipo - $metodo - $caso', () async {
      String titulo = await _insertarCategoria(vm);

      //a diferencia de insertarCategoria, el repositorio no corta cuando falta
      //la imagen: la peticion llega al backend con imagenId nulo
      Resultado<CategoriaEntidad> resultado = await vm.actualizarCategoria(
        CategoriaEntidad(titulo: titulo, descripcion: "sin imagen"),
      );
      _imprimirRespuesta(resultado);
      //el backend lo rechaza, y lo hace antes de mirar si el titulo existe:
      //esta validacion tapa cualquier otro error del cuerpo
      expect(resultado, isA<Fallo>());
      expect((resultado as Fallo).codigo, 400);
      expect((resultado as Fallo).mensaje, contains('imagenId'));
    });
  }

  //inserta una categoria con titulo unico y devuelve el titulo, para que cada
  //caso trabaje sobre su propio dato
  Future<String> _insertarCategoria(CategoriaViewModel vm) async {
    String titulo = "prueba_actualizar_${_marcaTiempo()}";
    Resultado<CategoriaEntidad> insercion = await vm.insertarCategoria(
      CategoriaEntidad(
        titulo: titulo,
        descripcion: "test unitario",
        imagenFile: _imagenPrueba(),
      ),
    );
    expect(insercion, isA<Exito>());
    return titulo;
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

  //la url y el metodo del error indican que peticion lo genero: sirve para
  //distinguir un rechazo del backend de un fallo previo al subir la imagen
  void _imprimirRespuesta(Resultado resultado) {
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
