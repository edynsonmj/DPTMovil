import 'dart:io';

import 'package:dpt_movil/data/models/errorModelo.dart';
import 'package:dpt_movil/domain/entities/categoriaEntidad.dart';
import 'package:dpt_movil/domain/entities/resultado.dart';
import 'package:flutter/foundation.dart';
import 'package:dpt_movil/data/models/respuestaModelo.dart';
import 'package:dpt_movil/domain/entities/cursoEntidad.dart';
import 'package:dpt_movil/domain/servicios/servicioCurso.dart';

class CursosViewModel with ChangeNotifier {
  //servicio a usar
  final ServicioCurso servicioCurso;
  //lista de cursos
  List<CursoEntidad>? _listaCursos;
  //nombres para el desplegable "desplazar a". Son datos, no widgets: la
  //vista arma sus DropdownMenuEntry
  List<String> _nombres = const [];
  //get para acceder a la lista
  List<CursoEntidad>? get getListaCursos => _listaCursos;
  List<String> get nombresCursos => _nombres;

  //mientras llega la lista: sin esto la vista no distingue "cargando" de
  //"la categoria no tiene cursos"
  bool _cargando = false;
  bool get cargando => _cargando;

  //el servicio sale de la raiz; el vm lo crea cada ruta (route_generator)
  CursosViewModel(this.servicioCurso);

  //url de la imagen de un curso: la vista no conoce la direccion del servidor
  String urlImagen(int idImagen) => servicioCurso.urlImagen(idImagen);

  //punto de entrada del formulario: aplica las reglas que antes vivian en la
  //vista (deporte e imagen obligatorios), arma la entidad y la registra. La
  //vista entrega lo que hay en pantalla y recibe exito o fallo ya resueltos
  Future<Resultado<CursoEntidad>> guardarCurso({
    required String nombre,
    required String descripcion,
    required String categoria,
    String? deporte,
    File? imagenNueva,
    CursoEntidad? original, //null = crear
  }) async {
    //no hay operacion de edicion en el servicio (VM-e); ninguna pantalla abre
    //el formulario en modo edicion, pero si llega se dice en vez de callar
    if (original != null) {
      return Fallo(0, 'La edicion de cursos aun no esta disponible', origen: 'ViewModel');
    }
    if (deporte == null) {
      return Fallo(0, 'Selecciona un deporte por favor', origen: 'ViewModel');
    }
    if (imagenNueva == null) {
      return Fallo(0, 'Carga una imagen por favor', origen: 'ViewModel');
    }
    final entidad = CursoEntidad(
      nombreCurso: nombre.trim(),
      nombreDeporte: deporte,
      tituloCategoria: categoria,
      descripcion: descripcion.trim(),
      imagenFile: imagenNueva,
    );
    final respuesta = await agregarCurso(entidad);
    if (respuesta.codigoHttp == 201) {
      return Exito(respuesta.datos as CursoEntidad?);
    }
    return _fallo(respuesta);
  }

  //la excepcion de una capa de abajo vuelve como respuesta, no se lanza: un
  //curso sin archivo hacia saltar el imagenFile! de la conexion hasta la vista
  //(CU-03)
  Future<RespuestaModelo> agregarCurso(CursoEntidad entidad) async {
    try {
      return await servicioCurso.insertarCurso(entidad);
    } catch (e) {
      return RespuestaModelo.fromObjectError(e, 'POST', 'Agregar curso', 'ViewModel');
    }
  }

  //la vista recibe exito o fallo ya resueltos y decide si avisa; el vm no
  //abre dialogos. Un error deja la lista vacia y devuelve un solo Fallo (antes
  //se abrian dos dialogos seguidos, CU-05)
  Future<Resultado<void>> listarCursosDe(CategoriaEntidad categoria) async {
    Resultado<void> resultado = Exito();
    _cargando = true;
    notifyListeners();
    try {
      final respuesta = await servicioCurso.listarCursosDe(categoria);
      if (respuesta.codigoHttp == 200 && respuesta.datos is List<CursoEntidad>) {
        _establecerCursos(respuesta.datos as List<CursoEntidad>);
      } else {
        _establecerCursos([]);
        resultado = _fallo(respuesta);
      }
    } catch (e) {
      _establecerCursos([]);
      resultado = Fallo(-1, e.toString(), origen: 'ViewModel');
    } finally {
      _cargando = false;
      notifyListeners();
    }
    return resultado;
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

  //unico punto donde se escribe la lista: los nombres del desplegable salen
  //siempre de ella
  void _establecerCursos(List<CursoEntidad> lista) {
    _listaCursos = lista;
    _nombres = [for (final curso in lista) curso.nombreCurso];
  }

  //unico punto donde se lee el ErrorModelo de una carga: la vista recibe
  //codigo y mensaje ya resueltos
  Fallo<T> _fallo<T>(RespuestaModelo respuesta) {
    final error = respuesta.error;
    return Fallo(
      respuesta.codigoHttp,
      error?.mensaje ?? 'Error desconocido. Código: ${respuesta.codigoHttp}',
      origen: error == null ? null : '${error.metodo} ${error.url}',
    );
  }
}
