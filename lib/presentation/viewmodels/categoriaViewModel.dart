import 'dart:io';

import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/domain/servicios/servicioImagen.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogCargando.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';

class CategoriaViewModel with ChangeNotifier {
  //servicio en uso
  final ServicioCategoria servicioCategoria;

  //lista de categorias, privada.
  List<CategoriaEntidad>? _categorias;
  //get para manipulacion de la lista fuera del viewModel.
  List<CategoriaEntidad>? get categorias => _categorias;

  //lista entradas, para filtro en inscripciones
  List<DropdownMenuEntry> _listaEntradas = [];
  //
  List<DropdownMenuEntry> get getListaEntradas => _listaEntradas;

  bool _cargando = false;
  bool get cargando => _cargando;

  String? _error;
  String? get error => _error;

  //constructor
  CategoriaViewModel() : servicioCategoria = ServicioCategoria();

  Future<void> cargarCategorias(context) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioCategoria.encontrarCategorias();
      if (respuesta.codigoHttp == 200) {
        if (respuesta.datos is List<CategoriaEntidad>) {
          _establecerCategorias(respuesta.datos as List<CategoriaEntidad>);
          notifyListeners();
        } else {
          _establecerCategorias(null);
          showDialog(
            context: context,
            builder: (context) {
              return DialogError(
                titulo: 'datos inconsistentes',
                mensaje:
                    'No se ha obtenido una lista de tipo entidad para cargar los datos',
                codigo: -1,
              );
            },
          );
        }
      } else if (respuesta.codigoHttp == 204) {
        _establecerCategorias([]);
        showDialog(
          context: context,
          builder: (context) {
            return DialogError(
              titulo: 'Exito en la operacion',
              mensaje:
                  'Lastimosamente no se encontraron categorias en el sistema',
              codigo: 204,
            );
          },
        );
      } else {
        _establecerCategorias([]);
        showDialog(
          context: context,
          builder: (context) {
            return DialogError(
              titulo: 'No se pudo obtener datos',
              mensaje:
                  respuesta?.error?.mensaje ??
                  'no hay informacion respecto al error',
              codigo: 204,
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return DialogError(
            titulo: 'excepcion no controlada',
            mensaje: e.toString(),
            codigo: -1,
          );
        },
      );
    }
  }

  Future<void> listarYNotificarCategorias() async {
    _cargando = true;
    _error = null;
    notifyListeners();
    try {
      final respuesta = await servicioCategoria.encontrarCategorias();
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
      }
    } catch (e) {
      _error = e.toString();
      _establecerCategorias([]);
    }
    _cargando = false;
    notifyListeners();
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
      if (respuesta.codigoHttp == 201) {
        await listarYNotificarCategorias();
        return Exito(respuesta.datos as CategoriaEntidad?);
      }
      return _fallo(respuesta);
    } catch (e) {
      return Fallo(-1, e.toString(), origen: 'ViewModel');
    }
  }

  /*
  Future<void> guardarCategoria(CategoriaEntidad entidad, context) async {
    //TODO: establecer carga mientra termina la peticion
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioCategoria.insertarCategoria(entidad);
      if (respuesta != null) {
        if (respuesta.codigoHttp == 201) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return DialogExito(
                titulo: 'Accion exitosa',
                mensaje:
                    'La categoria ${entidad.titulo}, ha sido creada con exito',
              );
            },
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return DialogError(
                titulo: 'Error al insertar la categoria',
                codigo: respuesta?.codigoHttp ?? -1,
                mensaje:
                    respuesta?.error?.mensaje ??
                    'No se ha encontrado informacion del error',
              );
            },
          );
        }
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return DialogError(
              titulo: 'Sin informacion',
              mensaje:
                  'El servidor no ha informado sobre el estado de la peticion',
              codigo: -1,
            );
          },
        );
      }
    } catch (e) {
      Navigator.pushNamed(context, AppRutas.categorias);
      showDialog(
        context: context,
        builder: (context) {
          return DialogError(
            titulo:
                'Error inesperado al usar el servicio, excepcion no controlada',
            mensaje: e.toString(),
            codigo: -1,
          );
        },
      );
    }
  }
*/
  //TODO: Para que sea funcional, hay que poner la logica de error en el formulario, de momento hay que seguir usando guardarCategoria
  /*
  Future<RespuestaModelo> registrarCategoria(CategoriaEntidad entidad) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioCategoria.insertarCategoria(entidad);
      if (respuesta.codigoHttp != 201) {
        return RespuestaModelo(
          codigoHttp: 0,
          error: ErrorModelo(
            codigoHttp: 0,
            mensaje: "la imagen no pudo ser insertada",
            url: "registrar categoria",
            metodo: "POST",
          ),
        );
      }
      respuesta = await servicioCategoria.insertarCategoria(entidad);
      return respuesta;
    } on Exception catch (e) {
      //_mostrarError(context, "fallo al registrar", null);
      return RespuestaModelo.fromException(
        e,
        "POST",
        "registro atenciones",
        "viewmodel",
      );  
    }
  }
*/
  //los dialogos y la navegacion quedan en CategoriaFormulario, igual que en
  //insertarCategoria: sin context el metodo se puede llamar desde una prueba
  Future<Resultado<CategoriaEntidad>> actualizarCategoria(
    CategoriaEntidad entidad,
  ) async {
    try {
      final respuesta = await servicioCategoria.actualizarCategoria(entidad);
      //tras el exito se refresca la lista, la vista consume vm.categorias
      if (respuesta.codigoHttp == 200) {
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

  //unico punto donde se escribe la lista: las entradas del desplegable se
  //recalculan siempre, tambien al fallar. Antes solo se hacia en el caso de
  //exito y el filtro de inscripciones quedaba con las categorias de la carga
  //anterior, que ya no estaban en la lista
  void _establecerCategorias(List<CategoriaEntidad>? lista) {
    _categorias = lista;
    _cargarEntradas();
  }

  void _cargarEntradas() {
    if (_categorias != null && _categorias!.isNotEmpty) {
      _listaEntradas =
          _categorias!.map((categoria) {
            return DropdownMenuEntry(
              value: categoria.titulo,
              label: categoria.titulo,
            );
          }).toList();
    } else {
      _listaEntradas = [];
    }
  }
}
