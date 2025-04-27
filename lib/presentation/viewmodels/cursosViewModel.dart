import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:flutter/material.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';
import 'package:dpt_movil/presentation/view/widgets/dialogError.dart';

class CursosViewModel with ChangeNotifier {
  //servicio a usar
  final ServicioCurso servicioCurso;
  //lista de cursos
  List<CursoEntidad>? _listaCursos;
  //lista entradas para el desplegable
  List<DropdownMenuEntry> _listaEntradas = [];
  //get para acceder a la lista
  List<CursoEntidad>? get getListaCursos => _listaCursos;
  //get para acceder a la lista de entradas para el desplegable
  List<DropdownMenuEntry> get getListaEntradas => _listaEntradas;

  //constructor
  CursosViewModel() : servicioCurso = ServicioCurso();

  Future<void> cargarListaCursos() async {
    try {
      _listaCursos = await servicioCurso.call();
      _cargarEntradas();
      notifyListeners();
    } catch (e) {
      print('error en CursosViewModel: $e');
    }
  }

  Future<RespuestaModelo> agregarCurso(CursoEntidad entidad) async {
    RespuestaModelo respuesta = await servicioCurso.insertarCurso(entidad);
    return respuesta;
  }

  Future<void> listarTodosCursos(context) async {
    RespuestaModelo? respuesta;
    _listaCursos = [];
    try {
      respuesta = await servicioCurso.listarTodosCursos();
      switch (respuesta.codigoHttp) {
        case 200: // respuesta correcta, cargar datos
          if (respuesta.datos is List<CursoEntidad>) {
            _listaCursos = respuesta.datos as List<CursoEntidad>;
          } else {
            showDialog(
              context: context,
              builder: (context) {
                return DialogError(
                  titulo: 'datos inconsistentes',
                  mensaje:
                      'no se ha obtenido una lista de tipo entidad para cargar los datos',
                  codigo: 0,
                );
              },
            );
          }
          break;
        case 204: //listado vacio
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
          break;
        default: //Otro tipo de error reportado
          showDialog(
            context: context,
            builder: (context) {
              return DialogError(
                titulo: 'No se pudo obtener datos',
                mensaje:
                    respuesta?.error?.mensaje ??
                    'no hay informacion respecto al error',
                codigo: respuesta?.codigoHttp ?? 0,
              );
            },
          );
          break;
      }
    } catch (e) {
      //error no esperado
      showDialog(
        context: context,
        builder: (context) {
          return DialogError(
            titulo: 'excepcion no controlada',
            mensaje: e.toString(),
            codigo: 0,
          );
        },
      );
    } finally {
      _cargarEntradas();
      notifyListeners();
    }
  }

  Future<void> listarCursosDe(context, CategoriaEntidad categoria) async {
    RespuestaModelo? respuesta;
    _listaCursos = [];
    try {
      respuesta = await servicioCurso.listarCursosDe(categoria);
      if (respuesta.codigoHttp != 200) {
        _mostrarError(context, "Sin datos", respuesta.error);
      }
      if (respuesta.datos is List<CursoEntidad>) {
        _listaCursos = respuesta.datos as List<CursoEntidad>;
      } else {
        _mostrarError(
          context,
          "datos inconsistentes",
          ErrorModelo(
            codigoHttp: 406,
            mensaje:
                'no se ha obtenido una lista de tipo entidad para cargar los datos',
            url: "cursosbycategoria",
            metodo: "POST",
          ),
        );
      }
    } catch (e) {
      _mostrarError(
        context,
        'excepcion no controlada',
        ErrorModelo(
          codigoHttp: 0,
          mensaje: e.toString(),
          url: 'cursosbycategoria',
          metodo: 'GET',
        ),
      );
    } finally {
      _cargarEntradas();
      notifyListeners();
    }
  }

  Future<RespuestaModelo> obtenerCurso(String categoria, String curso) async {
    RespuestaModelo? respuesta;
    try {
      respuesta = await servicioCurso.obtenerCurso(categoria, curso);
      return respuesta;
    } catch (e) {
      return RespuestaModelo(
        codigoHttp: 0,
        error: ErrorModelo(
          codigoHttp: 0,
          mensaje: "excepcion no controlada en view",
          url: 'obtenerCursos',
          metodo: 'GET',
        ),
      );
    }
  }

  void _cargarEntradas() {
    if (_listaCursos != null && _listaCursos!.isNotEmpty) {
      _listaEntradas =
          _listaCursos!.map((curso) {
            return DropdownMenuEntry(
              value: curso.nombreCurso,
              label: curso.nombreCurso,
            );
          }).toList();
    } else {
      _listaEntradas = [];
    }
  }

  void _mostrarError(context, String titulo, ErrorModelo? error) {
    showDialog(
      context: context,
      builder: (context) {
        return (error != null)
            ? DialogError(
              titulo: titulo,
              mensaje: error.mensaje,
              codigo: error.codigoHttp,
            )
            : DialogError(
              titulo: 'Error sin informacion',
              mensaje: "Se desconoce el error",
              codigo: 0,
            );
      },
    );
  }
}
