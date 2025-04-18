import 'package:flutter/material.dart';
import 'package:dpt_movil/config/routes/app_rutas.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioCategoria.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogCargando.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogExito.dart';

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
  //constructor
  CategoriaViewModel() : servicioCategoria = ServicioCategoria();

  Future<void> cargarCategorias(context) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioCategoria.encontrarCategorias();
      if (respuesta.codigoHttp == 200) {
        if (respuesta.datos is List<CategoriaEntidad>) {
          _categorias = respuesta.datos as List<CategoriaEntidad>;
          _cargarEntradas();
          notifyListeners();
        } else {
          _categorias = null;
          showDialog(
            context: context,
            builder: (context) {
              return DialogError(
                titulo: 'datos inconsistentes',
                mensaje:
                    'no se ha obtenido una lista de tipo entidad para cargar los datos',
                codigo: -1,
              );
            },
          );
        }
      } else if (respuesta.codigoHttp == 204) {
        _categorias = [];
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
        _categorias = [];
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

  Future<void> guardarCategoria(CategoriaEntidad entidad, context) async {
    //TODO: establecer carga mientra termina la peticion
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioCategoria.insertarCategoria(entidad);
      Navigator.pushNamed(context, AppRutas.categorias);
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

  Future<void> actualizarCategoria(context, CategoriaEntidad entidad) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioCategoria.actualizarCategoria(entidad);
      Navigator.pushNamed(context, AppRutas.categorias);
      if (respuesta != null) {
        if (respuesta.codigoHttp == 200) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return DialogExito(
                titulo: 'Accion exitosa',
                mensaje:
                    'La categoria ${entidad.titulo}, ha sido modificada con exito',
              );
            },
          );
        } else {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return DialogError(
                titulo: 'Error al modificar la categoria',
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

  Future<void> eliminarCategoria(String titulo, context) async {
    try {
      RespuestaModelo respuesta = await servicioCategoria.eliminarCategoria(
        titulo,
      );
      //si la respuesta fue exitosa muestra mensaje con la categoria eliminada
      if (respuesta.codigoHttp == 200) {
        cargarCategorias(context);
        notifyListeners();
        CategoriaEntidad entidad = respuesta.datos as CategoriaEntidad;
        showDialog(
          context: context,
          builder: (context) {
            return DialogExito(
              titulo: 'Eliminacion exitosa',
              mensaje:
                  'se ha eliminado correctamente la categoria ${entidad.titulo}',
            );
          },
        );
      } else {
        showDialog(
          context: context,
          builder: (context) {
            return DialogError(
              titulo: 'Fallo en eliminacion',
              mensaje:
                  respuesta.error?.mensaje ?? 'No hay informacion del error',
              codigo: respuesta.error?.codigoHttp ?? respuesta.codigoHttp,
            );
          },
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) {
          return DialogError(
            titulo: 'Error inesperado',
            mensaje:
                'Se ha encontrado un error no controlado con definicion: $e',
            codigo: -1,
          );
        },
      );
    }
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
