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

  //el servicio sale de la raiz; el vm lo crea cada ruta (route_generator)
  CursosViewModel(this.servicioCurso);

  //url de la imagen de un curso: la vista no conoce la direccion del servidor
  String urlImagen(int idImagen) => servicioCurso.urlImagen(idImagen);

  Future<RespuestaModelo> agregarCurso(CursoEntidad entidad) async {
    RespuestaModelo respuesta = await servicioCurso.insertarCurso(entidad);
    return respuesta;
  }

  //la vista recibe exito o fallo ya resueltos y decide si avisa; el vm no
  //abre dialogos. Un error deja la lista vacia y devuelve un solo Fallo (antes
  //se abrian dos dialogos seguidos, CU-05)
  Future<Resultado<void>> listarCursosDe(CategoriaEntidad categoria) async {
    Resultado<void> resultado = Exito();
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
    }
    notifyListeners();
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
