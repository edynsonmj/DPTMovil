import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/presentation/viewmodels/estadoSeccion.dart';

//NotificacionSegura: la ruta desecha el vm al salir y una carga que llega
//despues no notifica (CAT-04)
class CategoriaViewModel with ChangeNotifier, NotificacionSegura {
  //servicio en uso
  final ServicioCategoria servicioCategoria;

  //lista de categorias, privada.
  List<CategoriaEntidad>? _categorias;
  //get para manipulacion de la lista fuera del viewModel.
  List<CategoriaEntidad>? get categorias => _categorias;

  //titulos para los filtros de inscripciones. Son datos, no widgets: cada
  //vista arma su DropdownMenuEntry. Se guarda la lista (no se calcula en el
  //get) para que context.select compare la misma instancia entre notificaciones
  List<String> _titulos = const [];
  List<String> get titulos => _titulos;

  //numero de la ultima carga pedida, para descartar respuestas viejas
  int _cargaActual = 0;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  //el servicio llega desde la raiz; el vm se crea por ruta en route_generator
  CategoriaViewModel(this.servicioCategoria);

  //carga de la lista. Ademas de dejar el estado (categorias, cargando, error)
  //devuelve el resultado, para la vista que quiere avisar el fallo con su
  //codigo (InscripcionesGeneralesView); la que pinta vm.error lo ignora
  Future<Resultado<void>> listarYNotificarCategorias() async {
    Resultado<void> resultado = Exito();
    //cada carga lleva su numero: una respuesta vieja que llega despues de una
    //mas nueva se descarta y no la pisa (CAT-09)
    final carga = ++_cargaActual;
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final respuesta = await servicioCategoria.encontrarCategorias();
      if (carga != _cargaActual) return resultado;
      if (respuesta.codigoHttp == 200 && respuesta.datos is List) {
        _establecerCategorias(respuesta.datos as List<CategoriaEntidad>);
      } else if (respuesta.codigoHttp == 204) {
        //coleccion vacia, no es un error. Se ignoran los datos: el remoto
        //manda null y el local su lista de modelos vacia, y el repositorio
        //solo convierte a entidad en el 200
        _establecerCategorias([]);
      } else {
        _error =
            'Código: ${respuesta.codigoHttp} - ${respuesta.error?.mensaje ?? "Error desconocido"}';
        _establecerCategorias([]);
        resultado = _fallo(respuesta);
      }
    } catch (e) {
      if (carga != _cargaActual) return resultado;
      _error = e.toString();
      _establecerCategorias([]);
      resultado = Fallo(-1, e.toString(), origen: 'ViewModel');
    }
    _cargando = false;
    notifyListeners();
    return resultado;
  }

  //url de la imagen ya resuelta: la vista la pinta sin saber de servidores
  //ni endpoints
  String urlImagen(int idImagen) => servicioCategoria.urlImagen(idImagen);

  //punto de entrada del formulario: decide entre crear y actualizar y aplica
  //las reglas que antes vivian en la vista, asi se pueden probar sin UI
  Future<Resultado<CategoriaEntidad>> guardarCategoria({
    required String titulo,
    required String descripcion,
    File? imagenNueva,
    CategoriaEntidad? original, //null = crear
  }) async {
    //la categoria necesita imagen: una nueva o la que ya tenia
    if (imagenNueva == null && original?.idImagen == null) {
      return Fallo(0, 'Carga una imagen por favor', origen: 'ViewModel');
    }
    final entidad = CategoriaEntidad(
      //en edicion el titulo es la clave del PUT ?titulo=, se usa el original
      //tal cual para no dejar de encontrar la categoria por un trim
      titulo: original?.titulo ?? titulo.trim(),
      descripcion: descripcion.trim(),
      //se conserva la imagen actual; imagenFile solo si el usuario eligio
      //una nueva, y solo entonces la conexion sube otra
      idImagen: original?.idImagen,
      imagenFile: imagenNueva,
    );
    return original == null
        ? await insertarCategoria(entidad)
        : await actualizarCategoria(entidad);
  }

  Future<Resultado<CategoriaEntidad>> insertarCategoria(
    CategoriaEntidad entidad,
  ) async {
    try {
      final respuesta = await servicioCategoria.insertarCategoria(entidad);
      //204: se guardo pero el backend no devolvio la categoria (CAT-02)
      if (respuesta.codigoHttp == 201 || respuesta.codigoHttp == 204) {
        await listarYNotificarCategorias();
        return Exito(respuesta.datos as CategoriaEntidad?);
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  //los dialogos y la navegacion quedan en CategoriaFormulario, igual que en
  //insertarCategoria: sin context el metodo se puede llamar desde una prueba
  Future<Resultado<CategoriaEntidad>> actualizarCategoria(
    CategoriaEntidad entidad,
  ) async {
    try {
      final respuesta = await servicioCategoria.actualizarCategoria(entidad);
      //tras el exito se refresca la lista, la vista consume vm.categorias
      if (respuesta.codigoHttp == 200 || respuesta.codigoHttp == 204) {
        await listarYNotificarCategorias();
        return Exito(respuesta.datos as CategoriaEntidad?);
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  //unico punto donde se lee el ErrorModelo: la vista recibe codigo y mensaje
  //ya resueltos y no necesita conocer la capa de datos
  Fallo<T> _fallo<T>(RespuestaModelo respuesta) {
    final error = respuesta.error;
    return Fallo(
      respuesta.codigoHttp,
      error?.mensaje ?? 'Error desconocido. Código: ${respuesta.codigoHttp}',
      origen: error == null ? null : '${error.metodo} ${error.url}',
    );
  }

  //la vista recibe exito o fallo ya resueltos, sin codigos http que interpretar
  Future<Resultado<void>> eliminarCategoria(String titulo) async {
    try {
      final respuesta = await servicioCategoria.eliminarCategoria(titulo);
      //tras el exito se refresca la lista, la vista consume vm.categorias
      if (respuesta.codigoHttp == 200) {
        await listarYNotificarCategorias();
        return Exito();
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  //unico punto donde se escribe la lista: los titulos del filtro se
  //recalculan siempre, tambien al fallar. Antes solo se hacia en el caso de
  //exito y el filtro de inscripciones quedaba con las categorias de la carga
  //anterior, que ya no estaban en la lista
  void _establecerCategorias(List<CategoriaEntidad>? lista) {
    _categorias = lista;
    _titulos = [for (final categoria in lista ?? const []) categoria.titulo];
  }
}
